/**
 *Submitted for verification at polygonscan.com on 2022-10-18
*/

// File: contracts/upgradeability/VersionedInitializable.sol


pragma solidity ^0.8.10;

/**
 * @title VersionedInitializable
 * @author Souq, inspired by Souq and the OpenZeppelin Initializable contract
 * @notice Helper contract to implement initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * @dev WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
abstract contract VersionedInitializable {
  /**
   * @dev Indicates that the contract has been initialized.
   */
  uint256 private lastInitializedRevision = 0;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    uint256 revision = getRevision();
    require(
      initializing || isConstructor() || revision > lastInitializedRevision,
      'Contract instance has already been initialized'
    );

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      lastInitializedRevision = revision;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /**
   * @notice Returns the revision number of the contract
   * @dev Needs to be defined in the inherited class as a constant.
   * @return The revision number
   **/
  function getRevision() internal pure virtual returns (uint256);

  /**
   * @notice Returns true if and only if the function is running in the constructor
   * @return True if the function is running in the constructor
   **/
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    //solium-disable-next-line
    assembly {
      cs := extcodesize(address())
    }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: contracts/souq/libraries/types/DataTypes.sol


pragma solidity ^0.8.10;

library DataTypes {
  struct Asset {
    string name;
    address asset;
    string symbol;
    uint index;
    bool paused;
    address priceOracle;
  }
  struct VaultAsset {
    uint index;
    uint assetIndex;
    bool asUnderlying;
    bool forStaking;
  }
  struct AssetData {
    uint index;
    uint assetIndex;
    uint amount;
  }
  struct PositionData {
    uint maturity;
    uint index;
    uint date;
    uint vested;
    uint vault;
    uint assets;
  }
  struct VaultData {
      uint index;
      string name;
      bool paused;
      uint poolFee;
      uint threshold;
  }

  struct Token {
      uint positions;
      uint vaults;
      uint underlyingAssets;
      uint index;
  }
}

// File: contracts/souq/core/SouqStorage.sol


pragma solidity ^0.8.10;


/**
 * @title SouqStorage
 * @author Souq
 * @notice Contract used as storage of the Souq contract.
 * @dev It defines the storage layout of the Souq contract.
 */
contract SouqStorage {
  // Map of vaults and their data (underlyingAssetOfReserve => VaultData)
  mapping(uint => DataTypes.VaultData) internal _vaults;

  // Maximum number of active vaults there have been in the protocol. It is the upper bound of the vaults list
  uint16 internal _vaultCount;

  // Map of the vaults and their mapping of assets data (vaultId => asset data mapping by address).
  mapping(uint => mapping(address => DataTypes.VaultAsset)) internal _vaultAssetsData;

  // List of assets as a map (assetId in the vault => asset address).
  mapping(uint => mapping(uint => address)) internal _vaultAssetsList;

  // Maximum number of active assets there have been in the vault. It is the upper bound of the vaults asset list
  mapping(uint => uint16) internal _vaultAssetCount;

  // Map of the vaults and their mapping of underlying assets data (vaultId => asset data mapping by index).
  mapping(uint => mapping(address => DataTypes.AssetData)) internal _vaultUnderlyingAssetsData;

    // List of assets as a map (assetId in the vault => asset address).
  mapping(uint => mapping(uint => address)) internal _vaultUnderlyingAssetsList;

  // Maximum number of active underlying assets there have been in the vault. It is the upper bound of the vaults asset list
  mapping(uint => uint16) internal _vaultUnderlyingAssetCount;

  // Map of the vaults and their list of staking assets data (vaultId => asset data mapping by index).
  mapping(uint => mapping(address => DataTypes.AssetData)) internal _vaultStakingAssetsData;

    // List of vault staking assets as a map (assetId in the vault => asset address).
  mapping(uint => mapping(uint => address)) internal _vaultStakingAssetsList;

  // Maximum number of active staking assets there have been in the vault. It is the upper bound of the vaults asset list
  mapping(uint => uint16) internal _vaultStakingAssetCount;

  // Map between each vault and position ids
  mapping(uint => mapping(uint => uint)) internal _vaultPositionsList;

  // Maximum number of active position ids in each vault
  mapping(uint => uint16) internal _vaultPositionCount;

  
  //Map of all assets used in the protocol and their data
  mapping(address => DataTypes.Asset) internal _assets;

  // List of assets as a map (assetId => asset).
  // It is structured as a mapping for gas savings reasons, using the asset id as index
  mapping(uint => address) internal _assetsList;

  // Maximum number of active assets there have been in the protocol. It is the upper bound of the assets list
  uint16 internal _assetCount;


  // Map of positions and their data (id => PositionData)
  mapping(uint => DataTypes.PositionData) internal _positions;

  // Maximum number of active positions there have been in the protocol. It is the upper bound of the positions list
  uint16 internal _positionCount;

   // Map of the positions and their mapping of underlying assets data (positionId => asset data mapping by index).
  mapping(uint => mapping(address => DataTypes.AssetData)) internal _positionUnderlyingAssetsData;

    // List of vault staking assets as a map (assetId in the vault => asset address).
  mapping(uint => mapping(uint => address)) internal _positionUnderlyingAssetsList;

  // Maximum number of active underlying assets there have been in the position. It is the upper bound of the position asset list
  mapping(uint => uint16) internal _positionUnderlyingAssetCount;
}
// File: contracts/interfaces/IVault.sol


pragma solidity ^0.8.10;


interface IVault {
   function uri(uint) external view returns (string memory);
   function setURI(uint256, string memory) external;
   function mint(address, uint256) external;
   function burn(uint256) external;
}
// File: contracts/interfaces/IERC20.sol


pragma solidity 0.8.10;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);
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

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: contracts/interfaces/IAddressesProvider.sol


pragma solidity ^0.8.0;

/**
 * @title IAddressesProvider
 * @author Souq
 * @notice Defines the basic interface for a Vault Addresses Provider.
 **/
interface IAddressesProvider {

    /**
     * @dev Emitted when the Vault is updated.
     * @param oldAddress The old address of the Vault
     * @param newAddress The new address of the Vault
     */
    event VaultUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the price oracle is updated.
     * @param oldAddress The old address of the Treasury
     * @param newAddress The new address of the Treasury
     */
    event TreasuryUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the ACL manager is updated.
     * @param oldAddress The old address of the ACLManager
     * @param newAddress The new address of the ACLManager
     */
    event ACLManagerUpdated(address indexed oldAddress, address indexed newAddress);


    /**
     * @dev Emitted when the Staker is updated.
     * @param oldAddress The old address of the Staker
     * @param newAddress The new address of the Staker
     */
    event StakerUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the ACL admin is updated.
     * @param oldAddress The old address of the ACLAdmin
     * @param newAddress The new address of the ACLAdmin
     */
    event ACLAdminUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when a new proxy is created.
     * @param id The identifier of the proxy
     * @param proxyAddress The address of the created proxy contract
     * @param implementationAddress The address of the implementation contract
     */
    event ProxyCreated(
        bytes32 indexed id,
        address indexed proxyAddress,
        address indexed implementationAddress
    );

    /**
     * @dev Emitted when a new non-proxied contract address is registered.
     * @param id The identifier of the contract
     * @param oldAddress The address of the old contract
     * @param newAddress The address of the new contract
     */
    event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the implementation of the proxy registered with id is updated
     * @param id The identifier of the contract
     * @param proxyAddress The address of the proxy contract
     * @param oldImplementationAddress The address of the old implementation contract
     * @param newImplementationAddress The address of the new implementation contract
     */
    event AddressSetAsProxy(
        bytes32 indexed id,
        address indexed proxyAddress,
        address oldImplementationAddress,
        address indexed newImplementationAddress
    );

    /**
     * @notice Returns an address by its identifier.
     * @dev The returned address might be an EOA or a contract, potentially proxied
     * @dev It returns ZERO if there is no registered address with the given id
     * @param id The id
     * @return The address of the registered for the specified id
     */
    function getAddress(bytes32 id) external view returns (address);

    /**
     * @notice General function to update the implementation of a proxy registered with
     * certain `id`. If there is no proxy registered, it will instantiate one and
     * set as implementation the `newImplementationAddress`.
     * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
     * setter function, in order to avoid unexpected consequences
     * @param id The id
     * @param newImplementationAddress The address of the new implementation
     */
    function setAddressAsProxy(bytes32 id, address newImplementationAddress) external;

    /**
     * @notice Sets an address for an id replacing the address saved in the addresses map.
     * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
     * @param id The id
     * @param newAddress The address to set
     */
    function setAddress(bytes32 id, address newAddress) external;

    /**
     * @notice Returns the address of the Vault proxy.
     * @return The Vault proxy address
     **/
    function getVault() external view returns (address);

    /**
     * @notice Updates the address of the Vault.
     * @param newVault The address of the new Vault
     **/
    function setVault(address newVault) external;

    /**
     * @notice Returns the address of the price oracle.
     * @return The address of the Treasury
     */
    function getTreasury() external view returns (address);

    /**
     * @notice Updates the address of the price oracle.
     * @param newTreasury The address of the new Treasury
     */
    function setTreasury(address newTreasury) external;

    /**
     * @notice Returns the address of the ACL manager.
     * @return The address of the ACLManager
     */
    function getACLManager() external view returns (address);

    /**
     * @notice Updates the address of the ACL manager.
     * @param newAclManager The address of the new ACLManager
     **/
    function setACLManager(address newAclManager) external;

    /**
     * @notice Returns the address of the Staker.
     * @return The address of the Staker
     */
    function getStaker() external view returns (address);

    /**
     * @notice Updates the address of the Staker.
     * @param newStaker The address of the new Staker
     **/
    function setStaker(address newStaker) external;
    /**
     * @notice Returns the address of the ACL admin.
     * @return The address of the ACL admin
     */
    function getACLAdmin() external view returns (address);

    /**
     * @notice Updates the address of the ACL admin.
     * @param newAclAdmin The address of the new ACL admin
     */
    function setACLAdmin(address newAclAdmin) external;

}

// File: contracts/interfaces/IACManager.sol


pragma solidity ^0.8.0;


/**
 * @title IACLManager
 * @author Souq
 * @notice Defines the basic interface for the ACL Manager
 **/
interface IACManager {
  /**
   * @notice Returns the contract address of the VaultAddressesProvider
   * @return The address of the VaultAddressesProvider
   */
//   function ADDRESSES_PROVIDER() external view returns (address);

  /**
   * @notice Returns the identifier of the Vault role
   * @return The id of the Vaultrole
   */
  function SOUQ() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the VaultAdmin role
   * @return The id of the VaultAdmin role
   */
  function VAULT_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the EmergencyAdmin role
   * @return The id of the EmergencyAdmin role
   */
  function EMERGENCY_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the StakerAdmin role
   * @return The id of the StakerAdmin role
   */
  function STAKER_ADMIN_ROLE() external view returns (bytes32);
  /**
   * @notice Returns the identifier of the AssetListingAdmin role
   * @return The id of the AssetListingAdmin role
   */
  function ASSET_LISTING_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Set the role as admin of a specific role.
   * @dev By default the admin role for all roles is `DEFAULT_ADMIN_ROLE`.
   * @param role The role to be managed by the admin role
   * @param adminRole The admin role
   */
  function setRoleAdmin(bytes32 role, bytes32 adminRole) external;
 /**
   * @notice Adds a new admin as Souq
   * @param admin The address of the new admin
   */
  function addSouq(address admin) external;

  /**
   * @notice Removes an admin as Souq
   * @param admin The address of the admin to remove
   */
  function removeSouq(address admin) external;

  /**
   * @notice Returns true if the address is Souq, false otherwise
   * @param admin The address to check
   * @return True if the given address is Souq, false otherwise
   */
  function isSouq(address admin) external view returns (bool);

  /**
   * @notice Adds a new admin as VaultAdmin
   * @param admin The address of the new admin
   */
  function addVaultAdmin(address admin) external;

  /**
   * @notice Removes an admin as VaultAdmin
   * @param admin The address of the admin to remove
   */
  function removeVaultAdmin(address admin) external;

  /**
   * @notice Returns true if the address is VaultAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is VaultAdmin, false otherwise
   */
  function isVaultAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new admin as EmergencyAdmin
   * @param admin The address of the new admin
   */
  function addEmergencyAdmin(address admin) external;

  /**
   * @notice Removes an admin as EmergencyAdmin
   * @param admin The address of the admin to remove
   */
  function removeEmergencyAdmin(address admin) external;

  /**
   * @notice Returns true if the address is EmergencyAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is EmergencyAdmin, false otherwise
   */
  function isEmergencyAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new admin as StakerAdmin
   * @param admin The address of the new admin
   */
  function addStakerAdmin(address admin) external;

  /**
   * @notice Removes an admin as StakerAdmin
   * @param admin The address of the admin to remove
   */
  function removeStakerAdmin(address admin) external;

  /**
   * @notice Returns true if the address is StakerAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is StakerAdmin, false otherwise
   */
  function isStakerAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new admin as AssetListingAdmin
   * @param admin The address of the new admin
   */
  function addAssetListingAdmin(address admin) external;

  /**
   * @notice Removes an admin as AssetListingAdmin
   * @param admin The address of the admin to remove
   */
  function removeAssetListingAdmin(address admin) external;

  /**
   * @notice Returns true if the address is AssetListingAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is AssetListingAdmin, false otherwise
   */
  function isAssetListingAdmin(address admin) external view returns (bool);
}

// File: contracts/souq/libraries/helpers/Errors.sol


pragma solidity ^0.8.10;

/**
 * @title Errors library
 * @author Souq
 * @notice Defines the error messages emitted by the different contracts of the Souq protocol
 */
library Errors {
  string public constant CALLER_NOT_VAULT_ADMIN = "1"; // "The caller of the function is not a pool admin"
  string public constant CALLER_NOT_EMERGENCY_ADMIN = "2"; // "The caller of the function is not an emergency admin"
  string public constant CALLER_NOT_STAKER_ADMIN = "3"; // "The caller of the function is not a STAKER or pool admin"
  string public constant CALLER_NOT_ASSET_LISTING_ADMIN = "4"; // "The caller of the function is not an asset listing"
  string public constant ASSET_NOT_LISTED = "5"; // "Asset is not listed"
  string public constant ACL_ADMIN_CANNOT_BE_ZERO = "6";
  string public constant INVALID_ADDRESSES_PROVIDER = "7";
  string public constant CALLER_NOT_SOUQ = "8"; // "The caller of the function is not the souq contract"
  string public constant THRESHOLD_IS_ZERO = "9";  //threshold is zero or negative
  string public constant POOL_FEE_IS_ZERO = "10"; //pool fee is zero or negative
  string public constant ASSET_IS_PAUSED = "11"; //The asset being added or configured is paused
  string public constant VAULT_ASSETS_EXCEED_ASSET_COUNT = "12"; //The assets being added to the vault cannot be more than the total assets registered in the protocol
  string public constant VAULT_IS_PAUSED = "13"; //The vault is paused
  string public constant ASSET_DISABLED_FOR_UNDERLYING = "14"; //The asset cannot be used as an underlying collateral
  string public constant AMOUNT_IS_ZERO = "15"; //pool fee is zero or negative
  string public constant ASSET_ALREADY_EXISTS = "16"; //asset already exits
  string public constant ADDRESS_IS_ZERO = "17"; //address is address(0)
  string public constant AMOUNT_NOT_APPROVED="18"; //if amount to spend/transfer is not approved by the owner
  string public constant INSUFFICIENT_ASSET_FUNDS="19"; //Insufficient balance of asset
}

// File: contracts/souq/core/Souq.sol


pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;


// import {AggregatorV3Interface} from "../../interfaces/AggregatorV3Interface.sol";








contract souq is VersionedInitializable, SouqStorage {
    uint256 public constant POOL_REVISION = 0x1;
    address internal immutable ADDRESSES_PROVIDER;



    constructor(address provider) {
        ADDRESSES_PROVIDER = provider;
    }


    function initialize(address provider) external virtual initializer {
        require(provider == ADDRESSES_PROVIDER, Errors.INVALID_ADDRESSES_PROVIDER);
        _vaultCount = 0;
        _assetCount = 0;
        _positionCount = 0;
    }


    function getRevision() internal pure virtual override returns (uint256) {
        return POOL_REVISION;
    }

    //Add ERC20 Asset (USDT,USDC, etc)
    function addAsset(address asset, string memory name, string memory symbol, address priceOracle) external onlyVaultAdmin {
        require(asset != address(0),Errors.ADDRESS_IS_ZERO);
        require(_assets[asset].asset == address(0), Errors.ASSET_ALREADY_EXISTS);
        _assets[asset] = DataTypes.Asset({name: name,symbol: symbol, asset: asset, index: _assetCount,paused: false, priceOracle: priceOracle });
        _assetsList[_assetCount] = asset;
        _assetCount++;
    }

    //Pause Asset
    function pauseAsset(address asset, bool pause) public onlyVaultAdmin
    {
        _assets[asset].paused = pause;
    }
    
    //Get Asset Data per address
    function getAsset(address asset) view public returns (DataTypes.Asset memory){
        return _assets[asset];
    }

    //Get all active assets
    function getActiveAssets() view public returns (address[] memory assets)
    {
        uint256 assetCount = _assetCount;
        uint activeIndex = 0;
        for(uint256 i = 0; i < assetCount; i++)
        {
            if(_assets[_assetsList[i]].paused != false)
            {
              assets[activeIndex] = _assetsList[i];
              activeIndex++;
            }
        }
        return assets;
    }

    //Get all assets registered with the protocol
    function getAllAssets() view public returns (address[] memory)
    {
        uint256 assetCount = _assetCount;
        address[] memory assets = new address[](assetCount);
        for(uint256 i = 0; i < assetCount; i++)
        {
              assets[i] = _assetsList[i];
        }
        return assets;
    }

    //Get the configuration of the vault
    function getVaultAssetConfiguration(uint vaultId) external view returns(DataTypes.VaultData memory)
    {
        return _vaults[vaultId];
    }

    //Get the data of the asset that was deposited in the vault
    function getVaultUnderlyingAsset(uint vaultId, uint assetId) view external returns(DataTypes.AssetData memory)
    {
        return _vaultUnderlyingAssetsData[vaultId][_vaultUnderlyingAssetsList[vaultId][assetId]];
    }

    //Get the count of all assets that have been deposited in the vault
    function getVaultUnderlyingAssetsCount(uint vaultId) external view returns(uint)
    {
        return _vaultUnderlyingAssetCount[vaultId];
    }

    //Get the data of the Output asset from the vault
    function getVaultStakingAsset(uint vaultId, uint assetId) external view returns(DataTypes.AssetData memory)
    {
        return _vaultStakingAssetsData[vaultId][_vaultStakingAssetsList[vaultId][assetId]];
    }

    //Get the count of all the assets that were outputed from the vault
    function getVaultStakingAssetsCount(uint vaultId) external view returns(uint)
    {
        return _vaultStakingAssetCount[vaultId];
    }

    //Get the data of the particular asset configuration in the vault
    function getVaultAsset(uint vaultId, uint assetId) external view returns(DataTypes.VaultAsset memory)
    {
        return _vaultAssetsData[vaultId][_vaultAssetsList[vaultId][assetId]];
    }

    //Get the count of all configured assets in the vault
    function getVaultAssetsCount(uint vaultId) external view returns(uint)
    {
        return _vaultAssetCount[vaultId];
    }

    //Get the balance of an address in an ERC20 token
    function getAssetBalanceOf(address wallet,address asset) external view returns(uint)
    {
        require(wallet != address(0), Errors.ADDRESS_IS_ZERO);
        require(asset != address(0), Errors.ADDRESS_IS_ZERO);
       return IERC20(asset).balanceOf(wallet);
    }

    //Get the price of an asset in the protocol
    function getAssetPrice(address asset) external view returns (int)
    {
        require(_assets[asset].priceOracle != address(0), Errors.ADDRESS_IS_ZERO);
        AggregatorV3Interface priceFeed =  AggregatorV3Interface(_assets[asset].priceOracle);
        (, int answer, , , ) = priceFeed.latestRoundData();
        return answer;
    }

    //Get the ids of all the positions of a vault
    function getVaultPositionIds(uint vaultId) external view returns(uint[] memory)
    {
        uint positionCount = _vaultPositionCount[vaultId];
        uint[] memory positions = new uint[](positionCount);
        for(uint256 i = 0; i < positionCount; i++)
        {
              positions[i] = _vaultPositionsList[vaultId][i];
        }
        return positions;
    }

    //Get the data of a position
    function getPositionData(uint positionId) external view returns(DataTypes.PositionData memory)
    {
        return _positions[positionId];
    }

    //Get the asset deposited when opening the position
    function getPositionUnderlyingAsset(uint positionId, uint assetId) view external returns(DataTypes.AssetData memory)
    {
        return _positionUnderlyingAssetsData[positionId][_positionUnderlyingAssetsList[positionId][assetId]];
    }
    //Get the count of all assets deposited when opening the position.
    function getPositionUnderlyingAssetsCount(uint positionId) external view returns(uint)
    {
        return _positionUnderlyingAssetCount[positionId];
    }
    /////////////////////////////////
    //TODO: make an update vault function, not needed for example
    //function updateVault(...) ... returns (...)
    //{
    //change asset configuration
    //change vault configuration
    //add assets to configuration
    //remove assets from configuration
    //}
    /////////////////////////////////////

    //Add a new vault with configuration of it's assets (which one is input, output, both)
    function addVault(uint threshold, uint poolFee,bool paused, string memory name, DataTypes.VaultAsset[] memory vaultAssetData ) external onlyVaultAdmin {
       require(threshold > 0, Errors.THRESHOLD_IS_ZERO);
       require(poolFee > 0, Errors.POOL_FEE_IS_ZERO);
        _vaults[_vaultCount] = DataTypes.VaultData({index: _vaultCount,name: name, paused: paused, poolFee: poolFee, threshold: threshold});
        uint vaultAssetDataCount = vaultAssetData.length;
        
        require(vaultAssetDataCount <= _assetCount, Errors.VAULT_ASSETS_EXCEED_ASSET_COUNT);
        uint underlyingIndex = 0;
        uint stakingIndex = 0;
        for(uint256 i = 0; i < vaultAssetDataCount; i++)
        {
              require(_assets[_assetsList[i]].paused == false, Errors.ASSET_IS_PAUSED);
              uint assetIndex = vaultAssetData[i].assetIndex;
              address assetAddress = _assetsList[assetIndex];
              _vaultAssetsList[_vaultCount][i] = assetAddress;
              
              _vaultAssetsData[_vaultCount][assetAddress] = vaultAssetData[i];
              _vaultAssetCount[_vaultCount]++;
              if(vaultAssetData[i].asUnderlying == true)
              {
               _vaultUnderlyingAssetsData[_vaultCount][assetAddress] = DataTypes.AssetData({index: underlyingIndex, assetIndex: assetIndex, amount:0});
               _vaultUnderlyingAssetsList[_vaultCount][underlyingIndex] = assetAddress;
               _vaultUnderlyingAssetCount[_vaultCount]++;
                underlyingIndex++;
              }
              if(vaultAssetData[i].forStaking == true)
              {
               _vaultStakingAssetsData[_vaultCount][assetAddress] = DataTypes.AssetData({index: stakingIndex, assetIndex: assetIndex, amount:0});
               _vaultStakingAssetsList[_vaultCount][stakingIndex] = assetAddress;
               _vaultStakingAssetCount[_vaultCount]++;
                stakingIndex++;
              }
        }
        _vaultCount++;
    }

    //pause vault
    function pauseVault(uint vaultId, bool paused) external onlyVaultAdmin
    {
        _vaults[vaultId].paused = paused;
    }

    //Get ids of all vaults
    function getAllVaults() view external returns(uint[] memory)
    {
         uint256 vaultListCount = _vaultCount;
         uint[] memory vaults = new uint[](vaultListCount);
         for (uint256 i = 0; i < vaultListCount; i++) {
             vaults[i] = _vaults[i].index;
         }
     return vaults;
    }

    //Get ids of active vaults only
    function getActiveVaults() view external returns(uint[] memory vaults)
    {
         uint256 vaultListCount = _vaultCount;
         uint activeIndex = 0;
         for (uint256 i = 0; i < vaultListCount; i++) {
          if (_vaults[i].paused != false)
          {
             vaults[activeIndex] = _vaults[i].index;
             activeIndex++;
          }
         }
     return vaults;
    }



    //Check if vault admin role
    function _onlyVaultAdmin() internal view virtual {
        require(
            IACManager(IAddressesProvider(ADDRESSES_PROVIDER).getACLManager()).isVaultAdmin(msg.sender),
            Errors.CALLER_NOT_VAULT_ADMIN
        );
    }

    /**
     * @dev Only vault admin can call functions marked by this modifier.
     **/
    modifier onlyVaultAdmin() {
        _onlyVaultAdmin();
        _;
    }

    //Send tokens to the vault, check if they are accepted as per the configuration, if approved and has enough balance.
    //Transfer the tokens out, transfer the poolFee and mint a new NFT with the position forr the user
    function supplyToVault(
        uint256 vaultId,
        uint maturity,
        DataTypes.AssetData[] memory assetData
    ) external {
        require(_vaults[vaultId].paused == false, Errors.VAULT_IS_PAUSED);
        address staker = IAddressesProvider(ADDRESSES_PROVIDER).getStaker();
        address treasury = IAddressesProvider(ADDRESSES_PROVIDER).getTreasury();
        address vaultAdd = IAddressesProvider(ADDRESSES_PROVIDER).getVault();
        for(uint i =0; i< assetData.length; i++)
        {
            uint assetIndex = assetData[i].assetIndex;
            address assetAddress = _assetsList[assetIndex];
            require(assetData[i].amount > 0, Errors.AMOUNT_IS_ZERO);
            require(_assets[assetAddress].paused == false, Errors.ASSET_IS_PAUSED);
            require(_vaultAssetsData[vaultId][assetAddress].asUnderlying == true, Errors.ASSET_DISABLED_FOR_UNDERLYING);
            require(IERC20(assetAddress).balanceOf(msg.sender) >= assetData[i].amount, Errors.INSUFFICIENT_ASSET_FUNDS);
            require(IERC20(assetAddress).allowance(msg.sender,address(this)) >= assetData[i].amount, Errors.AMOUNT_NOT_APPROVED);
            uint poolFee = _vaults[vaultId].poolFee;
            uint stake = ((100 - poolFee)*assetData[i].amount)/100;
            IERC20(assetAddress).transferFrom(msg.sender,staker,stake);
            uint treasure = (poolFee*assetData[i].amount)/100;
            IERC20(assetAddress).transferFrom(msg.sender,treasury,treasure);
            assetData[i].amount = stake;
            _positionUnderlyingAssetsList[_positionCount][i] = assetAddress;
            _positionUnderlyingAssetsData[_positionCount][assetAddress]=assetData[i];
            _positionUnderlyingAssetCount[_positionCount]++;
            _vaultUnderlyingAssetsData[vaultId][assetAddress].amount += assetData[i].amount;
        }
        IVault(vaultAdd).mint(msg.sender,_positionCount);
        uint timeNow = block.timestamp;
        uint newMaturity =  timeNow + (maturity*30 days);
        _positions[_positionCount] = DataTypes.PositionData({maturity: newMaturity, index: _positionCount, date: timeNow, vested: 0, vault: vaultId, assets: assetData.length });
        _vaultPositionsList[vaultId][_vaultPositionCount[vaultId]] = _positionCount;
        _vaultPositionCount[vaultId]++;
        _positionCount++;
    }

    /////////////////////////////////////////////
    ////TODO: make a "withdraw after maturity" function



    ////////////////////////////////////////////////
    ////TODO: make a "withdraw unlocked rewards" function
}