// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IKyberVault, IBasePositionManager} from "@mellow-vaults/contracts/interfaces/vaults/IKyberVault.sol";

import "./IBaseFeesCollector.sol";

contract KyberSwapFeesCollector is IBaseFeesCollector {
    function collectFeesData(
        address vault
    ) external view override returns (address[] memory tokens, uint256[] memory amounts) {
        tokens = IKyberVault(vault).vaultTokens();
        (amounts, ) = IKyberVault(vault).tvl();

        uint256 kyberNft = IKyberVault(vault).kyberNft();
        (IBasePositionManager.Position memory position, ) = IKyberVault(vault).positionManager().positions(kyberNft);

        uint256[] memory baseAmounts = IKyberVault(vault).kyberHelper().liquidityToTokenAmounts(
            position.liquidity,
            IKyberVault(vault).pool(),
            kyberNft
        );

        amounts[0] -= baseAmounts[0];
        amounts[1] -= baseAmounts[1];
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./IIntegrationVault.sol";
import "../external/kyber/periphery/IBasePositionManager.sol";
import "../external/kyber/IPool.sol";

import "../oracles/IOracle.sol";
import "../utils/IKyberHelper.sol";
import "../external/kyber/IKyberSwapElasticLM.sol";

interface IKyberVault is IERC721Receiver, IIntegrationVault {
    struct Options {
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Reference to IBasePositionManager of KyberSwap protocol.
    function positionManager() external view returns (IBasePositionManager);

    /// @notice Reference to KyberSwap pool.
    function pool() external view returns (IPool);

    /// @notice NFT of KyberSwap position manager
    function kyberNft() external view returns (uint256);
    
    /// @notice Initialized a new contract.
    /// @dev Can only be initialized by vault governance
    /// @param nft_ NFT of the vault in the VaultRegistry
    /// @param vaultTokens_ ERC20 tokens that will be managed by this Vault
    /// @param fee_ Fee of the Kyber pool
    function initialize(
        uint256 nft_,
        address[] memory vaultTokens_,
        uint24 fee_
    ) external;

    function updateFarmInfo() external;

    function farm() external view returns (IKyberSwapElasticLM);

    function mellowOracle() external view returns (IOracle);

    function pid() external view returns (uint256);

    function isLiquidityInFarm() external view returns (bool);

    function kyberHelper() external view returns (IKyberHelper);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBaseFeesCollector {
    function collectFeesData(address vault) external view returns (address[] memory tokens, uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../external/erc/IERC1271.sol";
import "./IVault.sol";

interface IIntegrationVault is IVault, IERC1271 {
    /// @notice Pushes tokens on the vault balance to the underlying protocol. For example, for Yearn this operation will take USDC from
    /// the contract balance and convert it to yUSDC.
    /// @dev Tokens **must** be a subset of Vault Tokens. However, the convention is that if tokenAmount == 0 it is the same as token is missing.
    ///
    /// Also notice that this operation doesn't guarantee that tokenAmounts will be invested in full.
    /// @param tokens Tokens to push
    /// @param tokenAmounts Amounts of tokens to push
    /// @param options Additional options that could be needed for some vaults. E.g. for Uniswap this could be `deadline` param. For the exact bytes structure see concrete vault descriptions
    /// @return actualTokenAmounts The amounts actually invested. It could be less than tokenAmounts (but not higher)
    function push(
        address[] memory tokens,
        uint256[] memory tokenAmounts,
        bytes memory options
    ) external returns (uint256[] memory actualTokenAmounts);

    /// @notice The same as `push` method above but transfers tokens to vault balance prior to calling push.
    /// After the `push` it returns all the leftover tokens back (`push` method doesn't guarantee that tokenAmounts will be invested in full).
    /// @param tokens Tokens to push
    /// @param tokenAmounts Amounts of tokens to push
    /// @param options Additional options that could be needed for some vaults. E.g. for Uniswap this could be `deadline` param. For the exact bytes structure see concrete vault descriptions
    /// @return actualTokenAmounts The amounts actually invested. It could be less than tokenAmounts (but not higher)
    function transferAndPush(
        address from,
        address[] memory tokens,
        uint256[] memory tokenAmounts,
        bytes memory options
    ) external returns (uint256[] memory actualTokenAmounts);

    /// @notice Pulls tokens from the underlying protocol to the `to` address.
    /// @dev Can only be called but Vault Owner or Strategy. Vault owner is the owner of NFT for this vault in VaultManager.
    /// Strategy is approved address for the vault NFT.
    /// When called by vault owner this method just pulls the tokens from the protocol to the `to` address
    /// When called by strategy on vault other than zero vault it pulls the tokens to zero vault (required `to` == zero vault)
    /// When called by strategy on zero vault it pulls the tokens to zero vault, pushes tokens on the `to` vault, and reclaims everything that's left.
    /// Thus any vault other than zero vault cannot have any tokens on it
    ///
    /// Tokens **must** be a subset of Vault Tokens. However, the convention is that if tokenAmount == 0 it is the same as token is missing.
    ///
    /// Pull is fulfilled on the best effort basis, i.e. if the tokenAmounts overflows available funds it withdraws all the funds.
    /// @param to Address to receive the tokens
    /// @param tokens Tokens to pull
    /// @param tokenAmounts Amounts of tokens to pull
    /// @param options Additional options that could be needed for some vaults. E.g. for Uniswap this could be `deadline` param. For the exact bytes structure see concrete vault descriptions
    /// @return actualTokenAmounts The amounts actually withdrawn. It could be less than tokenAmounts (but not higher)
    function pull(
        address to,
        address[] memory tokens,
        uint256[] memory tokenAmounts,
        bytes memory options
    ) external returns (uint256[] memory actualTokenAmounts);

    /// @notice Claim ERC20 tokens from vault balance to zero vault.
    /// @dev Cannot be called from zero vault.
    /// @param tokens Tokens to claim
    /// @return actualTokenAmounts Amounts reclaimed
    function reclaimTokens(address[] memory tokens) external returns (uint256[] memory actualTokenAmounts);

    /// @notice Execute one of whitelisted calls.
    /// @dev Can only be called by Vault Owner or Strategy. Vault owner is the owner of NFT for this vault in VaultManager.
    /// Strategy is approved address for the vault NFT.
    ///
    /// Since this method allows sending arbitrary transactions, the destinations of the calls
    /// are whitelisted by Protocol Governance.
    /// @param to Address of the reward pool
    /// @param selector Selector of the call
    /// @param data Abi encoded parameters to `to::selector`
    /// @return result Result of execution of the call
    function externalCall(
        address to,
        bytes4 selector,
        bytes memory data
    ) external payable returns (bytes memory result);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IRouterTokenHelper} from "./IRouterTokenHelper.sol";
import {IBasePositionManagerEvents} from "./base_position_manager/IBasePositionManagerEvents.sol";
import {IERC721Permit} from "./IERC721Permit.sol";

interface IBasePositionManager is IRouterTokenHelper, IBasePositionManagerEvents, IERC721Permit {
    struct Position {
        // the nonce for permits
        uint96 nonce;
        // the address that is approved for spending this token
        address operator;
        // the ID of the pool with which this token is connected
        uint80 poolId;
        // the tick range of the position
        int24 tickLower;
        int24 tickUpper;
        // the liquidity of the position
        uint128 liquidity;
        // the current rToken that the position owed
        uint256 rTokenOwed;
        // fee growth per unit of liquidity as of the last update to liquidity
        uint256 feeGrowthInsideLast;
    }

    struct PoolInfo {
        address token0;
        uint24 fee;
        address token1;
    }

    /// @notice Params for the first time adding liquidity, mint new nft to sender
    /// @param token0 the token0 of the pool
    /// @param token1 the token1 of the pool
    ///   - must make sure that token0 < token1
    /// @param fee the pool's fee in bps
    /// @param tickLower the position's lower tick
    /// @param tickUpper the position's upper tick
    ///   - must make sure tickLower < tickUpper, and both are in tick distance
    /// @param ticksPrevious the nearest tick that has been initialized and lower than or equal to
    ///   the tickLower and tickUpper, use to help insert the tickLower and tickUpper if haven't initialized
    /// @param amount0Desired the desired amount for token0
    /// @param amount1Desired the desired amount for token1
    /// @param amount0Min min amount of token 0 to add
    /// @param amount1Min min amount of token 1 to add
    /// @param recipient the owner of the position
    /// @param deadline time that the transaction will be expired
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        int24[2] ticksPrevious;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Params for adding liquidity to the existing position
    /// @param tokenId id of the position to increase its liquidity
    /// @param amount0Desired the desired amount for token0
    /// @param amount1Desired the desired amount for token1
    /// @param amount0Min min amount of token 0 to add
    /// @param amount1Min min amount of token 1 to add
    /// @param deadline time that the transaction will be expired
    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Params for remove liquidity from the existing position
    /// @param tokenId id of the position to remove its liquidity
    /// @param amount0Min min amount of token 0 to receive
    /// @param amount1Min min amount of token 1 to receive
    /// @param deadline time that the transaction will be expired
    struct RemoveLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Burn the rTokens to get back token0 + token1 as fees
    /// @param tokenId id of the position to burn r token
    /// @param amount0Min min amount of token 0 to receive
    /// @param amount1Min min amount of token 1 to receive
    /// @param deadline time that the transaction will be expired
    struct BurnRTokenParams {
        uint256 tokenId;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Creates a new pool if it does not exist, then unlocks if it has not been unlocked
    /// @param token0 the token0 of the pool
    /// @param token1 the token1 of the pool
    /// @param fee the fee for the pool
    /// @param currentSqrtP the initial price of the pool
    /// @return pool returns the pool address
    function createAndUnlockPoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 currentSqrtP
    ) external payable returns (address pool);

    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    function addLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1,
            uint256 additionalRTokenOwed
        );

    function removeLiquidity(RemoveLiquidityParams calldata params)
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 additionalRTokenOwed
        );

    function burnRTokens(BurnRTokenParams calldata params)
        external
        returns (
            uint256 rTokenQty,
            uint256 amount0,
            uint256 amount1
        );

    /**
     * @dev Burn the token by its owner
     * @notice All liquidity should be removed before burning
     */
    function burn(uint256 tokenId) external payable;

    function positions(uint256 tokenId) external view returns (Position memory pos, PoolInfo memory info);

    function addressToPoolId(address pool) external view returns (uint80);

    function isRToken(address token) external view returns (bool);

    function factory() external view returns (address);

    function nextPoolId() external view returns (uint80);

    function nextTokenId() external view returns (uint256);

    function multicall(bytes[] calldata) external payable returns (bytes[] memory);

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
pragma solidity ^0.8.0;

import {IPoolActions} from "./pool/IPoolActions.sol";
import {IPoolEvents} from "./pool/IPoolEvents.sol";
import {IPoolStorage} from "./pool/IPoolStorage.sol";

interface IPool is IPoolActions, IPoolEvents, IPoolStorage {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    /// @notice Oracle price for tokens as a Q64.96 value.
    /// @notice Returns pricing information based on the indexes of non-zero bits in safetyIndicesSet.
    /// @notice It is possible that not all indices will have their respective prices returned.
    /// @dev The price is token1 / token0 i.e. how many weis of token1 required for 1 wei of token0.
    /// The safety indexes are:
    ///
    /// 1 - unsafe, this is typically a spot price that can be easily manipulated,
    ///
    /// 2 - 4 - more or less safe, this is typically a uniV3 oracle, where the safety is defined by the timespan of the average price
    ///
    /// 5 - safe - this is typically a chailink oracle
    /// @param token0 Reference to token0
    /// @param token1 Reference to token1
    /// @param safetyIndicesSet Bitmask of safety indices that are allowed for the return prices. For set of safety indexes = { 1 }, safetyIndicesSet = 0x2
    /// @return pricesX96 Prices that satisfy safetyIndex and tokens
    /// @return safetyIndices Safety indices for those prices
    function priceX96(
        address token0,
        address token1,
        uint256 safetyIndicesSet
    ) external view returns (uint256[] memory pricesX96, uint256[] memory safetyIndices);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../external/kyber/IPool.sol";
import "../external/kyber/IFactory.sol";
import "../external/kyber/periphery/IBasePositionManager.sol";

import "../vaults/IKyberVault.sol";

interface IKyberHelper {
    function liquidityToTokenAmounts(
        uint128 liquidity,
        IPool pool,
        uint256 kyberNft
    ) external view returns (uint256[] memory tokenAmounts);

    function tokenAmountsToLiquidity(
        uint256[] memory tokenAmounts,
        IPool pool,
        uint256 kyberNft
    ) external view returns (uint128 liquidity);

    function tokenAmountsToMaximalLiquidity(
        uint160 sqrtRatioX96,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1
    ) external pure returns (uint128 liquidity);

    function calculateTvlBySqrtPriceX96(
        IPool pool,
        uint256 kyberNft,
        uint160 sqrtPriceX96
    ) external view returns (uint256[] memory tokenAmounts);

    function calcTvl() external view returns (uint256[] memory minTokenAmounts, uint256[] memory maxTokenAmounts);

    function getBytesToMulticall(uint256[] memory tokenAmounts, IKyberVault.Options memory opts) external view returns (bytes[] memory);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IKyberSwapElasticLMEvents} from './IKyberSwapElasticLMEvents.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IKyberSwapElasticLM is IKyberSwapElasticLMEvents {
  struct RewardData {
    address rewardToken;
    uint256 rewardUnclaimed;
  }

  struct LMPoolInfo {
    address poolAddress;
    uint32 startTime;
    uint32 endTime;
    uint32 vestingDuration;
    uint256 totalSecondsClaimed; // scaled by (1 << 96)
    RewardData[] rewards;
    uint256 feeTarget;
    uint256 numStakes;
  }

  struct PositionInfo {
    address owner;
    uint256 liquidity;
  }

  struct StakeInfo {
    uint128 secondsPerLiquidityLast;
    uint256[] rewardLast;
    uint256[] rewardPending;
    uint256[] rewardHarvested;
    int256 feeFirst;
    uint256 liquidity;
  }

  // input data in harvestMultiplePools function
  struct HarvestData {
    uint256[] pIds;
  }

  // avoid stack too deep error
  struct RewardCalculationData {
    uint128 secondsPerLiquidityNow;
    int256 feeNow;
    uint256 vestingVolume;
    uint256 totalSecondsUnclaimed;
    uint256 secondsPerLiquidity;
    uint256 secondsClaim; // scaled by (1 << 96)
  }

  /**
   * @dev Add new pool to LM
   * @param poolAddr pool address
   * @param startTime start time of liquidity mining
   * @param endTime end time of liquidity mining
   * @param vestingDuration time locking in reward locker
   * @param rewardTokens reward token list for pool
   * @param rewardAmounts reward amount of list token
   * @param feeTarget fee target for pool
   *
   */
  function addPool(
    address poolAddr,
    uint32 startTime,
    uint32 endTime,
    uint32 vestingDuration,
    address[] calldata rewardTokens,
    uint256[] calldata rewardAmounts,
    uint256 feeTarget
  ) external;

  /**
   * @dev Renew a pool to start another LM program
   * @param pId pool id to update
   * @param startTime start time of liquidity mining
   * @param endTime end time of liquidity mining
   * @param vestingDuration time locking in reward locker
   * @param rewardAmounts reward amount of list token
   * @param feeTarget fee target for pool
   *
   */
  function renewPool(
    uint256 pId,
    uint32 startTime,
    uint32 endTime,
    uint32 vestingDuration,
    uint256[] calldata rewardAmounts,
    uint256 feeTarget
  ) external;

  /**
   * @dev Deposit NFT
   * @param nftIds list nft id
   *
   */
  function deposit(uint256[] calldata nftIds) external;

  /**
   * @dev Withdraw NFT, must exit all pool before call.
   * @param nftIds list nft id
   *
   */
  function withdraw(uint256[] calldata nftIds) external;

  /**
   * @dev Join pools
   * @param pId pool id to join
   * @param nftIds nfts to join
   * @param liqs list liquidity value to join each nft
   *
   */
  function join(
    uint256 pId,
    uint256[] calldata nftIds,
    uint256[] calldata liqs
  ) external;

  /**
   * @dev Exit from pools
   * @param pId pool ids to exit
   * @param nftIds list nfts id
   * @param liqs list liquidity value to exit from each nft
   *
   */
  function exit(
    uint256 pId,
    uint256[] calldata nftIds,
    uint256[] calldata liqs
  ) external;

  /**
   * @dev Operator only. Call to withdraw all reward from list pools.
   * @param rewards list reward address erc20 token
   * @param amounts amount to withdraw
   *
   */
  function emergencyWithdrawForOwner(address[] calldata rewards, uint256[] calldata amounts)
    external;

  /**
   * @dev Withdraw NFT, can call any time, reward will be reset. Must enable this func by operator
   * @param pIds list pool to withdraw
   *
   */
  function emergencyWithdraw(uint256[] calldata pIds) external;

  function nft() external view returns (IERC721);

  function poolLength() external view returns (uint256);

  function getUserInfo(uint256 nftId, uint256 pId)
    external
    view
    returns (
      uint256 liquidity,
      uint256[] memory rewardPending,
      uint256[] memory rewardLast
    );

  function getPoolInfo(uint256 pId)
    external
    view
    returns (
      address poolAddress,
      uint32 startTime,
      uint32 endTime,
      uint32 vestingDuration,
      uint256 totalSecondsClaimed,
      uint256 feeTarget,
      uint256 numStakes,
      //index reward => reward data
      address[] memory rewardTokens,
      uint256[] memory rewardUnclaimeds
    );

  function getDepositedNFTs(address user) external view returns (uint256[] memory listNFTs);

  function getRewardCalculationData(uint256 nftId, uint256 pId)
    external
    view
    returns (RewardCalculationData memory data);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC1271 {
    /// @notice Verifies offchain signature.
    /// @dev Should return whether the signature provided is valid for the provided hash
    ///
    /// MUST return the bytes4 magic value 0x1626ba7e when function passes.
    ///
    /// MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
    ///
    /// MUST allow external calls
    /// @param _hash Hash of the data to be signed
    /// @param _signature Signature byte array associated with _hash
    /// @return magicValue 0x1626ba7e if valid, 0xffffffff otherwise
    function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IVaultGovernance.sol";

interface IVault is IERC165 {
    /// @notice Checks if the vault is initialized

    function initialized() external view returns (bool);

    /// @notice VaultRegistry NFT for this vault
    function nft() external view returns (uint256);

    /// @notice Address of the Vault Governance for this contract.
    function vaultGovernance() external view returns (IVaultGovernance);

    /// @notice ERC20 tokens under Vault management.
    function vaultTokens() external view returns (address[] memory);

    /// @notice Checks if a token is vault token
    /// @param token Address of the token to check
    /// @return `true` if this token is managed by Vault
    function isVaultToken(address token) external view returns (bool);

    /// @notice Total value locked for this contract.
    /// @dev Generally it is the underlying token value of this contract in some
    /// other DeFi protocol. For example, for USDC Yearn Vault this would be total USDC balance that could be withdrawn for Yearn to this contract.
    /// The tvl itself is estimated in some range. Sometimes the range is exact, sometimes it's not
    /// @return minTokenAmounts Lower bound for total available balances estimation (nth tokenAmount corresponds to nth token in vaultTokens)
    /// @return maxTokenAmounts Upper bound for total available balances estimation (nth tokenAmount corresponds to nth token in vaultTokens)
    function tvl() external view returns (uint256[] memory minTokenAmounts, uint256[] memory maxTokenAmounts);

    /// @notice Existential amounts for each token
    function pullExistentials() external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IRouterTokenHelper {
    /// @notice Unwraps the contract's WETH balance and sends it to recipient as ETH.
    /// @dev The minAmount parameter prevents malicious contracts from stealing WETH from users.
    /// @param minAmount The minimum amount of WETH to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWeth(uint256 minAmount, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundEth() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The minAmount parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param minAmount The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function transferAllTokens(
        address token,
        uint256 minAmount,
        address recipient
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBasePositionManagerEvents {
    /// @notice Emitted when a token is minted for a given position
    /// @param tokenId the newly minted tokenId
    /// @param poolId poolId of the token
    /// @param liquidity liquidity minted to the position range
    /// @param amount0 token0 quantity needed to mint the liquidity
    /// @param amount1 token1 quantity needed to mint the liquidity
    event MintPosition(
        uint256 indexed tokenId,
        uint80 indexed poolId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when a token is burned
    /// @param tokenId id of the token
    event BurnPosition(uint256 indexed tokenId);

    /// @notice Emitted when add liquidity
    /// @param tokenId id of the token
    /// @param liquidity the increase amount of liquidity
    /// @param amount0 token0 quantity needed to increase liquidity
    /// @param amount1 token1 quantity needed to increase liquidity
    /// @param additionalRTokenOwed additional rToken earned
    event AddLiquidity(
        uint256 indexed tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1,
        uint256 additionalRTokenOwed
    );

    /// @notice Emitted when remove liquidity
    /// @param tokenId id of the token
    /// @param liquidity the decease amount of liquidity
    /// @param amount0 token0 quantity returned when remove liquidity
    /// @param amount1 token1 quantity returned when remove liquidity
    /// @param additionalRTokenOwed additional rToken earned
    event RemoveLiquidity(
        uint256 indexed tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1,
        uint256 additionalRTokenOwed
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/// @title ERC721 with permit
/// @notice Extension to ERC721 that includes a permit function for signature based approvals
interface IERC721Permit is IERC721, IERC721Enumerable {
    /// @notice The permit typehash used in the permit signature
    /// @return The typehash for the permit
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    /// @notice The domain separator used in the permit signature
    /// @return The domain seperator used in encoding of permit signature
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Approve of a specific token ID for spending by spender via signature
    /// @param spender The account that is being approved
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

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
pragma solidity ^0.8.0;

interface IPoolActions {
    /// @notice Sets the initial price for the pool and seeds reinvestment liquidity
    /// @dev Assumes the caller has sent the necessary token amounts
    /// required for initializing reinvestment liquidity prior to calling this function
    /// @param initialSqrtP the initial sqrt price of the pool
    /// @param qty0 token0 quantity sent to and locked permanently in the pool
    /// @param qty1 token1 quantity sent to and locked permanently in the pool
    function unlockPool(uint160 initialSqrtP) external returns (uint256 qty0, uint256 qty1);

    /// @notice Adds liquidity for the specified recipient/tickLower/tickUpper position
    /// @dev Any token0 or token1 owed for the liquidity provision have to be paid for when
    /// the IMintCallback#mintCallback is called to this method's caller
    /// The quantity of token0/token1 to be sent depends on
    /// tickLower, tickUpper, the amount of liquidity, and the current price of the pool.
    /// Also sends reinvestment tokens (fees) to the recipient for any fees collected
    /// while the position is in range
    /// Reinvestment tokens have to be burnt via #burnRTokens in exchange for token0 and token1
    /// @param recipient Address for which the added liquidity is credited to
    /// @param tickLower Recipient position's lower tick
    /// @param tickUpper Recipient position's upper tick
    /// @param ticksPrevious The nearest tick that is initialized and <= the lower & upper ticks
    /// @param qty Liquidity quantity to mint
    /// @param data Data (if any) to be passed through to the callback
    /// @return qty0 token0 quantity sent to the pool in exchange for the minted liquidity
    /// @return qty1 token1 quantity sent to the pool in exchange for the minted liquidity
    /// @return feeGrowthInside position's updated feeGrowthInside value
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        int24[2] calldata ticksPrevious,
        uint128 qty,
        bytes calldata data
    )
        external
        returns (
            uint256 qty0,
            uint256 qty1,
            uint256 feeGrowthInside
        );

    /// @notice Remove liquidity from the caller
    /// Also sends reinvestment tokens (fees) to the caller for any fees collected
    /// while the position is in range
    /// Reinvestment tokens have to be burnt via #burnRTokens in exchange for token0 and token1
    /// @param tickLower Position's lower tick for which to burn liquidity
    /// @param tickUpper Position's upper tick for which to burn liquidity
    /// @param qty Liquidity quantity to burn
    /// @return qty0 token0 quantity sent to the caller
    /// @return qty1 token1 quantity sent to the caller
    /// @return feeGrowthInside position's updated feeGrowthInside value
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 qty
    )
        external
        returns (
            uint256 qty0,
            uint256 qty1,
            uint256 feeGrowthInside
        );

    /// @notice Burns reinvestment tokens in exchange to receive the fees collected in token0 and token1
    /// @param qty Reinvestment token quantity to burn
    /// @param isLogicalBurn true if burning rTokens without returning any token0/token1
    ///         otherwise should transfer token0/token1 to sender
    /// @return qty0 token0 quantity sent to the caller for burnt reinvestment tokens
    /// @return qty1 token1 quantity sent to the caller for burnt reinvestment tokens
    function burnRTokens(uint256 qty, bool isLogicalBurn) external returns (uint256 qty0, uint256 qty1);

    /// @notice Swap token0 -> token1, or vice versa
    /// @dev This method's caller receives a callback in the form of ISwapCallback#swapCallback
    /// @dev swaps will execute up to limitSqrtP or swapQty is fully used
    /// @param recipient The address to receive the swap output
    /// @param swapQty The swap quantity, which implicitly configures the swap as exact input (>0), or exact output (<0)
    /// @param isToken0 Whether the swapQty is specified in token0 (true) or token1 (false)
    /// @param limitSqrtP the limit of sqrt price after swapping
    /// could be MAX_SQRT_RATIO-1 when swapping 1 -> 0 and MIN_SQRT_RATIO+1 when swapping 0 -> 1 for no limit swap
    /// @param data Any data to be passed through to the callback
    /// @return qty0 Exact token0 qty sent to recipient if < 0. Minimally received quantity if > 0.
    /// @return qty1 Exact token1 qty sent to recipient if < 0. Minimally received quantity if > 0.
    function swap(
        address recipient,
        int256 swapQty,
        bool isToken0,
        uint160 limitSqrtP,
        bytes calldata data
    ) external returns (int256 qty0, int256 qty1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IFlashCallback#flashCallback
    /// @dev Fees collected are sent to the feeTo address if it is set in Factory
    /// @param recipient The address which will receive the token0 and token1 quantities
    /// @param qty0 token0 quantity to be loaned to the recipient
    /// @param qty1 token1 quantity to be loaned to the recipient
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 qty0,
        uint256 qty1,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPoolEvents {
    /// @notice Emitted only once per pool when #initialize is first called
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtP The initial price of the pool
    /// @param tick The initial tick of the pool
    event Initialize(uint160 sqrtP, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @dev transfers reinvestment tokens for any collected fees earned by the position
    /// @param sender address that minted the liquidity
    /// @param owner address of owner of the position
    /// @param tickLower position's lower tick
    /// @param tickUpper position's upper tick
    /// @param qty liquidity minted to the position range
    /// @param qty0 token0 quantity needed to mint the liquidity
    /// @param qty1 token1 quantity needed to mint the liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 qty,
        uint256 qty0,
        uint256 qty1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev transfers reinvestment tokens for any collected fees earned by the position
    /// @param owner address of owner of the position
    /// @param tickLower position's lower tick
    /// @param tickUpper position's upper tick
    /// @param qty liquidity removed
    /// @param qty0 token0 quantity withdrawn from removal of liquidity
    /// @param qty1 token1 quantity withdrawn from removal of liquidity
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 qty,
        uint256 qty0,
        uint256 qty1
    );

    /// @notice Emitted when reinvestment tokens are burnt
    /// @param owner address which burnt the reinvestment tokens
    /// @param qty reinvestment token quantity burnt
    /// @param qty0 token0 quantity sent to owner for burning reinvestment tokens
    /// @param qty1 token1 quantity sent to owner for burning reinvestment tokens
    event BurnRTokens(address indexed owner, uint256 qty, uint256 qty0, uint256 qty1);

    /// @notice Emitted for swaps by the pool between token0 and token1
    /// @param sender Address that initiated the swap call, and that received the callback
    /// @param recipient Address that received the swap output
    /// @param deltaQty0 Change in pool's token0 balance
    /// @param deltaQty1 Change in pool's token1 balance
    /// @param sqrtP Pool's sqrt price after the swap
    /// @param liquidity Pool's liquidity after the swap
    /// @param currentTick Log base 1.0001 of pool's price after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 deltaQty0,
        int256 deltaQty1,
        uint160 sqrtP,
        uint128 liquidity,
        int24 currentTick
    );

    /// @notice Emitted by the pool for any flash loans of token0/token1
    /// @param sender The address that initiated the flash loan, and that received the callback
    /// @param recipient The address that received the flash loan quantities
    /// @param qty0 token0 quantity loaned to the recipient
    /// @param qty1 token1 quantity loaned to the recipient
    /// @param paid0 token0 quantity paid for the flash, which can exceed qty0 + fee
    /// @param paid1 token1 quantity paid for the flash, which can exceed qty0 + fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 qty0,
        uint256 qty1,
        uint256 paid0,
        uint256 paid1
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IFactory} from "../IFactory.sol";

interface IPoolStorage {
    /// @notice The contract that deployed the pool, which must adhere to the IFactory interface
    /// @return The contract address
    function factory() external view returns (IFactory);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (IERC20);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (IERC20);

    /// @notice The fee to be charged for a swap in basis points
    /// @return The swap fee in basis points
    function swapFeeUnits() external view returns (uint24);

    /// @notice The pool tick distance
    /// @dev Ticks can only be initialized and used at multiples of this value
    /// It remains an int24 to avoid casting even though it is >= 1.
    /// e.g: a tickDistance of 5 means ticks can be initialized every 5th tick, i.e., ..., -10, -5, 0, 5, 10, ...
    /// @return The tick distance
    function tickDistance() external view returns (int24);

    /// @notice Maximum gross liquidity that an initialized tick can have
    /// @dev This is to prevent overflow the pool's active base liquidity (uint128)
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxTickLiquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross total liquidity amount from positions that uses this tick as a lower or upper tick
    /// liquidityNet how much liquidity changes when the pool tick crosses above the tick
    /// feeGrowthOutside the fee growth on the other side of the tick relative to the current tick
    /// secondsPerLiquidityOutside the seconds spent on the other side of the tick relative to the current tick
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside,
            uint128 secondsPerLiquidityOutside
        );

    /// @notice Returns the previous and next initialized ticks of a specific tick
    /// @dev If specified tick is uninitialized, the returned values are zero.
    /// @param tick The tick to look up
    function initializedTicks(int24 tick) external view returns (int24 previous, int24 next);

    /// @notice Returns the information about a position by the position's key
    /// @return liquidity the liquidity quantity of the position
    /// @return feeGrowthInsideLast fee growth inside the tick range as of the last mint / burn action performed
    function getPositions(
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) external view returns (uint128 liquidity, uint256 feeGrowthInsideLast);

    /// @notice Fetches the pool's prices, ticks and lock status
    /// @return sqrtP sqrt of current price: sqrt(token1/token0)
    /// @return currentTick pool's current tick
    /// @return nearestCurrentTick pool's nearest initialized tick that is <= currentTick
    /// @return locked true if pool is locked, false otherwise
    function getPoolState()
        external
        view
        returns (
            uint160 sqrtP,
            int24 currentTick,
            int24 nearestCurrentTick,
            bool locked
        );

    /// @notice Fetches the pool's liquidity values
    /// @return baseL pool's base liquidity without reinvest liqudity
    /// @return reinvestL the liquidity is reinvested into the pool
    /// @return reinvestLLast last cached value of reinvestL, used for calculating reinvestment token qty
    function getLiquidityState()
        external
        view
        returns (
            uint128 baseL,
            uint128 reinvestL,
            uint128 reinvestLLast
        );

    /// @return feeGrowthGlobal All-time fee growth per unit of liquidity of the pool
    function getFeeGrowthGlobal() external view returns (uint256);

    /// @return secondsPerLiquidityGlobal All-time seconds per unit of liquidity of the pool
    /// @return lastUpdateTime The timestamp in which secondsPerLiquidityGlobal was last updated
    function getSecondsPerLiquidityData()
        external
        view
        returns (uint128 secondsPerLiquidityGlobal, uint32 lastUpdateTime);

    /// @notice Calculates and returns the active time per unit of liquidity until current block.timestamp
    /// @param tickLower The lower tick (of a position)
    /// @param tickUpper The upper tick (of a position)
    /// @return secondsPerLiquidityInside active time (multiplied by 2^96)
    /// between the 2 ticks, per unit of liquidity.
    function getSecondsPerLiquidityInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (uint128 secondsPerLiquidityInside);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title KyberSwap v2 factory
/// @notice Deploys KyberSwap v2 pools and manages control over government fees
interface IFactory {
    /// @notice Emitted when a pool is created
    /// @param token0 First pool token by address sort order
    /// @param token1 Second pool token by address sort order
    /// @param swapFeeUnits Fee to be collected upon every swap in the pool, in fee units
    /// @param tickDistance Minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed swapFeeUnits,
        int24 tickDistance,
        address pool
    );

    /// @notice Emitted when a new fee is enabled for pool creation via the factory
    /// @param swapFeeUnits Fee to be collected upon every swap in the pool, in fee units
    /// @param tickDistance Minimum number of ticks between initialized ticks for pools created with the given fee
    event SwapFeeEnabled(uint24 indexed swapFeeUnits, int24 indexed tickDistance);

    /// @notice Emitted when vesting period changes
    /// @param vestingPeriod The maximum time duration for which LP fees
    /// are proportionally burnt upon LP removals
    event VestingPeriodUpdated(uint32 vestingPeriod);

    /// @notice Emitted when configMaster changes
    /// @param oldConfigMaster configMaster before the update
    /// @param newConfigMaster configMaster after the update
    event ConfigMasterUpdated(address oldConfigMaster, address newConfigMaster);

    /// @notice Emitted when fee configuration changes
    /// @param feeTo Recipient of government fees
    /// @param governmentFeeUnits Fee amount, in fee units,
    /// to be collected out of the fee charged for a pool swap
    event FeeConfigurationUpdated(address feeTo, uint24 governmentFeeUnits);

    /// @notice Emitted when whitelist feature is enabled
    event WhitelistEnabled();

    /// @notice Emitted when whitelist feature is disabled
    event WhitelistDisabled();

    /// @notice Returns the maximum time duration for which LP fees
    /// are proportionally burnt upon LP removals
    function vestingPeriod() external view returns (uint32);

    /// @notice Returns the tick distance for a specified fee.
    /// @dev Once added, cannot be updated or removed.
    /// @param swapFeeUnits Swap fee, in fee units.
    /// @return The tick distance. Returns 0 if fee has not been added.
    function feeAmountTickDistance(uint24 swapFeeUnits) external view returns (int24);

    /// @notice Returns the address which can update the fee configuration
    function configMaster() external view returns (address);

    /// @notice Returns the keccak256 hash of the Pool creation code
    /// This is used for pre-computation of pool addresses
    function poolInitHash() external view returns (bytes32);

    /// @notice Fetches the recipient of government fees
    /// and current government fee charged in fee units
    function feeConfiguration() external view returns (address _feeTo, uint24 _governmentFeeUnits);

    /// @notice Returns the status of whitelisting feature of NFT managers
    /// If true, anyone can mint liquidity tokens
    /// Otherwise, only whitelisted NFT manager(s) are allowed to mint liquidity tokens
    function whitelistDisabled() external view returns (bool);

    //// @notice Returns all whitelisted NFT managers
    /// If the whitelisting feature is turned on,
    /// only whitelisted NFT manager(s) are allowed to mint liquidity tokens
    function getWhitelistedNFTManagers() external view returns (address[] memory);

    /// @notice Checks if sender is a whitelisted NFT manager
    /// If the whitelisting feature is turned on,
    /// only whitelisted NFT manager(s) are allowed to mint liquidity tokens
    /// @param sender address to be checked
    /// @return true if sender is a whistelisted NFT manager, false otherwise
    function isWhitelistedNFTManager(address sender) external view returns (bool);

    /// @notice Returns the pool address for a given pair of tokens and a swap fee
    /// @dev Token order does not matter
    /// @param tokenA Contract address of either token0 or token1
    /// @param tokenB Contract address of the other token
    /// @param swapFeeUnits Fee to be collected upon every swap in the pool, in fee units
    /// @return pool The pool address. Returns null address if it does not exist
    function getPool(
        address tokenA,
        address tokenB,
        uint24 swapFeeUnits
    ) external view returns (address pool);

    /// @notice Fetch parameters to be used for pool creation
    /// @dev Called by the pool constructor to fetch the parameters of the pool
    /// @return factory The factory address
    /// @return token0 First pool token by address sort order
    /// @return token1 Second pool token by address sort order
    /// @return swapFeeUnits Fee to be collected upon every swap in the pool, in fee units
    /// @return tickDistance Minimum number of ticks between initialized ticks
    function parameters()
        external
        view
        returns (
            address factory,
            address token0,
            address token1,
            uint24 swapFeeUnits,
            int24 tickDistance
        );

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param swapFeeUnits Desired swap fee for the pool, in fee units
    /// @dev Token order does not matter. tickDistance is determined from the fee.
    /// Call will revert under any of these conditions:
    ///     1) pool already exists
    ///     2) invalid swap fee
    ///     3) invalid token arguments
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 swapFeeUnits
    ) external returns (address pool);

    /// @notice Enables a fee amount with the given tickDistance
    /// @dev Fee amounts may never be removed once enabled
    /// @param swapFeeUnits The fee amount to enable, in fee units
    /// @param tickDistance The distance between ticks to be enforced for all pools created with the given fee amount
    function enableSwapFee(uint24 swapFeeUnits, int24 tickDistance) external;

    /// @notice Updates the address which can update the fee configuration
    /// @dev Must be called by the current configMaster
    function updateConfigMaster(address) external;

    /// @notice Updates the vesting period
    /// @dev Must be called by the current configMaster
    function updateVestingPeriod(uint32) external;

    /// @notice Updates the address receiving government fees and fee quantity
    /// @dev Only configMaster is able to perform the update
    /// @param feeTo Address to receive government fees collected from pools
    /// @param governmentFeeUnits Fee amount, in fee units,
    /// to be collected out of the fee charged for a pool swap
    function updateFeeConfiguration(address feeTo, uint24 governmentFeeUnits) external;

    /// @notice Enables the whitelisting feature
    /// @dev Only configMaster is able to perform the update
    function enableWhitelist() external;

    /// @notice Disables the whitelisting feature
    /// @dev Only configMaster is able to perform the update
    function disableWhitelist() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKyberSwapElasticLMEvents {
  event AddPool(
    uint256 indexed pId,
    address poolAddress,
    uint32 startTime,
    uint32 endTime,
    uint32 vestingDuration,
    uint256 feeTarget
  );

  event RenewPool(
    uint256 indexed pid,
    uint32 startTime,
    uint32 endTime,
    uint32 vestingDuration,
    uint256 feeTarget
  );

  event Deposit(address sender, uint256 indexed nftId);

  event Withdraw(address sender, uint256 indexed nftId);

  event Join(uint256 indexed nftId, uint256 indexed pId, uint256 indexed liq);

  event Exit(address to, uint256 indexed nftId, uint256 indexed pId, uint256 indexed liq);

  event SyncLiq(uint256 indexed nftId, uint256 indexed pId, uint256 indexed liq);

  event Harvest(address to, address reward, uint256 indexed amount);

  event EmergencyEnabled();

  event EmergencyWithdrawForOwner(address reward, uint256 indexed amount);

  event EmergencyWithdraw(address sender, uint256 indexed nftId);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../IProtocolGovernance.sol";
import "../IVaultRegistry.sol";
import "./IVault.sol";

interface IVaultGovernance {
    /// @notice Internal references of the contract.
    /// @param protocolGovernance Reference to Protocol Governance
    /// @param registry Reference to Vault Registry
    struct InternalParams {
        IProtocolGovernance protocolGovernance;
        IVaultRegistry registry;
        IVault singleton;
    }

    // -------------------  EXTERNAL, VIEW  -------------------

    /// @notice Timestamp in unix time seconds after which staged Delayed Strategy Params could be committed.
    /// @param nft Nft of the vault
    function delayedStrategyParamsTimestamp(uint256 nft) external view returns (uint256);

    /// @notice Timestamp in unix time seconds after which staged Delayed Protocol Params could be committed.
    function delayedProtocolParamsTimestamp() external view returns (uint256);

    /// @notice Timestamp in unix time seconds after which staged Delayed Protocol Params Per Vault could be committed.
    /// @param nft Nft of the vault
    function delayedProtocolPerVaultParamsTimestamp(uint256 nft) external view returns (uint256);

    /// @notice Timestamp in unix time seconds after which staged Internal Params could be committed.
    function internalParamsTimestamp() external view returns (uint256);

    /// @notice Internal Params of the contract.
    function internalParams() external view returns (InternalParams memory);

    /// @notice Staged new Internal Params.
    /// @dev The Internal Params could be committed after internalParamsTimestamp
    function stagedInternalParams() external view returns (InternalParams memory);

    // -------------------  EXTERNAL, MUTATING  -------------------

    /// @notice Stage new Internal Params.
    /// @param newParams New Internal Params
    function stageInternalParams(InternalParams memory newParams) external;

    /// @notice Commit staged Internal Params.
    function commitInternalParams() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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
interface IERC165 {
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
pragma solidity ^0.8.0;

import "./utils/IDefaultAccessControl.sol";
import "./IUnitPricesGovernance.sol";

interface IProtocolGovernance is IDefaultAccessControl, IUnitPricesGovernance {
    /// @notice CommonLibrary protocol params.
    /// @param maxTokensPerVault Max different token addresses that could be managed by the vault
    /// @param governanceDelay The delay (in secs) that must pass before setting new pending params to commiting them
    /// @param protocolTreasury The address that collects protocolFees, if protocolFee is not zero
    /// @param forceAllowMask If a permission bit is set in this mask it forces all addresses to have this permission as true
    /// @param withdrawLimit Withdraw limit (in unit prices, i.e. usd)
    struct Params {
        uint256 maxTokensPerVault;
        uint256 governanceDelay;
        address protocolTreasury;
        uint256 forceAllowMask;
        uint256 withdrawLimit;
    }

    // -------------------  EXTERNAL, VIEW  -------------------

    /// @notice Timestamp after which staged granted permissions for the given address can be committed.
    /// @param target The given address
    /// @return Zero if there are no staged permission grants, timestamp otherwise
    function stagedPermissionGrantsTimestamps(address target) external view returns (uint256);

    /// @notice Staged granted permission bitmask for the given address.
    /// @param target The given address
    /// @return Bitmask
    function stagedPermissionGrantsMasks(address target) external view returns (uint256);

    /// @notice Permission bitmask for the given address.
    /// @param target The given address
    /// @return Bitmask
    function permissionMasks(address target) external view returns (uint256);

    /// @notice Timestamp after which staged pending protocol parameters can be committed
    /// @return Zero if there are no staged parameters, timestamp otherwise.
    function stagedParamsTimestamp() external view returns (uint256);

    /// @notice Staged pending protocol parameters.
    function stagedParams() external view returns (Params memory);

    /// @notice Current protocol parameters.
    function params() external view returns (Params memory);

    /// @notice Addresses for which non-zero permissions are set.
    function permissionAddresses() external view returns (address[] memory);

    /// @notice Permission addresses staged for commit.
    function stagedPermissionGrantsAddresses() external view returns (address[] memory);

    /// @notice Return all addresses where rawPermissionMask bit for permissionId is set to 1.
    /// @param permissionId Id of the permission to check.
    /// @return A list of dirty addresses.
    function addressesByPermission(uint8 permissionId) external view returns (address[] memory);

    /// @notice Checks if address has permission or given permission is force allowed for any address.
    /// @param addr Address to check
    /// @param permissionId Permission to check
    function hasPermission(address addr, uint8 permissionId) external view returns (bool);

    /// @notice Checks if address has all permissions.
    /// @param target Address to check
    /// @param permissionIds A list of permissions to check
    function hasAllPermissions(address target, uint8[] calldata permissionIds) external view returns (bool);

    /// @notice Max different ERC20 token addresses that could be managed by the protocol.
    function maxTokensPerVault() external view returns (uint256);

    /// @notice The delay for committing any governance params.
    function governanceDelay() external view returns (uint256);

    /// @notice The address of the protocol treasury.
    function protocolTreasury() external view returns (address);

    /// @notice Permissions mask which defines if ordinary permission should be reverted.
    /// This bitmask is xored with ordinary mask.
    function forceAllowMask() external view returns (uint256);

    /// @notice Withdraw limit per token per block.
    /// @param token Address of the token
    /// @return Withdraw limit per token per block
    function withdrawLimit(address token) external view returns (uint256);

    /// @notice Addresses that has staged validators.
    function stagedValidatorsAddresses() external view returns (address[] memory);

    /// @notice Timestamp after which staged granted permissions for the given address can be committed.
    /// @param target The given address
    /// @return Zero if there are no staged permission grants, timestamp otherwise
    function stagedValidatorsTimestamps(address target) external view returns (uint256);

    /// @notice Staged validator for the given address.
    /// @param target The given address
    /// @return Validator
    function stagedValidators(address target) external view returns (address);

    /// @notice Addresses that has validators.
    function validatorsAddresses() external view returns (address[] memory);

    /// @notice Address that has validators.
    /// @param i The number of address
    /// @return Validator address
    function validatorsAddress(uint256 i) external view returns (address);

    /// @notice Validator for the given address.
    /// @param target The given address
    /// @return Validator
    function validators(address target) external view returns (address);

    // -------------------  EXTERNAL, MUTATING, GOVERNANCE, IMMEDIATE  -------------------

    /// @notice Rollback all staged validators.
    function rollbackStagedValidators() external;

    /// @notice Revoke validator instantly from the given address.
    /// @param target The given address
    function revokeValidator(address target) external;

    /// @notice Stages a new validator for the given address
    /// @param target The given address
    /// @param validator The validator for the given address
    function stageValidator(address target, address validator) external;

    /// @notice Commits validator for the given address.
    /// @dev Reverts if governance delay has not passed yet.
    /// @param target The given address.
    function commitValidator(address target) external;

    /// @notice Commites all staged validators for which governance delay passed
    /// @return Addresses for which validators were committed
    function commitAllValidatorsSurpassedDelay() external returns (address[] memory);

    /// @notice Rollback all staged granted permission grant.
    function rollbackStagedPermissionGrants() external;

    /// @notice Commits permission grants for the given address.
    /// @dev Reverts if governance delay has not passed yet.
    /// @param target The given address.
    function commitPermissionGrants(address target) external;

    /// @notice Commites all staged permission grants for which governance delay passed.
    /// @return An array of addresses for which permission grants were committed.
    function commitAllPermissionGrantsSurpassedDelay() external returns (address[] memory);

    /// @notice Revoke permission instantly from the given address.
    /// @param target The given address.
    /// @param permissionIds A list of permission ids to revoke.
    function revokePermissions(address target, uint8[] memory permissionIds) external;

    /// @notice Commits staged protocol params.
    /// Reverts if governance delay has not passed yet.
    function commitParams() external;

    // -------------------  EXTERNAL, MUTATING, GOVERNANCE, DELAY  -------------------

    /// @notice Sets new pending params that could have been committed after governance delay expires.
    /// @param newParams New protocol parameters to set.
    function stageParams(Params memory newParams) external;

    /// @notice Stage granted permissions that could have been committed after governance delay expires.
    /// Resets commit delay and permissions if there are already staged permissions for this address.
    /// @param target Target address
    /// @param permissionIds A list of permission ids to grant
    function stagePermissionGrants(address target, uint8[] memory permissionIds) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IProtocolGovernance.sol";

interface IVaultRegistry is IERC721 {
    /// @notice Get Vault for the giver NFT ID.
    /// @param nftId NFT ID
    /// @return vault Address of the Vault contract
    function vaultForNft(uint256 nftId) external view returns (address vault);

    /// @notice Get NFT ID for given Vault contract address.
    /// @param vault Address of the Vault contract
    /// @return nftId NFT ID
    function nftForVault(address vault) external view returns (uint256 nftId);

    /// @notice Checks if the nft is locked for all transfers
    /// @param nft NFT to check for lock
    /// @return `true` if locked, false otherwise
    function isLocked(uint256 nft) external view returns (bool);

    /// @notice Register new Vault and mint NFT.
    /// @param vault address of the vault
    /// @param owner owner of the NFT
    /// @return nft Nft minted for the given Vault
    function registerVault(address vault, address owner) external returns (uint256 nft);

    /// @notice Number of Vaults registered.
    function vaultsCount() external view returns (uint256);

    /// @notice All Vaults registered.
    function vaults() external view returns (address[] memory);

    /// @notice Address of the ProtocolGovernance.
    function protocolGovernance() external view returns (IProtocolGovernance);

    /// @notice Address of the staged ProtocolGovernance.
    function stagedProtocolGovernance() external view returns (IProtocolGovernance);

    /// @notice Minimal timestamp when staged ProtocolGovernance can be applied.
    function stagedProtocolGovernanceTimestamp() external view returns (uint256);

    /// @notice Stage new ProtocolGovernance.
    /// @param newProtocolGovernance new ProtocolGovernance
    function stageProtocolGovernance(IProtocolGovernance newProtocolGovernance) external;

    /// @notice Commit new ProtocolGovernance.
    function commitStagedProtocolGovernance() external;

    /// @notice Lock NFT for transfers
    /// @dev Use this method when vault structure is set up and should become immutable. Can be called by owner.
    /// @param nft - NFT to lock
    function lockNft(uint256 nft) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

interface IDefaultAccessControl is IAccessControlEnumerable {
    /// @notice Checks that the address is contract admin.
    /// @param who Address to check
    /// @return `true` if who is admin, `false` otherwise
    function isAdmin(address who) external view returns (bool);

    /// @notice Checks that the address is contract admin.
    /// @param who Address to check
    /// @return `true` if who is operator, `false` otherwise
    function isOperator(address who) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./utils/IDefaultAccessControl.sol";

interface IUnitPricesGovernance is IDefaultAccessControl, IERC165 {
    // -------------------  EXTERNAL, VIEW  -------------------

    /// @notice Estimated amount of token worth 1 USD staged for commit.
    /// @param token Address of the token
    /// @return The amount of token
    function stagedUnitPrices(address token) external view returns (uint256);

    /// @notice Timestamp after which staged unit prices for the given token can be committed.
    /// @param token Address of the token
    /// @return Timestamp
    function stagedUnitPricesTimestamps(address token) external view returns (uint256);

    /// @notice Estimated amount of token worth 1 USD.
    /// @param token Address of the token
    /// @return The amount of token
    function unitPrices(address token) external view returns (uint256);

    // -------------------  EXTERNAL, MUTATING  -------------------

    /// @notice Stage estimated amount of token worth 1 USD staged for commit.
    /// @param token Address of the token
    /// @param value The amount of token
    function stageUnitPrice(address token, uint256 value) external;

    /// @notice Reset staged value
    /// @param token Address of the token
    function rollbackUnitPrice(address token) external;

    /// @notice Commit staged unit price
    /// @param token Address of the token
    function commitUnitPrice(address token) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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