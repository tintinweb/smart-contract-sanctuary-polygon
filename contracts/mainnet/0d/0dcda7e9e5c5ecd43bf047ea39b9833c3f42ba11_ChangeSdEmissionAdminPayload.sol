// SPDX-License-Identifier: MIT

/*
   _      ΞΞΞΞ      _
  /_;-.__ / _\  _.-;_\
     `-._`'`_/'`.-'
         `\   /`
          |  /
         /-.(
         \_._\
          \ \`;
           > |/
          / //
          |//
          \(\
           ``
     defijesus.eth
*/

pragma solidity ^0.8.0;

import {IEmissionManager} from '../interfaces/IEmissionManager.sol';
import {IProposalGenericExecutor} from '../interfaces/IProposalGenericExecutor.sol';

/**
 * @title AddEmissionAdminPayload
 * @author Llama
 * @dev Setting new Emssion Admin for SD token in Aave V3 Polygon Liquidity Pool
 * Governance Forum Post: https://governance.aave.com/t/arc-sd-emission-admin-for-polygon-v3-liquidity-pool/10658
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0x58c20dae66638085b5e834cd66ef560a34a71cad88cb1866fb9a726a1fb1861a
 */
contract ChangeSdEmissionAdminPayload is IProposalGenericExecutor {
  address public constant EMISSION_MANAGER = 0x048f2228D7Bf6776f99aB50cB1b1eaB4D1d4cA73;

  address public constant SD = 0x1d734A02eF1e1f5886e66b0673b71Af5B53ffA94;

  address public constant NEW_EMISSION_ADMIN = 0x51358004cFe135E64453d7F6a0dC433CAba09A2a;

  function execute() public {
    IEmissionManager(EMISSION_MANAGER).setEmissionAdmin(SD, NEW_EMISSION_ADMIN);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IEACAggregatorProxy {
  function decimals() external view returns (uint8);

  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy);
}

interface ITransferStrategyBase {
  event EmergencyWithdrawal(
    address indexed caller,
    address indexed token,
    address indexed to,
    uint256 amount
  );

  /**
   * @dev Perform custom transfer logic via delegate call from source contract to a TransferStrategy implementation
   * @param to Account to transfer rewards
   * @param reward Address of the reward token
   * @param amount Amount to transfer to the "to" address parameter
   * @return Returns true bool if transfer logic succeeds
   */
  function performTransfer(
    address to,
    address reward,
    uint256 amount
  ) external returns (bool);

  /**
   * @return Returns the address of the Incentives Controller
   */
  function getIncentivesController() external view returns (address);

  /**
   * @return Returns the address of the Rewards admin
   */
  function getRewardsAdmin() external view returns (address);

  /**
   * @dev Perform an emergency token withdrawal only callable by the Rewards admin
   * @param token Address of the token to withdraw funds from this contract
   * @param to Address of the recipient of the withdrawal
   * @param amount Amount of the withdrawal
   */
  function emergencyWithdrawal(
    address token,
    address to,
    uint256 amount
  ) external;
}

library RewardsDataTypes {
  struct RewardsConfigInput {
    uint88 emissionPerSecond;
    uint256 totalSupply;
    uint32 distributionEnd;
    address asset;
    address reward;
    ITransferStrategyBase transferStrategy;
    IEACAggregatorProxy rewardOracle;
  }

  struct UserAssetBalance {
    address asset;
    uint256 userBalance;
    uint256 totalSupply;
  }

  struct UserData {
    uint104 index; // matches reward index
    uint128 accrued;
  }

  struct RewardData {
    uint104 index;
    uint88 emissionPerSecond;
    uint32 lastUpdateTimestamp;
    uint32 distributionEnd;
    mapping(address => UserData) usersData;
  }

  struct AssetData {
    mapping(address => RewardData) rewards;
    mapping(uint128 => address) availableRewards;
    uint128 availableRewardsCount;
    uint8 decimals;
  }
}

/**
 * @title IRewardsDistributor
 * @author Aave
 * @notice Defines the basic interface for a Rewards Distributor.
 */
interface IRewardsDistributor {
  /**
   * @dev Emitted when the configuration of the rewards of an asset is updated.
   * @param asset The address of the incentivized asset
   * @param reward The address of the reward token
   * @param oldEmission The old emissions per second value of the reward distribution
   * @param newEmission The new emissions per second value of the reward distribution
   * @param oldDistributionEnd The old end timestamp of the reward distribution
   * @param newDistributionEnd The new end timestamp of the reward distribution
   * @param assetIndex The index of the asset distribution
   */
  event AssetConfigUpdated(
    address indexed asset,
    address indexed reward,
    uint256 oldEmission,
    uint256 newEmission,
    uint256 oldDistributionEnd,
    uint256 newDistributionEnd,
    uint256 assetIndex
  );

  /**
   * @dev Emitted when rewards of an asset are accrued on behalf of a user.
   * @param asset The address of the incentivized asset
   * @param reward The address of the reward token
   * @param user The address of the user that rewards are accrued on behalf of
   * @param assetIndex The index of the asset distribution
   * @param userIndex The index of the asset distribution on behalf of the user
   * @param rewardsAccrued The amount of rewards accrued
   */
  event Accrued(
    address indexed asset,
    address indexed reward,
    address indexed user,
    uint256 assetIndex,
    uint256 userIndex,
    uint256 rewardsAccrued
  );

  /**
   * @dev Emitted when the emission manager address is updated.
   * @param oldEmissionManager The address of the old emission manager
   * @param newEmissionManager The address of the new emission manager
   */
  event EmissionManagerUpdated(
    address indexed oldEmissionManager,
    address indexed newEmissionManager
  );

  /**
   * @dev Sets the end date for the distribution
   * @param asset The asset to incentivize
   * @param reward The reward token that incentives the asset
   * @param newDistributionEnd The end date of the incentivization, in unix time format
   **/
  function setDistributionEnd(
    address asset,
    address reward,
    uint32 newDistributionEnd
  ) external;

  /**
   * @dev Sets the emission per second of a set of reward distributions
   * @param asset The asset is being incentivized
   * @param rewards List of reward addresses are being distributed
   * @param newEmissionsPerSecond List of new reward emissions per second
   */
  function setEmissionPerSecond(
    address asset,
    address[] calldata rewards,
    uint88[] calldata newEmissionsPerSecond
  ) external;

  /**
   * @dev Gets the end date for the distribution
   * @param asset The incentivized asset
   * @param reward The reward token of the incentivized asset
   * @return The timestamp with the end of the distribution, in unix time format
   **/
  function getDistributionEnd(address asset, address reward) external view returns (uint256);

  /**
   * @dev Returns the index of a user on a reward distribution
   * @param user Address of the user
   * @param asset The incentivized asset
   * @param reward The reward token of the incentivized asset
   * @return The current user asset index, not including new distributions
   **/
  function getUserAssetIndex(
    address user,
    address asset,
    address reward
  ) external view returns (uint256);

  /**
   * @dev Returns the configuration of the distribution reward for a certain asset
   * @param asset The incentivized asset
   * @param reward The reward token of the incentivized asset
   * @return The index of the asset distribution
   * @return The emission per second of the reward distribution
   * @return The timestamp of the last update of the index
   * @return The timestamp of the distribution end
   **/
  function getRewardsData(address asset, address reward)
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    );

  /**
   * @dev Returns the list of available reward token addresses of an incentivized asset
   * @param asset The incentivized asset
   * @return List of rewards addresses of the input asset
   **/
  function getRewardsByAsset(address asset) external view returns (address[] memory);

  /**
   * @dev Returns the list of available reward addresses
   * @return List of rewards supported in this contract
   **/
  function getRewardsList() external view returns (address[] memory);

  /**
   * @dev Returns the accrued rewards balance of a user, not including virtually accrued rewards since last distribution.
   * @param user The address of the user
   * @param reward The address of the reward token
   * @return Unclaimed rewards, not including new distributions
   **/
  function getUserAccruedRewards(address user, address reward) external view returns (uint256);

  /**
   * @dev Returns a single rewards balance of a user, including virtually accrued and unrealized claimable rewards.
   * @param assets List of incentivized assets to check eligible distributions
   * @param user The address of the user
   * @param reward The address of the reward token
   * @return The rewards amount
   **/
  function getUserRewards(
    address[] calldata assets,
    address user,
    address reward
  ) external view returns (uint256);

  /**
   * @dev Returns a list all rewards of a user, including already accrued and unrealized claimable rewards
   * @param assets List of incentivized assets to check eligible distributions
   * @param user The address of the user
   * @return The list of reward addresses
   * @return The list of unclaimed amount of rewards
   **/
  function getAllUserRewards(address[] calldata assets, address user)
    external
    view
    returns (address[] memory, uint256[] memory);

  /**
   * @dev Returns the decimals of an asset to calculate the distribution delta
   * @param asset The address to retrieve decimals
   * @return The decimals of an underlying asset
   */
  function getAssetDecimals(address asset) external view returns (uint8);

  /**
   * @dev Returns the address of the emission manager
   * @return The address of the EmissionManager
   */
  function getEmissionManager() external view returns (address);

  /**
   * @dev Updates the address of the emission manager
   * @param emissionManager The address of the new EmissionManager
   */
  function setEmissionManager(address emissionManager) external;
}

/**
 * @title IRewardsController
 * @author Aave
 * @notice Defines the basic interface for a Rewards Controller.
 */
interface IRewardsController is IRewardsDistributor {
  /**
   * @dev Emitted when a new address is whitelisted as claimer of rewards on behalf of a user
   * @param user The address of the user
   * @param claimer The address of the claimer
   */
  event ClaimerSet(address indexed user, address indexed claimer);

  /**
   * @dev Emitted when rewards are claimed
   * @param user The address of the user rewards has been claimed on behalf of
   * @param reward The address of the token reward is claimed
   * @param to The address of the receiver of the rewards
   * @param claimer The address of the claimer
   * @param amount The amount of rewards claimed
   */
  event RewardsClaimed(
    address indexed user,
    address indexed reward,
    address indexed to,
    address claimer,
    uint256 amount
  );

  /**
   * @dev Emitted when a transfer strategy is installed for the reward distribution
   * @param reward The address of the token reward
   * @param transferStrategy The address of TransferStrategy contract
   */
  event TransferStrategyInstalled(address indexed reward, address indexed transferStrategy);

  /**
   * @dev Emitted when the reward oracle is updated
   * @param reward The address of the token reward
   * @param rewardOracle The address of oracle
   */
  event RewardOracleUpdated(address indexed reward, address indexed rewardOracle);

  /**
   * @dev Whitelists an address to claim the rewards on behalf of another address
   * @param user The address of the user
   * @param claimer The address of the claimer
   */
  function setClaimer(address user, address claimer) external;

  /**
   * @dev Sets a TransferStrategy logic contract that determines the logic of the rewards transfer
   * @param reward The address of the reward token
   * @param transferStrategy The address of the TransferStrategy logic contract
   */
  function setTransferStrategy(address reward, ITransferStrategyBase transferStrategy) external;

  /**
   * @dev Sets an Aave Oracle contract to enforce rewards with a source of value.
   * @notice At the moment of reward configuration, the Incentives Controller performs
   * a check to see if the reward asset oracle is compatible with IEACAggregator proxy.
   * This check is enforced for integrators to be able to show incentives at
   * the current Aave UI without the need to setup an external price registry
   * @param reward The address of the reward to set the price aggregator
   * @param rewardOracle The address of price aggregator that follows IEACAggregatorProxy interface
   */
  function setRewardOracle(address reward, IEACAggregatorProxy rewardOracle) external;

  /**
   * @dev Get the price aggregator oracle address
   * @param reward The address of the reward
   * @return The price oracle of the reward
   */
  function getRewardOracle(address reward) external view returns (address);

  /**
   * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
   * @param user The address of the user
   * @return The claimer address
   */
  function getClaimer(address user) external view returns (address);

  /**
   * @dev Returns the Transfer Strategy implementation contract address being used for a reward address
   * @param reward The address of the reward
   * @return The address of the TransferStrategy contract
   */
  function getTransferStrategy(address reward) external view returns (address);

  /**
   * @dev Configure assets to incentivize with an emission of rewards per second until the end of distribution.
   * @param config The assets configuration input, the list of structs contains the following fields:
   *   uint104 emissionPerSecond: The emission per second following rewards unit decimals.
   *   uint256 totalSupply: The total supply of the asset to incentivize
   *   uint40 distributionEnd: The end of the distribution of the incentives for an asset
   *   address asset: The asset address to incentivize
   *   address reward: The reward token address
   *   ITransferStrategy transferStrategy: The TransferStrategy address with the install hook and claim logic.
   *   IEACAggregatorProxy rewardOracle: The Price Oracle of a reward to visualize the incentives at the UI Frontend.
   *                                     Must follow Chainlink Aggregator IEACAggregatorProxy interface to be compatible.
   */
  function configureAssets(RewardsDataTypes.RewardsConfigInput[] memory config) external;

  /**
   * @dev Called by the corresponding asset on any update that affects the rewards distribution
   * @param user The address of the user
   * @param userBalance The user balance of the asset
   * @param totalSupply The total supply of the asset
   **/
  function handleAction(
    address user,
    uint256 userBalance,
    uint256 totalSupply
  ) external;

  /**
   * @dev Claims reward for a user to the desired address, on all the assets of the pool, accumulating the pending rewards
   * @param assets List of assets to check eligible distributions before claiming rewards
   * @param amount The amount of rewards to claim
   * @param to The address that will be receiving the rewards
   * @param reward The address of the reward token
   * @return The amount of rewards claimed
   **/
  function claimRewards(
    address[] calldata assets,
    uint256 amount,
    address to,
    address reward
  ) external returns (uint256);

  /**
   * @dev Claims reward for a user on behalf, on all the assets of the pool, accumulating the pending rewards. The
   * caller must be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @param amount The amount of rewards to claim
   * @param user The address to check and claim rewards
   * @param to The address that will be receiving the rewards
   * @param reward The address of the reward token
   * @return The amount of rewards claimed
   **/
  function claimRewardsOnBehalf(
    address[] calldata assets,
    uint256 amount,
    address user,
    address to,
    address reward
  ) external returns (uint256);

  /**
   * @dev Claims reward for msg.sender, on all the assets of the pool, accumulating the pending rewards
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @param amount The amount of rewards to claim
   * @param reward The address of the reward token
   * @return The amount of rewards claimed
   **/
  function claimRewardsToSelf(
    address[] calldata assets,
    uint256 amount,
    address reward
  ) external returns (uint256);

  /**
   * @dev Claims all rewards for a user to the desired address, on all the assets of the pool, accumulating the pending rewards
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @param to The address that will be receiving the rewards
   * @return rewardsList List of addresses of the reward tokens
   * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardList"
   **/
  function claimAllRewards(address[] calldata assets, address to)
    external
    returns (address[] memory rewardsList, uint256[] memory claimedAmounts);

  /**
   * @dev Claims all rewards for a user on behalf, on all the assets of the pool, accumulating the pending rewards. The caller must
   * be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @param user The address to check and claim rewards
   * @param to The address that will be receiving the rewards
   * @return rewardsList List of addresses of the reward tokens
   * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardsList"
   **/
  function claimAllRewardsOnBehalf(
    address[] calldata assets,
    address user,
    address to
  ) external returns (address[] memory rewardsList, uint256[] memory claimedAmounts);

  /**
   * @dev Claims all reward for msg.sender, on all the assets of the pool, accumulating the pending rewards
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @return rewardsList List of addresses of the reward tokens
   * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardsList"
   **/
  function claimAllRewardsToSelf(address[] calldata assets)
    external
    returns (address[] memory rewardsList, uint256[] memory claimedAmounts);
}

/**
 * @title IEmissionManager
 * @author Aave
 * @notice Defines the basic interface for the Emission Manager
 */
interface IEmissionManager {
  /**
   * @dev Emitted when the admin of a reward emission is updated.
   * @param reward The address of the rewarding token
   * @param oldAdmin The address of the old emission admin
   * @param newAdmin The address of the new emission admin
   */
  event EmissionAdminUpdated(
    address indexed reward,
    address indexed oldAdmin,
    address indexed newAdmin
  );

  /**
   * @dev Configure assets to incentivize with an emission of rewards per second until the end of distribution.
   * @dev Only callable by the emission admin of the given rewards
   * @param config The assets configuration input, the list of structs contains the following fields:
   *   uint104 emissionPerSecond: The emission per second following rewards unit decimals.
   *   uint256 totalSupply: The total supply of the asset to incentivize
   *   uint40 distributionEnd: The end of the distribution of the incentives for an asset
   *   address asset: The asset address to incentivize
   *   address reward: The reward token address
   *   ITransferStrategy transferStrategy: The TransferStrategy address with the install hook and claim logic.
   *   IEACAggregatorProxy rewardOracle: The Price Oracle of a reward to visualize the incentives at the UI Frontend.
   *                                     Must follow Chainlink Aggregator IEACAggregatorProxy interface to be compatible.
   */
  function configureAssets(RewardsDataTypes.RewardsConfigInput[] memory config) external;

  /**
   * @dev Sets a TransferStrategy logic contract that determines the logic of the rewards transfer
   * @dev Only callable by the emission admin of the given reward
   * @param reward The address of the reward token
   * @param transferStrategy The address of the TransferStrategy logic contract
   */
  function setTransferStrategy(address reward, ITransferStrategyBase transferStrategy) external;

  /**
   * @dev Sets an Aave Oracle contract to enforce rewards with a source of value.
   * @dev Only callable by the emission admin of the given reward
   * @notice At the moment of reward configuration, the Incentives Controller performs
   * a check to see if the reward asset oracle is compatible with IEACAggregator proxy.
   * This check is enforced for integrators to be able to show incentives at
   * the current Aave UI without the need to setup an external price registry
   * @param reward The address of the reward to set the price aggregator
   * @param rewardOracle The address of price aggregator that follows IEACAggregatorProxy interface
   */
  function setRewardOracle(address reward, IEACAggregatorProxy rewardOracle) external;

  /**
   * @dev Sets the end date for the distribution
   * @dev Only callable by the emission admin of the given reward
   * @param asset The asset to incentivize
   * @param reward The reward token that incentives the asset
   * @param newDistributionEnd The end date of the incentivization, in unix time format
   **/
  function setDistributionEnd(
    address asset,
    address reward,
    uint32 newDistributionEnd
  ) external;

  /**
   * @dev Sets the emission per second of a set of reward distributions
   * @param asset The asset is being incentivized
   * @param rewards List of reward addresses are being distributed
   * @param newEmissionsPerSecond List of new reward emissions per second
   */
  function setEmissionPerSecond(
    address asset,
    address[] calldata rewards,
    uint88[] calldata newEmissionsPerSecond
  ) external;

  /**
   * @dev Whitelists an address to claim the rewards on behalf of another address
   * @dev Only callable by the owner of the EmissionManager
   * @param user The address of the user
   * @param claimer The address of the claimer
   */
  function setClaimer(address user, address claimer) external;

  /**
   * @dev Updates the address of the emission manager
   * @dev Only callable by the owner of the EmissionManager
   * @param emissionManager The address of the new EmissionManager
   */
  function setEmissionManager(address emissionManager) external;

  /**
   * @dev Updates the admin of the reward emission
   * @dev Only callable by the owner of the EmissionManager
   * @param reward The address of the reward token
   * @param admin The address of the new admin of the emission
   */
  function setEmissionAdmin(address reward, address admin) external;

  /**
   * @dev Updates the address of the rewards controller
   * @dev Only callable by the owner of the EmissionManager
   * @param controller the address of the RewardsController contract
   */
  function setRewardsController(address controller) external;

  /**
   * @dev Returns the rewards controller address
   * @return The address of the RewardsController contract
   */
  function getRewardsController() external view returns (IRewardsController);

  /**
   * @dev Returns the admin of the given reward emission
   * @param reward The address of the reward token
   * @return The address of the emission admin
   */
  function getEmissionAdmin(address reward) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProposalGenericExecutor {
  function execute() external;
}