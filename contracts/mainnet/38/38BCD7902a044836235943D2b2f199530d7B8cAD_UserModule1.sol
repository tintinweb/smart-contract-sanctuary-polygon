pragma solidity ^0.8.0;

import "./helpers.sol";

contract CoreInternals is Helpers {

    /**
    * @dev Add NFT to user's nft list.
    * @param user_ user's address.
    * @param NFTID_ ID of NFT.
    */
    function addNft(address user_, uint96 NFTID_) internal {
        if (_nftLink[user_].first == 0) {
            _nftLink[user_].first = NFTID_;
            _nftList[NFTID_].owner = user_;
        } else {
            uint96 last_ = _nftLink[user_].last;
            _nftList[last_].next = uint48(NFTID_);
            _nftList[NFTID_].prev = uint48(last_);
            _nftList[NFTID_].owner = user_;
        }
        _nftLink[user_].last = NFTID_;
        _nftLink[user_].count++;
    }

    /**
    * @dev Remove NFT from user's nft list.
    * @param user_ user's address.
    * @param NFTID_ ID of NFT.
    */
    function removeNft(address user_, uint96 NFTID_) internal {
        uint48 prev_ = _nftList[NFTID_].prev;
        uint48 next_ = _nftList[NFTID_].next;
        if (prev_ != 0) _nftList[prev_].next = next_;
        if (next_ != 0) _nftList[next_].prev = prev_;
        if (prev_ == 0) _nftLink[user_].first = next_;
        if (next_ == 0) _nftLink[user_].last = prev_;
        _nftLink[user_].count--;
        delete _nftList[NFTID_];
    }

    /**
    * @dev deposit's NFT and creates a debt position against it.
    * @param owner_ owner of the NFT.
    * @param NFTID_ ID of NFT.
    */
    function deposit(address owner_, uint256 NFTID_) internal {
        _position[owner_][NFTID_] = true;
        (
            ,
            ,
            address token0_,
            address token1_,
            uint24 fee_,
            int24 tickLower_,
            int24 tickUpper_,
            ,
            ,
            ,
            ,
        ) = nftManager.positions(NFTID_);
        address pool_ = getPoolAddress(token0_, token1_, fee_);
        require(_poolEnabled[pool_], "P3:M2: NFT-pool-not-enabled");
        require(uint24(tickUpper_ - tickLower_) > _minTick[pool_], "P3:M2: less-ticks-difference");

        emit depositLog(owner_, NFTID_);
    }
    
}

contract UserModule1 is CoreInternals {

    modifier nonReentrant() {
        require(_status != 2, "P3:M2::ReentrancyGuard: reentrant call");
        _status = 2;
        _;
        _status = 1;
    }

    /**
    * @dev modifier the verify owner of NFT position. msg.sender should be an owner.
    * @param NFTID_ ID of NFT.
    */
    modifier isPositionOwner(uint96 NFTID_) {
        require(_position[msg.sender][NFTID_], "P3:M2: not-an-owner");
        _;
    }

    /**
    * @dev modifier the verifies that the NFT is not staked.
    * @param NFTID_ ID of NFT.
    */
    modifier isNotStaked(uint96 NFTID_) {
        require(!_isStaked[NFTID_], "P3:M2: NFT-should-be-unstaked");
        _;
    }

    /**
    * @dev Triggers when an ERC721 token receives to this contract.
    * @param _operator Person who initiated the transfer of NFT.
    * @param _from owner of NFT.
    * @param _id ID of NFT.
    */
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _id,
        bytes calldata
    ) external nonReentrant returns (bytes4) {
        require(_operator == _from, "P3:M2: operator-should-be-the-owner");
        require(msg.sender == nftManagerAddr, "P3:M2: Not-Uniswap-V3-NFT");
        deposit(_from, _id);
        addNft(_from, uint48(_id));
        return 0x150b7a02;
    }

    /**
    * @dev Withdraws the NFT from contract. NFT should have 0 debt.
    * @param NFTID_ NFT ID
    */
    function withdraw(uint96 NFTID_) external isPositionOwner(NFTID_) isNotStaked(NFTID_) nonReentrant {
        bool has_ = hasDebt(NFTID_);
        require(!has_, "P3:M2: debt-should-be-0");
        _position[msg.sender][NFTID_] = false;
        nftManager.safeTransferFrom(address(this), msg.sender, NFTID_);
        removeNft(msg.sender, NFTID_);
        
        emit withdrawLog(NFTID_);
    }

    /**
    * @dev Transfer position of user to another address. NFT should not be staked.
    * @param NFTID_ NFTID of user.
    * @param to_ address to transfer the position to.
    */
    function transferPosition(uint96 NFTID_, address to_) public isPositionOwner(NFTID_) nonReentrant {
        _position[msg.sender][NFTID_] = false;
        _position[to_][NFTID_] = true;
        removeNft(msg.sender, NFTID_);
        addNft(to_, NFTID_);

        emit transferPositionLog(NFTID_, to_);
    }
    
}

pragma solidity ^0.8.0;

import "../common/variables.sol";
import "./events.sol";
import "./interfaces.sol";

contract Helpers is Variables, Events {
    
    bytes32 internal constant POOL_INIT_CODE_HASH =
        0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;
    address internal constant nftManagerAddr =
        0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    INonfungiblePositionManager internal constant nftManager =
        INonfungiblePositionManager(nftManagerAddr);
    IUniswapV3Staker internal constant staker =
        IUniswapV3Staker(0xe34139463bA50bD61336E0c446Bd8C0867c6fE65);

    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /**
     * @dev computes the address of pool
     * @param factory_ factory address
     * @param key_ PoolKey struct
     */
    function computeAddress(address factory_, PoolKey memory key_)
        internal
        pure
        returns (address pool_)
    {
        require(key_.token0 < key_.token1);
        pool_ = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory_,
                            keccak256(
                                abi.encode(key_.token0, key_.token1, key_.fee)
                            ),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }

    /**
     * @dev returns pool address.
     * @param token0_ token 0 address
     * @param token1_ token 1 address
     * @param fee_ fee of pool
     * @return poolAddr_ pool address
     */
    function getPoolAddress(
        address token0_,
        address token1_,
        uint24 fee_
    ) internal view returns (address poolAddr_) {
        poolAddr_ = computeAddress(
            nftManager.factory(),
            PoolKey({token0: token0_, token1: token1_, fee: fee_})
        );
    }

    /**
     * Checks if user has any debt.
     * @param NFTID_ NFT ID
     * @return has_ true if has any debt.
     */
    function hasDebt(uint256 NFTID_) internal view returns (bool has_) {
        (
            ,
            ,
            address token0_,
            address token1_,
            uint24 fee_,
            ,
            ,
            ,
            ,
            ,
            ,

        ) = nftManager.positions(NFTID_);
        address pool_ = getPoolAddress(token0_, token1_, fee_);
        address[] memory markets_ = _poolMarkets[pool_];
        for (uint256 i = 0; i < markets_.length; i++) {
            has_ = _borrowBalRaw[NFTID_][markets_[i]] == 0 ? false : true;
            if (has_) break;
        }
    }
}

pragma solidity ^0.8.0;


import "../../common/ILiquidity.sol";

interface IRewardPool {
    function giveAllowance(address token_) external;
}

contract Variables {

    // status for re-entrancy. 1 = allow/non-entered, 2 = disallow/entered
    uint256 internal _status;

    ILiquidity constant internal liquidity = ILiquidity(0x11dE7Bd1251d1DB7Dc877e35e1648649a864102a); // TODO: add the core liquidity address
    IRewardPool constant internal rewardPool = IRewardPool(0x023e85cEeedF463b82541E2a7a8Fe49F41dEe0A8); // TODO: add the reward pool address

    // pool => bool. To enable a pool
    mapping (address => bool) internal _poolEnabled;

    // pool_address => token_address => rawBorrowAmount.
    mapping (address => mapping (address => uint256)) internal _poolRawBorrow;

    // pool_address => token_address => rawBorrowLimit.
    mapping (address => mapping (address => uint256)) internal _poolBorrowLimit;

    // owner => NFT ID => bool
    mapping (address => mapping (uint => bool)) internal _position;

    struct NftLink {
        uint96 first;
        uint96 last;
        uint64 count;
    }

    struct NftList {
        uint48 prev;
        uint48 next;
        address owner;
    }

    // NFT Link (User Address => NftLink(NFTID of First and Last And Count of NFTID's)).
    mapping (address => NftLink) internal _nftLink;

    // Linked List of NFTIDs (NFTID =>  NftList(Previous and next NFTID, owner of this NFT)).
    mapping (uint96 => NftList) internal _nftList;

    // NFT ID => bool
    mapping (uint => bool) internal _isStaked;

    // NFT ID => no. of stakes
    mapping (uint => uint) internal _stakeCount;

    uint public constant maxStakeCount = 5;

    // rewards accrued at the time of unstaking. NFTID -> token address -> reward amount
    mapping (uint => mapping(address => uint)) internal _rewardAccrued;

    // pool => minimum tick. Minimum tick difference a position should have to deposit (upperTick - lowerTick)
    mapping (address => uint) internal _minTick;

    // NFT ID => token => uint
    mapping (uint => mapping (address => uint)) internal _borrowBalRaw;

    // pool => token => bool
    mapping (address => mapping (address => bool)) internal _borrowAllowed;

    // pool => array or tokens. Market of borrow tokens for particular pool.
    // first 2 markets are always token0 & token1
    mapping (address => address[]) internal _poolMarkets;

    // normal. 8500 = 0.85.
    // extended. 9500 = 0.95.
    // extended meaning max totalborrow/totalsupply ratio
    // normal meaning canceling the same token borrow & supply and calculate ratio from rest of the tokens, meaning
    // if NFT has 1 ETH & 4000 USDC (at 1 ETH = 4000 USDC) and debt of 0.5 ETH & 5000 USDC then the ratio would be
    // extended = (2000 + 5000) / (4000 + 4000) = 7/8
    // normal = (0 + 1000) / (2000) = 1/2
    struct BorrowLimit {
        uint128 normal;
        uint128 extended;
    }

    // pool address => Borrow limit
    mapping (address => BorrowLimit) internal _borrowLimit;

    // pool => _priceSlippage
    // 1 = 0.01%. 10000 = 100%
    // used to check Uniswap and chainlink price
    mapping (address => uint) internal _priceSlippage;

    // Tick checkpoints
    // 5 checkpoints Eg:-
    // Past 10 sec.
    // Past 30 sec.
    // Past 60 sec.
    // Past 120 sec.
    // Past 300 sec.
    struct TickCheck {
        uint24 tickSlippage1;
        uint24 secsAgo1;
        uint24 tickSlippage2;
        uint24 secsAgo2;
        uint24 tickSlippage3;
        uint24 secsAgo3;
        uint24 tickSlippage4;
        uint24 secsAgo4;
        uint24 tickSlippage5;
        uint24 secsAgo5;
    }

    // pool => TickCheck
    mapping (address => TickCheck) internal _tickCheck;

    // token => oracle contract. Price in USD.
    mapping (address => address) internal _chainlinkOracle;

    struct RewardRate {
        uint128 rewardRate; // reward rate per sec
        uint64 startTime; // reward start time
        uint64 endTime; // reward end time
    }

    struct RewardPrice {
        uint256 rewardPrice; // rewards per total current raw borrow from start. Keeping it 256 bit as we're multiplying with 1e27 for proper decimal calculation
        uint256 lastUpdateTime; // in sec
    }

    struct NftReward {
        uint256 lastRewardPrice; // last updated reward price for this nft. Keeping it 256 bit as we're multiplying with 1e27 for proper decimal calculation
        uint256 reward; // rewards available for claiming for user
    }

    // token => reward tokens. One token can have multiple rewards going on.
    mapping (address => address[]) internal _rewardTokens;

    // token => reward token => reward rate per sec
    mapping (address => mapping (address => RewardRate)) internal _rewardRate;

    // rewards per total current raw borrow. _rewardPrice = _rewardPrice + (_rewardRate * timeElapsed) / total current raw borrow
    // multiplying with 1e27 to get decimal precision otherwise the number could get 0. To calculate users reward divide by 1e27 in the end.
    // token => reward token => reward price
    mapping (address => mapping (address => RewardPrice)) internal _rewardPrice; // starts from 0 & increase overtime.

    // last reward price stored for a nft. Multiplying (current - last) * (amount of token borrowed on nft) will give users new rewards earned
    // nftid => token => reward token => reward amount
    mapping (uint96 => mapping (address => mapping (address => NftReward))) internal _nftRewards;

}

pragma solidity ^0.8.0;


contract Events { 

    event depositLog(address owner_, uint256 NFTID_);

    event withdrawLog(uint96 NFTID_);

    event transferPositionLog(uint96 NFTID_, address to_);
    
}

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@uniswap/v3-core/contracts/interfaces/IERC20Minimal.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IMulticall.sol';

interface TokenInterface {
    function approve(address, uint256) external;

    function decimals() external view returns (uint256);
}

interface INonfungiblePositionManager {
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    function factory() external view returns (address);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external;

    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    function collect(CollectParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    function balanceOf(address) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

interface IUniswapV3Pool {
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    function token0() external view returns (address);

    function token1() external view returns (address);

    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s
        );

    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
}

struct IncreaseLiquidityParams {
    uint256 tokenId;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
}

/// @title Uniswap V3 Staker Interface
/// @notice Allows staking nonfungible liquidity tokens in exchange for reward tokens
interface IUniswapV3Staker is IERC721Receiver, IMulticall {
    /// @param rewardToken The token being distributed as a reward
    /// @param pool The Uniswap V3 pool
    /// @param startTime The time when the incentive program begins
    /// @param endTime The time when rewards stop accruing
    /// @param refundee The address which receives any remaining reward tokens when the incentive is ended
    struct IncentiveKey {
        IERC20Minimal rewardToken;
        IUniswapV3Pool pool;
        uint256 startTime;
        uint256 endTime;
        address refundee;
    }

    /// @notice The nonfungible position manager with which this staking contract is compatible
    function nonfungiblePositionManager() external view returns (INonfungiblePositionManager);

    /// @notice Represents a staking incentive
    /// @param incentiveId The ID of the incentive computed from its parameters
    /// @return totalRewardUnclaimed The amount of reward token not yet claimed by users
    /// @return totalSecondsClaimedX128 Total liquidity-seconds claimed, represented as a UQ32.128
    /// @return numberOfStakes The count of deposits that are currently staked for the incentive
    function incentives(bytes32 incentiveId)
        external
        view
        returns (
            uint256 totalRewardUnclaimed,
            uint160 totalSecondsClaimedX128,
            uint96 numberOfStakes
        );

    /// @notice Returns information about a deposited NFT
    /// @return owner The owner of the deposited NFT
    /// @return numberOfStakes Counter of how many incentives for which the liquidity is staked
    /// @return tickLower The lower tick of the range
    /// @return tickUpper The upper tick of the range
    function deposits(uint256 tokenId)
        external
        view
        returns (
            address owner,
            uint48 numberOfStakes,
            int24 tickLower,
            int24 tickUpper
        );

    /// @notice Returns information about a staked liquidity NFT
    /// @param tokenId The ID of the staked token
    /// @param incentiveId The ID of the incentive for which the token is staked
    /// @return secondsPerLiquidityInsideInitialX128 secondsPerLiquidity represented as a UQ32.128
    /// @return liquidity The amount of liquidity in the NFT as of the last time the rewards were computed
    function stakes(uint256 tokenId, bytes32 incentiveId)
        external
        view
        returns (uint160 secondsPerLiquidityInsideInitialX128, uint128 liquidity);

    /// @notice Returns amounts of reward tokens owed to a given address according to the last time all stakes were updated
    /// @param rewardToken The token for which to check rewards
    /// @param owner The owner for which the rewards owed are checked
    /// @return rewardsOwed The amount of the reward token claimable by the owner
    function rewards(IERC20Minimal rewardToken, address owner) external view returns (uint256 rewardsOwed);

    /// @notice Creates a new liquidity mining incentive program
    /// @param key Details of the incentive to create
    /// @param reward The amount of reward tokens to be distributed
    function createIncentive(IncentiveKey memory key, uint256 reward) external;

    /// @notice Ends an incentive after the incentive end time has passed and all stakes have been withdrawn
    /// @param key Details of the incentive to end
    /// @return refund The remaining reward tokens when the incentive is ended
    function endIncentive(IncentiveKey memory key) external returns (uint256 refund);

    /// @notice Withdraws a Uniswap V3 LP token `tokenId` from this contract to the recipient `to`
    /// @param tokenId The unique identifier of an Uniswap V3 LP token
    /// @param to The address where the LP token will be sent
    /// @param data An optional data array that will be passed along to the `to` address via the NFT safeTransferFrom
    function withdrawToken(
        uint256 tokenId,
        address to,
        bytes memory data
    ) external;

    /// @notice Stakes a Uniswap V3 LP token
    /// @param key The key of the incentive for which to stake the NFT
    /// @param tokenId The ID of the token to stake
    function stakeToken(IncentiveKey memory key, uint256 tokenId) external;

    /// @notice Unstakes a Uniswap V3 LP token
    /// @param key The key of the incentive for which to unstake the NFT
    /// @param tokenId The ID of the token to unstake
    function unstakeToken(IncentiveKey memory key, uint256 tokenId) external;

    /// @notice Transfers `amountRequested` of accrued `rewardToken` rewards from the contract to the recipient `to`
    /// @param rewardToken The token being distributed as a reward
    /// @param to The address where claimed rewards will be sent to
    /// @param amountRequested The amount of reward tokens to claim. Claims entire reward amount if set to 0.
    /// @return reward The amount of reward tokens claimed
    function claimReward(
        IERC20Minimal rewardToken,
        address to,
        uint256 amountRequested
    ) external returns (uint256 reward);

}

struct CollectParams {
    uint256 tokenId;
    address recipient;
    uint128 amount0Max;
    uint128 amount1Max;
}

struct DecreaseLiquidityParams {
    uint256 tokenId;
    uint128 liquidity;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
}

pragma solidity ^0.8.0;


interface ILiquidity {

    function supply(
        address token_,
        uint amount_
    ) external returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    );

    function withdraw(
        address token_,
        uint amount_
    ) external returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    );

    function borrow(
        address token_,
        uint amount_
    ) external returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    );

    function payback(
        address token_,
        uint amount_
    ) external returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    );

    function updateInterest(
        address token_
    ) external view returns (
        uint newSupplyExchangePrice,
        uint newBorrowExchangePrice
    );

    function isProtocol(address protocol_) external view returns (bool);

    function protocolBorrowLimit(address protocol_, address token_) external view returns (uint256);

    function totalSupplyRaw(address token_) external view returns (uint256);

    function totalBorrowRaw(address token_) external view returns (uint256);

    function protocolRawSupply(address protocol_, address token_) external view returns (uint256);

    function protocolRawBorrow(address protocol_, address token_) external view returns (uint256);

    struct Rates {
        uint96 lastSupplyExchangePrice; // last stored exchange price. Increases overtime.
        uint96 lastBorrowExchangePrice; // last stored exchange price. Increases overtime.
        uint48 lastUpdateTime; // in sec
        uint16 utilization; // utilization. 10000 = 100%
    }

    function rate(address token_) external view returns (Rates memory);

}

// SPDX-License-Identifier: MIT

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Minimal ERC20 interface for Uniswap
/// @notice Contains a subset of the full ERC20 interface that is used in Uniswap V3
interface IERC20Minimal {
    /// @notice Returns the balance of a token
    /// @param account The account for which to look up the number of tokens it has, i.e. its balance
    /// @return The number of tokens held by the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers the amount of token from the `msg.sender` to the recipient
    /// @param recipient The account that will receive the amount transferred
    /// @param amount The number of tokens to send from the sender to the recipient
    /// @return Returns true for a successful transfer, false for an unsuccessful transfer
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Returns the current allowance given to a spender by an owner
    /// @param owner The account of the token owner
    /// @param spender The account of the token spender
    /// @return The current allowance granted by `owner` to `spender`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets the allowance of a spender from the `msg.sender` to the value `amount`
    /// @param spender The account which will be allowed to spend a given amount of the owners tokens
    /// @param amount The amount of tokens allowed to be used by `spender`
    /// @return Returns true for a successful approval, false for unsuccessful
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`
    /// @param sender The account from which the transfer will be initiated
    /// @param recipient The recipient of the transfer
    /// @param amount The amount of the transfer
    /// @return Returns true for a successful transfer, false for unsuccessful
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @notice Event emitted when tokens are transferred from one address to another, either via `#transfer` or `#transferFrom`.
    /// @param from The account from which the tokens were sent, i.e. the balance decreased
    /// @param to The account to which the tokens were sent, i.e. the balance increased
    /// @param value The amount of tokens that were transferred
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Event emitted when the approval amount for the spender of a given owner's tokens changes.
    /// @param owner The account that approved spending of its tokens
    /// @param spender The account for which the spending allowance was modified
    /// @param value The new allowance from the owner to the spender
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}