pragma solidity ^0.8.0;


import "../common/variables.sol";

contract ReadModule is Variables {

    function poolEnabled(address pool_) external view returns (bool) {
        return _poolEnabled[pool_];
    }

    // Return true if the NFT is deposited and the owner is the owner_
    function position(address owner_, uint NFTID_) external view returns (bool) {
        return _position[owner_][NFTID_];
    }

    // returns to owner of the NFT
    function nftOwner(uint96 NFTID_) external view returns (address) {
        return _nftList[NFTID_].owner;
    }

    // NFT Link (User Address => first, last & count)
    function nftLink(address user_) external view returns (uint96 first_, uint96 last_, uint64 count_) {
        return (_nftLink[user_].first, _nftLink[user_].last, _nftLink[user_].count);
    }

    // Linked List of NFTIDs (NFTID => prev, next & owner
    function nftList(uint96 NFTID_) external view returns (uint48 prev_, uint48 next_, address owner_) {
        return (_nftList[NFTID_].prev, _nftList[NFTID_].next, _nftList[NFTID_].owner);
    }

    function isStaked(uint NFTID_) external view returns (bool) {
        return _isStaked[NFTID_];
    }

    // NFT ID => no. of stakes
    function stakeCount(uint NFTID_) external view returns (uint) {
        return _stakeCount[NFTID_];
    }

    function minTick(address pool_) external view returns (uint) {
        return _minTick[pool_];
    }

    function borrowBalRaw(uint NFTID_, address token_) external view returns (uint) {
        return _borrowBalRaw[NFTID_][token_];
    }

    function borrowAllowed(address pool_, address token_) external view returns (bool) {
        return _borrowAllowed[pool_][token_];
    }

    function poolMarkets(address pool_) external view returns (address[] memory) {
        return _poolMarkets[pool_];
    }

    function poolRawBorrow(address pool_, address token_) external view returns (uint256) {
        return _poolRawBorrow[pool_][token_];
    }

    function poolBorrowLimit(address pool_, address token_) external view returns (uint256) {
        return _poolBorrowLimit[pool_][token_];
    }

    function borrowLimit(address pool_) external view returns (uint128 normal_, uint128 extended_) {
        normal_ = _borrowLimit[pool_].normal;
        extended_ = _borrowLimit[pool_].extended;
    }

    function priceSlippage(address pool_) external view returns (uint) {
        return _priceSlippage[pool_];
    }

    function tickCheck(address pool_) external view returns (TickCheck memory tickCheck_) {
        tickCheck_= _tickCheck[pool_];
    }

    function rewardTokens(address token_) external view returns (address[] memory) {
        return _rewardTokens[token_];
    }

    function rewardRate(address token_, address rewardToken_) external view returns (RewardRate memory) {
        return _rewardRate[token_][rewardToken_];
    }

    function rewardPrice(address token_, address rewardToken_) external view returns (uint rewardPrice_, uint lastUpdateTime_) {
        rewardPrice_ = _rewardPrice[token_][rewardToken_].rewardPrice;
        lastUpdateTime_ = _rewardPrice[token_][rewardToken_].lastUpdateTime;
    }

    function nftRewards(uint96 NFTID_, address token_, address rewardToken_) external view returns (uint lastRewardPrice_, uint reward_) {
        lastRewardPrice_ = _nftRewards[NFTID_][token_][rewardToken_].lastRewardPrice;
        reward_ = _nftRewards[NFTID_][token_][rewardToken_].reward;
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