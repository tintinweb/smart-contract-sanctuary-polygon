pragma solidity 0.7.4;

import "@horizongames/skyweaver-contracts/contracts/factories/RewardFactory.sol";

contract LeaderboardRewardFactory is RewardFactory {
  constructor(
    address _initialOwner,
    address _assetsAddr,
    uint256 _periodLength,
    uint256 _periodMintLimit,
    bool _whitelistOnly
  ) RewardFactory(_initialOwner, _assetsAddr, _periodLength, _periodMintLimit, _whitelistOnly) public {}
}

pragma solidity 0.7.4;

import "../utils/TieredOwnable.sol";
import "../interfaces/ISkyweaverAssets.sol";
import "@0xsequence/erc-1155/contracts/utils/SafeMath.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC165.sol";

/**
 * @notice This is a contract allowing contract owner to mint up to N 
 *         assets per period of 6 hours.
 * @dev This contract should only be able to mint some asset types
 */
contract RewardFactory is TieredOwnable {
  using SafeMath for uint256;

  /***********************************|
  |             Variables             |
  |__________________________________*/

  // Token information
  ISkyweaverAssets immutable public skyweaverAssets; // ERC-1155 Skyweaver assets contract

  // Period variables
  uint256 internal period;                // Current period
  uint256 internal availableSupply;       // Amount of assets that can currently be minted
  uint256 public periodMintLimit;         // Amount that can be minted within 6h
  uint256 immutable public PERIOD_LENGTH; // Length of each mint periods in seconds

  // Whitelist
  bool internal immutable MINT_WHITELIST_ONLY;
  mapping(uint256 => bool) public mintWhitelist;

  // Event
  event PeriodMintLimitChanged(uint256 oldMintingLimit, uint256 newMintingLimit);
  event AssetsEnabled(uint256[] enabledIds);
  event AssetsDisabled(uint256[] disabledIds);
  
  /***********************************|
  |            Constructor            |
  |__________________________________*/

  /**
   * @notice Create factory, link skyweaver assets and store initial parameters
   * @param _firstOwner      Address of the first owner
   * @param _assetsAddr      The address of the ERC-1155 Assets Token contract
   * @param _periodLength    Number of seconds each period lasts
   * @param _periodMintLimit Can only mint N assets per period
   * @param _whitelistOnly   Whether this factory uses a mint whitelist or not
   */
  constructor(
    address _firstOwner,
    address _assetsAddr,
    uint256 _periodLength,
    uint256 _periodMintLimit,
    bool _whitelistOnly
  ) TieredOwnable(_firstOwner) public {
    require(
      _assetsAddr != address(0) &&
      _periodLength > 0 &&
      _periodMintLimit > 0,
      "RewardFactory#constructor: INVALID_INPUT"
    );

    // Assets
    skyweaverAssets = ISkyweaverAssets(_assetsAddr);

    // Set Period length
    PERIOD_LENGTH = _periodLength;

    // Set whether this factory uses a mint whitelist or not
    MINT_WHITELIST_ONLY = _whitelistOnly;

    // Set current period
    period = block.timestamp / _periodLength; // From livePeriod()
    availableSupply = _periodMintLimit;

    // Rewards parameters
    periodMintLimit = _periodMintLimit;
    emit PeriodMintLimitChanged(0, _periodMintLimit);
  }


  /***********************************|
  |         Management Methods        |
  |__________________________________*/

  /**
   * @notice Will update the daily mint limit
   * @dev This change will take effect immediatly once executed
   * @param _newPeriodMintLimit Amount of assets that can be minted within a period
   */
  function updatePeriodMintLimit(uint256 _newPeriodMintLimit) external onlyOwnerTier(HIGHEST_OWNER_TIER) {
    // Immediately update supply instead of waiting for next period
    if (availableSupply > _newPeriodMintLimit) {
      availableSupply = _newPeriodMintLimit;
    }

    emit PeriodMintLimitChanged(periodMintLimit, _newPeriodMintLimit);
    periodMintLimit = _newPeriodMintLimit;
  }

  /**
   * @notice Will enable these tokens to be minted by this factory
   * @param _enabledIds IDs this factory can mint
   */
  function enableMint(uint256[] calldata _enabledIds) external onlyOwnerTier(HIGHEST_OWNER_TIER) {
    for (uint256 i = 0; i < _enabledIds.length; i++) {
      mintWhitelist[_enabledIds[i]] = true;
    }
    emit AssetsEnabled(_enabledIds);
  }

  /**
   * @notice Will prevent these ids from being minted by this factory
   * @param _disabledIds IDs this factory can mint
   */
  function disableMint(uint256[] calldata _disabledIds) external onlyOwnerTier(HIGHEST_OWNER_TIER) {
    for (uint256 i = 0; i < _disabledIds.length; i++) {
      mintWhitelist[_disabledIds[i]] = false;
    }
    emit AssetsDisabled(_disabledIds);
  }


  /***********************************|
  |      Receiver Method Handler      |
  |__________________________________*/

  /**
   * @notice Prevents receiving Ether or calls to unsuported methods
   */
  fallback () external {
    revert("RewardFactory#_: UNSUPPORTED_METHOD");
  }

  /***********************************|
  |         Minting Functions         |
  |__________________________________*/

  /**
   * @notice Will mint tokens to user
   * @dev Can only mint up to the periodMintLimit in a given 6hour period
   * @param _to      The address that receives the assets
   * @param _ids     Array of Tokens ID that are minted
   * @param _amounts Amount of Tokens id minted for each corresponding Token id in _ids
   * @param _data    Byte array passed to recipient if recipient is a contract
   */
  function batchMint(address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data)
    external onlyOwnerTier(1)
  {
    uint256 live_period = livePeriod();
    uint256 stored_period = period;
    uint256 available_supply;

    // Update period and refresh the available supply if period
    // is different, otherwise use current available supply.
    if (live_period == stored_period) {
      available_supply = availableSupply;
    } else {
      available_supply = periodMintLimit;
      period = live_period;
    }

    // If there is an insufficient available supply, this will revert
    for (uint256 i = 0; i < _ids.length; i++) {
      available_supply = available_supply.sub(_amounts[i]);
      if (MINT_WHITELIST_ONLY) {
        require(mintWhitelist[_ids[i]], "RewardFactory#batchMint: ID_IS_NOT_WHITELISTED");
      }
    }

    // Store available supply
    availableSupply = available_supply;
    
    // Mint assets
    skyweaverAssets.batchMint(_to, _ids, _amounts, _data);
  }


  /***********************************|
  |         Utility Functions         |
  |__________________________________*/

  /**
   * @notice Returns how many cards can currently be minted by this factory
   */
  function getAvailableSupply() external view returns (uint256) {
    return livePeriod() == period ? availableSupply : periodMintLimit;
  }

  /**
   * @notice Calculate the current period
   */
  function livePeriod() public view returns (uint256) {
    return block.timestamp / PERIOD_LENGTH;
  }

  /**
   * @notice Indicates whether a contract implements a given interface.
   * @param interfaceID The ERC-165 interface ID that is queried for support.
   * @return True if contract interface is supported.
   */
  function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
    return  interfaceID == type(IERC165).interfaceId;
  }
}

pragma solidity 0.7.4;

/**
 * @notice The TieredOwnable can assign ownership tiers to addresses,
 * allowing inheriting contracts to choose which tier can call which function.
 */
contract TieredOwnable {
  uint256 constant internal HIGHEST_OWNER_TIER = 2**256-1; //Highest possible tier

  mapping(address => uint256) internal ownerTier;
  event OwnershipGranted(address indexed owner, uint256 indexed previousTier, uint256 indexed newTier);

  /**
   * @dev Sets the _firstOwner provided to highest owner tier
   * @dev _firstOwner First address to be a owner of this contract
   */
  constructor (address _firstOwner) {
    require(_firstOwner != address(0), "TieredOwnable#constructor: INVALID_FIRST_OWNER");
    ownerTier[_firstOwner] = HIGHEST_OWNER_TIER;
    emit OwnershipGranted(_firstOwner, 0, HIGHEST_OWNER_TIER);
  }

  /**
   * @dev Throws if called by an account that's in lower ownership tier than expected
   */
  modifier onlyOwnerTier(uint256 _minTier) {
    require(ownerTier[msg.sender] >= _minTier, "TieredOwnable#onlyOwnerTier: OWNER_TIER_IS_TOO_LOW");
    _;
  }

  /**
   * @notice Highest owners can change ownership tier of other owners
   * @dev Prevents changing sender's tier to ensure there is always at least one HIGHEST_OWNER_TIER owner.
   * @param _address Address of the owner
   * @param _tier    Ownership tier assigned to owner
   */
  function assignOwnership(address _address, uint256 _tier) external onlyOwnerTier(HIGHEST_OWNER_TIER) {
    require(_address != address(0), "TieredOwnable#assignOwnership: INVALID_ADDRESS");
    require(msg.sender != _address, "TieredOwnable#assignOwnership: UPDATING_SELF_TIER");
    emit OwnershipGranted(_address, ownerTier[_address], _tier);
    ownerTier[_address] = _tier;
  }

  /**
   * @notice Returns the ownership tier of provided owner
   * @param _owner Owner's address to query ownership tier
   */
  function getOwnerTier(address _owner) external view returns (uint256) {
    return ownerTier[_owner];
  }
}

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

interface ISkyweaverAssets {

  /***********************************|
  |               Events              |
  |__________________________________*/

  event FactoryActivation(address indexed factory);
  event FactoryShutdown(address indexed factory);
  event MintPermissionAdded(address indexed factory, AssetRange new_range);
  event MintPermissionRemoved(address indexed factory, AssetRange deleted_range);

  // Struct for mint ID ranges permissions
  struct AssetRange {
    uint256 minID;
    uint256 maxID;
  }

  /***********************************|
  |    Supplies Management Methods    |
  |__________________________________*/

  /**
   * @notice Set max issuance for some token IDs that can't ever be increased
   * @dev Can only decrease the max issuance if already set, but can't set it *back* to 0.
   * @param _ids Array of token IDs to set the max issuance
   * @param _newMaxIssuances Array of max issuances for each corresponding ID
   */
  function setMaxIssuances(uint256[] calldata _ids, uint256[] calldata _newMaxIssuances) external;

  /***********************************|
  |     Factory Management Methods    |
  |__________________________________*/

  /**
   * @notice Will allow a factory to mint some token ids
   * @param _factory   Address of the factory to update permission
   * @param _minRange  Minimum ID (inclusive) in id range that factory will be able to mint
   * @param _maxRange  Maximum ID (inclusive) in id range that factory will be able to mint
   * @param _startTime Timestamp when the range becomes valid
   * @param _endTime   Timestamp after which the range is no longer valid 
   */
  function addMintPermission(address _factory, uint64 _minRange, uint64 _maxRange, uint64 _startTime, uint64 _endTime) external;

  /**
   * @notice Will remove the permission a factory has to mint some token ids
   * @param _factory    Address of the factory to update permission
   * @param _rangeIndex Array's index where the range to delete is located for _factory
   */
  function removeMintPermission(address _factory, uint256 _rangeIndex) external;

  /**
   * @notice Will ALLOW factory to print some assets specified in `canPrint` mapping
   * @param _factory Address of the factory to activate
   */
  function activateFactory(address _factory) external;

  /**
   * @notice Will DISALLOW factory to print any asset
   * @param _factory Address of the factory to shutdown
   */
  function shutdownFactory(address _factory) external;

  /**
   * @notice Will forever prevent new mint permissions for provided ids
   * @param _range AssetRange struct for range of asset that can't be granted
   *               new mint permission to
   */
  function lockRangeMintPermissions(AssetRange calldata _range) external;


  /***********************************|
  |         Getter Functions          |
  |__________________________________*/

  /**
   * @return Returns whether a factory is active or not
   */
  function getFactoryStatus(address _factory) external view returns (bool);

  /**
   * @return Returns whether the sale has ended or not
   */
  function getFactoryAccessRanges(address _factory) external view returns ( AssetRange[] memory);

  /**
   * @notice Get the max issuance of multiple asset IDs
   * @dev The max issuance of a token does not reflect the maximum supply, only
   *      how many tokens can be minted once the maxIssuance for a token is set.
   * @param _ids Array containing the assets IDs
   * @return The current max issuance of each asset ID in _ids
   */
  function getMaxIssuances(uint256[] calldata _ids) external view returns (uint256[] memory);

  /**
   * @notice Get the current issuanc of multiple asset ID
   * @dev The current issuance of a token does not reflect the current supply, only
   *      how many tokens since a max issuance was set for a given token id.
   * @param _ids Array containing the assets IDs
   * @return The current issuance of each asset ID in _ids
   */
  function getCurrentIssuances(uint256[] calldata _ids)external view returns (uint256[] memory);

  /***************************************|
  |           Minting Functions           |
  |______________________________________*/

  /**
   * @dev Mint _amount of tokens of a given id if not frozen and if max supply not exceeded
   * @param _to     The address to mint tokens to.
   * @param _id     Token id to mint
   * @param _amount The amount to be minted
   * @param _data   Byte array of data to pass to recipient if it's a contract
   */
  function mint(address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;

  /**
   * @dev Mint tokens for each ids in _ids
   * @param _to      The address to mint tokens to.
   * @param _ids     Array of ids to mint
   * @param _amounts Array of amount of tokens to mint per id
   * @param _data    Byte array of data to pass to recipient if it's a contract
   */
  function batchMint(address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;


  /***************************************|
  |           Burning Functions           |
  |______________________________________*/

  /**
   * @notice Burn sender's_amount of tokens of a given token id
   * @param _id      Token id to burn
   * @param _amount  The amount to be burned
   */
  function burn(uint256 _id, uint256 _amount) external;

  /**
   * @notice Burn sender's tokens of given token id for each (_ids[i], _amounts[i]) pair
   * @param _ids      Array of token ids to burn
   * @param _amounts  Array of the amount to be burned
   */
  function batchBurn(uint256[] calldata _ids, uint256[] calldata _amounts) external;
}

pragma solidity 0.7.4;


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {

  /**
   * @dev Multiplies two unsigned integers, reverts on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath#mul: OVERFLOW");

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath#sub: UNDERFLOW");
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath#add: OVERFLOW");

    return c; 
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
    return a % b;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;


/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {

    /**
     * @notice Query if a contract implements an interface
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas
     * @param _interfaceId The interface identifier, as specified in ERC-165
     */
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}