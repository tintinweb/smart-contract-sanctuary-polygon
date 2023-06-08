// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

// import {PropertyToken2} from "./propertyToken.sol";
// import {Identity} from "@onchain-id/solidity/contracts/Identity.sol";
// import {ImplementationAuthority} from "@onchain-id/solidity/contracts/proxy/ImplementationAuthority.sol";
// import {IdentityProxy} from "@onchain-id/solidity/contracts/proxy/IdentityProxy.sol";

/**
 * @title ZeroXInterfaces
 * @notice Stores common interface names used throughout 0xequity.
 */
library ZeroXInterfaces {
    bytes32 public constant RENT_SHARE = "RentShare";
    bytes32 public constant PRICE_FEED = "PriceFeed";
    bytes32 public constant PROPERTY_TOKEN = "PropertyToken";
    bytes32 public constant IDENTITY = "Identity";
    bytes32 public constant IMPLEMENTATION_AUTHORITY =
        "ImplementationAuthority";
    bytes32 public constant IDENTITY_PROXY = "IdentityProxy";
    bytes32 public constant MAINTAINER_ROLE = keccak256("Maintainer");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant REWARD_TOKEN = "RewardToken";
    bytes32 public constant SBT = "SBT";
    bytes32 public constant MARKETPLACE = "Marketplace";
    bytes32 public constant TRUSTED_FORWARDER = "TrustedForwarder";
    bytes32 public constant FEEMANAGER = "FeeManager";
    bytes32 public constant XEQ = "XEQ";
    bytes32 public constant OCLROUTER = "OCLRouter";
    bytes32 public constant XJTRY = "XJTRY";
    bytes32 public constant XUSDC = "XUSDC";
    bytes32 public constant SWAPCONTROLLER = "SwapController";
    bytes32 public constant JTRYVAULT = "ERC4626StakingPoolJTRY";
    bytes32 public constant CUSTOMVAULTJTRY = "CustomVaultJTRY";
    bytes32 public constant USDCVAULT = "ERC4626StakingPoolUSDC";
    bytes32 public constant CUSTOMVAULTUSDC = "CustomVaultUSDC";
    bytes32 public constant MANAGER = "Manager";
    bytes32 public constant DFX = "Dfx";
    bytes32 public constant JARVISDEX = "JarvisDex";
    bytes32 public constant TOKENSWHITELIST = "TokensWhitelist";
    bytes32 public constant USDC = "Usdc";
    bytes32 public constant VTRY = "Vtry";
}

// library ZeroXBtyeCodes {
//     bytes public constant PropertyToken = type(PropertyToken2).creationCode;
//     bytes public constant identity = type(Identity).creationCode;
//     bytes public constant implementationAuthority =
//         type(ImplementationAuthority).creationCode;
//     bytes public constant identityProxy = type(IdentityProxy).creationCode;
// }

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

/**
 * @title Provides addresses of the contracts implementing certain interfaces.
 */
interface IFinder {
    /**
     * @notice Updates the address of the contract that implements `interfaceName`.
     * @param interfaceName bytes32 encoding of the interface name that is either changed or registered.
     * @param implementationAddress address of the deployed contract that implements the interface.
     */
    function changeImplementationAddress(
        bytes32 interfaceName,
        address implementationAddress
    ) external;

    /**
     * @notice Gets the address of the contract that implements the given `interfaceName`.
     * @param interfaceName queried interface.
     * @return implementationAddress Address of the deployed contract that implements the interface.
     */
    function getImplementationAddress(
        bytes32 interfaceName
    ) external view returns (address);

    function changeImplementationBytecode(
        bytes32 interfaceName,
        bytes calldata implementationBytecode
    ) external;

    function getImplementationBytecode(
        bytes32 interfaceName
    ) external view returns (bytes memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

interface IManager {
    /**
     * @notice Allow to add roles in contracts
     * @param contracts contracts where to grant the role
     * @param roles Roles id
     * @param accounts Addresses to which give the grant
     */
    function grantRoles(
        address[] calldata contracts,
        bytes32[] calldata roles,
        address[] calldata accounts
    ) external;

    /**
     * @notice Allow to revoke roles in contracts
     * @param contracts where to revoke role from
     * @param roles Roles id
     * @param accounts Addresses to which revoke the grant
     */
    function revokeRoles(
        address[] calldata contracts,
        bytes32[] calldata roles,
        address[] calldata accounts
    ) external;

    /**
     * @notice Allow to renounce roles in contracts
     * @param contracts contracts
     * @param roles Roles id
     */
    function renounceRoles(
        address[] calldata contracts,
        bytes32[] calldata roles
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

/**
 * @title An interface to track a whitelist of addresses.
 */
interface ITokensWhitelist {
    /**
     * @notice Adds an address to the whitelist.
     * @param newToken the new address to add.
     */
    function addToWhitelist(address newToken) external;

    /**
     * @notice Removes an address from the whitelist.
     * @param tokenToRemove The existing address to remove.
     */
    function removeFromWhitelist(address tokenToRemove) external;

    /**
     * @notice Checks whether an address is on the whitelist.
     * @param tokenToCheck The address to check.
     * @return True if `tokenToCheck` is on the whitelist, or False.
     */
    function isOnWhitelist(address tokenToCheck) external view returns (bool);

    /**
     * @notice Gets all addresses that are currently included in the whitelist.
     * @return The list of addresses on the whitelist.
     */
    function getWhitelist() external view returns (address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {IFinder} from "../interfaces/IFinder.sol";
import {IManager} from "../interfaces/IManager.sol";
import {ZeroXInterfaces} from "../Constants.sol";

/**
 * @title Stores functiions for getting from the finder instances of 0xEquity contracts
 */
library FinderLib {
    /**
     * @param _finder Address of finder
     * @return address of Manager.sol
     */
    function getManager(IFinder _finder) internal view returns (IManager) {
        return
            IManager(_finder.getImplementationAddress(ZeroXInterfaces.MANAGER));
    }

    /**
     * @param _finder Address of finder
     * @return address of Rewardtoken (vTRY for now)
     */
    function getPropertyRentToken(
        IFinder _finder
    ) internal view returns (address) {
        return _finder.getImplementationAddress(ZeroXInterfaces.REWARD_TOKEN);
    }

    /**
     * @param _finder Address of finder
     * @return address of RentShare.sol
     */
    function getRentShareAddress(
        IFinder _finder
    ) internal view returns (address) {
        return _finder.getImplementationAddress(ZeroXInterfaces.RENT_SHARE);
    }

    /**
     * @param _finder Address of finder
     * @return address of DFXRouter deployed by DFX
     */
    function getDFXAddress(IFinder _finder) internal view returns (address) {
        return _finder.getImplementationAddress(ZeroXInterfaces.DFX);
    }

    /**
     * @param _finder Address of finder
     * @return address of JarvisDex.sol
     */
    function getJarvisDexAddress(
        IFinder _finder
    ) internal view returns (address) {
        return _finder.getImplementationAddress(ZeroXInterfaces.JARVISDEX);
    }

    /**
     * @param _finder Address of finder
     * @return address of TokensWhitelist.sol
     */
    function getTokensWhitelistAddress(
        IFinder _finder
    ) internal view returns (address) {
        return
            _finder.getImplementationAddress(ZeroXInterfaces.TOKENSWHITELIST);
    }

    /**
     * @param _finder Address of finder
     * @return address of USDC
     */
    function getUSDC(IFinder _finder) internal view returns (address) {
        return _finder.getImplementationAddress(ZeroXInterfaces.USDC);
    }

    /**
     * @param _finder Address of finder
     * @return address of vTRY
     */
    function getVTRY(IFinder _finder) internal view returns (address) {
        return _finder.getImplementationAddress(ZeroXInterfaces.VTRY);
    }

    /**
     * @param _finder Address of finder
     * @return address of OCLRouter.sol
     */
    function getOclrAddress(IFinder _finder) internal view returns (address) {
        return _finder.getImplementationAddress(ZeroXInterfaces.OCLROUTER);
    }

    /**
     * @param _finder Address of finder
     * @return address of Marketplace.sol
     */
    function getMarketplaceAddress(
        IFinder _finder
    ) internal view returns (address) {
        return _finder.getImplementationAddress(ZeroXInterfaces.MARKETPLACE);
    }

    /**
     * @param _finder Address of finder
     * @return address of xUSDC deployed by 0xEquity
     */
    function getXUSDCAddress(IFinder _finder) internal view returns (address) {
        return _finder.getImplementationAddress(ZeroXInterfaces.XUSDC);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

contract IPropertyToken {
    function addMinter(address account) external {}

    function mint(address _to, uint256 _amount) external {}

    function unlock(uint256 _amount) external {}
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRentShare {
    //----------------------------------------
    // Events
    //----------------------------------------

    event Deposit(address indexed user, uint256 indexed poolId, uint256 amount);
    event Withdraw(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount
    );
    event HarvestRewards(
        uint256 indexed poolId,
        address indexed user,
        uint256 amount
    );
    event PoolCreated(uint256 indexed poolId);
    event RewardsPaused(uint256 indexed poolId);
    event RewardsUnpaused(uint256 indexed poolId);
    event PoolRewardUpdated(uint256 indexed poolId, uint256 indexed amount);
    event VaultRewardsHarvested(
        uint indexed poolId,
        address indexed sender,
        uint amount
    );
    //----------------------------------------
    // Structs
    //----------------------------------------

    // Staking user for a pool
    struct PoolStaker {
        uint256 amount; // The tokens quantity the user has staked.
        uint256 rewards; // The reward tokens quantity the user can harvest
        uint256 rewardDebt; // The amount relative to accumulatedRewardsPerShare the user can't get as reward
    }

    // Staking pool
    struct Pool {
        IERC20 stakeToken; // Token to be staked
        uint256 tokensStaked; // Total tokens staked
        uint256 lastRewardedTimestamp; // Last block number the user had their rewards calculated
        uint256 accumulatedRewardsPerShare; // Accumulated rewards per share times REWARDS_PRECISION
        uint256 rewardTokensPerSecond; // Number of reward tokens minted per block for this pool
    }

    struct Storage {
        Pool[] pools; // Staking pools
        address rewardToken; // Token to be payed as reward
        address finder; //finder address
        uint256 REWARDS_PRECISION; // A big number to perform mul and div operations
        // Mapping poolId => staker address => PoolStaker
        mapping(uint256 => mapping(address => PoolStaker)) poolStakers;
        mapping(string => uint256) symbolToPoolId;
        mapping(string => bool) symbolExisit;
        mapping(uint256 => bool) rewardsPaused;
        mapping(address => mapping(string => uint)) userToPropertyRentClaimTimestamp;
        mapping(uint => string) poolIdToSymbol;
        uint harvestDelay; // delay in seconds to harvest rewards
        uint maxHarvestDelay; // max delay to harvest rewards possible
        mapping(address => uint) pendingHarvestRewardsTimestamps; // keep track of user to harvestRewards timestamp
    }

    //----------------------------------------
    // Function Sig
    //----------------------------------------

    function createPool(
        IERC20 _stakeToken,
        address maintainer,
        string memory symbol,
        uint256 _poolId
    ) external returns (uint256 poolId);

    function deposit(
        uint256 _poolId,
        address _sender,
        uint256 _amount
    ) external;

    function withdraw(
        uint256 _poolId,
        address _sender,
        uint256 _amount
    ) external;

    function harvestRewards(
        string memory symbol
    ) external returns (uint rewardsHarvested);

    function harvestRewardsForVault(
        string memory symbol
    ) external returns (uint rewardsHarvested);

    function isPropertyTokenWhitelisted(
        string memory propertySymbol
    ) external view returns (uint);

    function getPoolIdToSymbol(
        uint poolId
    ) external view returns (string memory);

    function requestHarvestReward() external;

    function getRewardToken() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import {IFinder} from "../core/interfaces/IFinder.sol";
import {FinderLib} from "./../core/libs/CoreLibs.sol";
import {ZeroXInterfaces} from "../core/Constants.sol";
import {IRentShare} from "../Interfaces/IRentShare.sol";
import {IPropertyToken} from "../Interfaces/IPropertyToken.sol";

import "./../core/interfaces/ITokensWhitelist.sol";

// This contract uses the library to set and retrieve state variables
library RentShareLib {
    using FinderLib for IFinder;

    event HarvestRewards(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount
    );

    function isTrustedForwarder(
        IRentShare.Storage storage _storageParams,
        address _forwarder
    ) external view returns (bool) {
        try
            IFinder(_storageParams.finder).getImplementationAddress(
                ZeroXInterfaces.TRUSTED_FORWARDER
            )
        returns (address trustedForwarder) {
            if (_forwarder == trustedForwarder) {
                return true;
            } else {
                return false;
            }
        } catch {
            return false;
        }
    }

    function updatePoolRewards(
        IRentShare.Storage storage _storageParams,
        uint256 _poolId
    ) external {
        //fetching the pool
        IRentShare.Pool storage pool = _storageParams.pools[_poolId];
        //if the total tokenStaked is zero so far then update the lastRewardedTimestamp as the current block.timeStamp
        if (pool.tokensStaked == 0) {
            pool.lastRewardedTimestamp = block.timestamp;
            return;
        }
        //calculating the blockSinceLastReward i.e current block.timestamp - LastTimestampRewarded
        uint256 TimeStampSinceLastReward = block.timestamp -
            pool.lastRewardedTimestamp;
        //calculating the rewards since last block rewarded.
        uint256 rewards = (TimeStampSinceLastReward *
            pool.rewardTokensPerSecond) / 1e12;
        //accumulatedRewardPerShare += rewards * REWARDS_PRECISION / tokenStaked
        pool.accumulatedRewardsPerShare =
            pool.accumulatedRewardsPerShare +
            ((rewards * _storageParams.REWARDS_PRECISION) / pool.tokensStaked);
        //updated the last reward block to current block
        pool.lastRewardedTimestamp = block.timestamp;
    }

    function _getAccumulatedRewards(
        IRentShare.Storage storage _storageParams,
        string memory tokenSymbol,
        address _staker
    ) external view returns (uint256 rewardsToHarvest) {
        uint256 poolId = _isPropertyTokenWhitelisted(
            _storageParams,
            tokenSymbol
        );
        //fetching the pool
        //fetching the pool
        IRentShare.Pool memory pool = _storageParams.pools[poolId];
        //if the total tokenStaked is zero so far then update the lastRewardedTimestamp as the current block.timeStamp
        if (pool.tokensStaked == 0) {
            pool.lastRewardedTimestamp = block.timestamp;
            return 0;
        }
        //calculating the blockSinceLastReward i.e current block.timestamp - LastTimestampRewarded
        uint256 TimeStampSinceLastReward = block.timestamp -
            pool.lastRewardedTimestamp;
        //calculating the rewards since last block rewarded.
        uint256 rewards = (TimeStampSinceLastReward *
            pool.rewardTokensPerSecond) / 1e12;
        //accumulatedRewardPerShare += rewards * REWARDS_PRECISION / tokenStaked
        pool.accumulatedRewardsPerShare =
            pool.accumulatedRewardsPerShare +
            ((rewards * _storageParams.REWARDS_PRECISION) / pool.tokensStaked);
        //updated the last reward block to current block
        pool.lastRewardedTimestamp = block.timestamp;

        //-------------------------------------------------------------------------

        IRentShare.PoolStaker memory staker = _storageParams.poolStakers[
            poolId
        ][_staker];

        rewardsToHarvest =
            ((staker.amount * pool.accumulatedRewardsPerShare) /
                _storageParams.REWARDS_PRECISION) -
            staker.rewardDebt;
    }

    function harvestRewards(
        IRentShare.Storage storage _storageParams,
        uint256 _poolId,
        address sender
    ) external returns (uint) {
        if (!_storageParams.rewardsPaused[_poolId]) {
            IRentShare.Pool storage pool = _storageParams.pools[_poolId];
            IRentShare.PoolStaker storage staker = _storageParams.poolStakers[
                _poolId
            ][sender];
            uint rewardsToHarvest = ((staker.amount *
                pool.accumulatedRewardsPerShare) /
                _storageParams.REWARDS_PRECISION) - staker.rewardDebt;
            if (rewardsToHarvest == 0) {
                staker.rewardDebt =
                    (staker.amount * pool.accumulatedRewardsPerShare) /
                    _storageParams.REWARDS_PRECISION;
                return 0;
            }
            staker.rewards = 0;
            staker.rewardDebt =
                (staker.amount * pool.accumulatedRewardsPerShare) /
                _storageParams.REWARDS_PRECISION;
            emit HarvestRewards(sender, _poolId, rewardsToHarvest);
            IPropertyToken(_storageParams.rewardToken).mint(
                sender,
                rewardsToHarvest
            );
            return rewardsToHarvest;
        } else return 0;
    }

    function _isPropertyTokenWhitelisted(
        IRentShare.Storage storage _storageParams,
        string memory tokenSymbol
    ) internal view returns (uint) {
        uint poolId = _storageParams.symbolToPoolId[tokenSymbol];
        address stakeToken = address(_storageParams.pools[poolId].stakeToken);
        address tokenWhitelistAddress = IFinder(_storageParams.finder)
            .getTokensWhitelistAddress();
        require(
            keccak256(abi.encode(_storageParams.poolIdToSymbol[poolId])) ==
                keccak256(abi.encode(tokenSymbol)),
            "Invalid symbol"
        );
        require(
            ITokensWhitelist(tokenWhitelistAddress).isOnWhitelist(stakeToken),
            "Invalid property"
        );
        return poolId;
    }
}