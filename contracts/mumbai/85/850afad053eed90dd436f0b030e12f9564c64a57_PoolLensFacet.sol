// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { SwapStorage, InfoStorage, SwapStorageLib, StorageLib } from "../../src/Storage.sol";
import { IPoolLens } from "../interfaces/IPoolLens.sol";
import { Token, TokenImpl } from "Util/Token.sol";
import { Price, SqrtPriceLib } from "Ticks/Tick.sol";
import { BidAsk } from "Swap/BidAsk.sol";
import { TableIndex } from "Ticks/Table.sol";
import { TickTable, TickTableImpl } from "Ticks/TickTable.sol";
import { TickIndex, TickIndexImpl } from "Ticks/Tick.sol";
import { TickData } from "Ticks/Data.sol";
import { Asset, AssetBook, AssetBookImpl } from "Liq/Asset.sol";

/// A lens for examining pool details
contract PoolLensFacet is IPoolLens {
    using TokenImpl for Token;
    using TickTableImpl for TickTable;
    using TickIndexImpl for TickIndex;

    error IncorrectTableBounds(int24 lower, int24 upper);

    /// @inheritdoc IPoolLens
    function getTokenPair() external view override returns (address tokenX, address tokenY) {
        InfoStorage storage info = StorageLib.info();
        tokenX = info.tokenX.addr();
        tokenY = info.tokenY.addr();
    }

    /// @inheritdoc IPoolLens
    function getPM() external view override returns (address PM) {
        PM = StorageLib.info().PM;
    }

    /// @inheritdoc IPoolLens
    function getCurrentSqrtPrice() external view override returns (uint160 sqrtPriceX96) {
        sqrtPriceX96 = Price.unwrap(SwapStorageLib.load().sqrtP);
    }

    /// @inheritdoc IPoolLens
    function getCurrentTableIndex() external view override returns (int24 tableIndex) {
        TickTable storage table = StorageLib.table();
        TickIndex ti = SqrtPriceLib.toTick(SwapStorageLib.load().sqrtP);
        return TableIndex.unwrap(table.getTableIndex(ti));
    }

    /// @inheritdoc IPoolLens
    function getBidAsk() external view override returns (uint160 bidSqrtX96, uint160 askSqrtX96) {
        BidAsk storage bidAsk = StorageLib.bidAsk();
        bidSqrtX96 = Price.unwrap(bidAsk.bidSP);
        askSqrtX96 = Price.unwrap(bidAsk.askSP);
    }

    /// @inheritdoc IPoolLens
    function getTickSpacing() external view override returns (uint24 spacing) {
        TickTable storage table = StorageLib.table();
        spacing = uint24(table.spacing);
    }

    /// @inheritdoc IPoolLens
    function getTableIndex(uint160 sqrtPriceX96) external view override returns (int24 tableIndex) {
        Price sqrtP = SqrtPriceLib.make(sqrtPriceX96);
        TickTable storage table = StorageLib.table();
        return TableIndex.unwrap(table.getTableIndex(SqrtPriceLib.toTick(sqrtP)));
    }

    /// @inheritdoc IPoolLens
    function getSqrtPrice(int24 tableIndex) external view override returns (uint160 sqrtPriceX96) {
        TickTable storage table = StorageLib.table();
        TableIndex bi = table.makeTableIndex(tableIndex);
        TickIndex tick = table.getTickIndex(bi);
        return Price.unwrap(tick.toSqrtPrice());
    }

    /* Liquidity */

    /// @inheritdoc IPoolLens
    function getCurrentLiqs() external view override returns (uint128 mLiq, uint128 tLiq) {
        SwapStorage storage swaps = SwapStorageLib.load();
        mLiq = swaps.mLiq;
        tLiq = swaps.tLiq;
    }

    /// @inheritdoc IPoolLens
    function getTableDelta(int24 tableIndex) external view override returns (int128 mDelta, int128 tDelta) {
        TickTable storage table = StorageLib.table();
        TableIndex bi = table.makeTableIndex(tableIndex);
        TickData storage data = table.getData(bi);
        mDelta = data.mLiqDelta;
        tDelta = data.tLiqDelta;
    }

    /// @inheritdoc IPoolLens
    function getTableDeltas(int24 lowTableIndex, int24 highTableIndex)
    external view override returns (int128[] memory mLiqDeltas, int128[] memory tLiqDeltas) {
        TickTable storage table = StorageLib.table();

        if (highTableIndex <= lowTableIndex) {
            revert IncorrectTableBounds(lowTableIndex, highTableIndex);
        }
        uint24 length = uint24(highTableIndex - lowTableIndex);
        mLiqDeltas = new int128[](length);
        tLiqDeltas = new int128[](length);

        for (uint24 i = 0; i < length; ++i) {
            int24 bi = lowTableIndex + int24(i);
            TickData storage data = table.getData(TableIndex.wrap(bi));
            mLiqDeltas[i] = data.mLiqDelta;
            tLiqDeltas[i] = data.tLiqDelta;
        }
    }

    /* Tick Traversal */

    /// @inheritdoc IPoolLens
    function getNextActiveTableIndex(int24 tableIndex) external view override returns (bool exists, int24 nextTable) {
        TickTable storage table = StorageLib.table();
        TableIndex bi = table.makeTableIndex(tableIndex);
        (bool _exists, TableIndex next) = table.getNextTableIndex(bi);
        exists = _exists; // Solidity flaw
        nextTable = TableIndex.unwrap(next);
    }

    /// @inheritdoc IPoolLens
    function getPrevActiveTableIndex(int24 tableIndex) external view override returns (bool exists, int24 prevTable) {
        TickTable storage table = StorageLib.table();
        TableIndex bi = table.makeTableIndex(tableIndex);
        (bool _exists, TableIndex prev) = table.getPrevTableIndex(bi);
        exists = _exists; // Solidity flaw
        prevTable = TableIndex.unwrap(prev);
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { BidAsk } from "Swap/BidAsk.sol";
import { AssetBook } from "Liq/Asset.sol";
import { LiqTree } from "Liq/Tree.sol";
import { TickTable } from "Ticks/TickTable.sol";
import { TBP } from "Borrow/TBP.sol";
import { InternalBorrower } from "Borrow/Internal.sol";
import { FeeCollector } from "Fee/Fees.sol";

import { Token } from "Util/Token.sol";
import { Price } from "Ticks/Tick.sol";
import { TableIndex } from "Ticks/Table.sol";
import { Status } from "Pool/Status.sol";

/* solhint-disable */

/// This is not really immutable at the moment. We'll have to figure out how to
/// use immutable storage in Diamond Patterns.
struct InfoStorage {
    Token tokenX; // 160 bits
    /* 256 */
    Token tokenY; // 160
    /* 256 */
    address PM; // The external PositionManager

    // Param Update Config
    uint32 shortDelay;
    uint32 mediumDelay;
    uint32 longDelay;

    /* 256 */

    // Borrow related info
    uint32 bRateUpdateInterval; // The update interval for the borrow rate.
    bool useIBR; // Whether or not we need the internal borrower.
    // 40 bits

    // Status related
    Status status;
    uint8 numPendingCuts;
    uint64 unhaltTime;
    // 80 bits
}

/// Central library for where most storage is kept.
/// Some storage is done in their own libraries when they have niche use cases.
library StorageLib {
    bytes32 public constant INFO_STORAGE_POSITION = keccak256("v4.info.diamond.storage");
    bytes32 public constant BIDASK_STORAGE_POSITION = keccak256("v4.bidask.diamond.storage");
    bytes32 public constant POS_STORAGE_POSITION = keccak256("v4.pos.diamond.storage");
    bytes32 public constant TREE_STORAGE_POSITION = keccak256("v4.tree.diamond.storage");
    bytes32 public constant TICKTABLE_STORAGE_POSITION = keccak256("v4.ticktable.diamond.storage");
    bytes32 public constant XTBP_STORAGE_POSITION = keccak256("v4.xtbp.diamond.storage");
    bytes32 public constant YTBP_STORAGE_POSITION = keccak256("v4.ytbp.diamond.storage");
    bytes32 public constant INTERNAL_BORROWER_STORAGE_POSITION = keccak256("v4.internalborrower.diamond.storage");

    /// Load the semantically immutable informational fields for this AMM.
    /// @dev we may consider moving this to another file since it is used beyond just swaps.
    function info() internal pure returns (InfoStorage storage iis) {
        bytes32 position = INFO_STORAGE_POSITION;
        assembly {
            iis.slot := position
        }
    }

    /// Load the bidAsk struct for exploit prevention.
    function bidAsk() internal pure returns (BidAsk storage bas) {
        bytes32 position = BIDASK_STORAGE_POSITION;
        assembly {
            bas.slot := position
        }
    }

    /* Mostly used by Liq */

    /// Where our assets are tracked
    function assetBook() internal pure returns (AssetBook storage aBook) {
        bytes32 position = POS_STORAGE_POSITION;
        assembly {
            aBook.slot := position
        }
    }

    /// Where liquidity and borrow fees are tracked.
    function tree() internal pure returns (LiqTree storage lTree) {
        bytes32 position = TREE_STORAGE_POSITION;
        assembly {
            lTree.slot := position
        }
    }

    /// Where tick information is stored for swapping.
    function table() internal pure returns (TickTable storage tab) {
        bytes32 position = TICKTABLE_STORAGE_POSITION;
        assembly {
            tab.slot := position
        }
    }

    /// Fetches the Taker Borrow Pool for the x token.
    function xTBP() internal pure returns (TBP storage tbp) {
        bytes32 position = XTBP_STORAGE_POSITION;
        assembly {
            tbp.slot := position
        }
    }

    /// Fetches the Taker Borrow Pool for the y token.
    function yTBP() internal pure returns (TBP storage tbp) {
        bytes32 position = YTBP_STORAGE_POSITION;
        assembly {
            tbp.slot := position
        }
    }

    /// An internal notion of the borrow rate based on liquidity.
    function IBR() internal pure returns (InternalBorrower storage iborrower) {
        bytes32 position = INTERNAL_BORROWER_STORAGE_POSITION;
        assembly {
            iborrower.slot := position
        }
    }
}

/**
 * @notice Storage specific to the Swap.
 * The swap storage is separate because it has special store and load functions
 * that are specific to how it operates.
 */
library SwapStorageLib {
    bytes32 public constant SWAP_STORAGE_POSITION = keccak256("v4.swap.diamond.storage");

    /// Load swap relevant data.
    /// @dev We aren't guaranteed that functions get inlined so we'll redundantly write these stubs for now.
    function load() internal pure returns (SwapStorage storage ss) {
        bytes32 position = SWAP_STORAGE_POSITION;
        assembly {
            ss.slot := position
        }
    }

    /// Write back swap relevant data.
    /// @dev for now we do it field by field, but we can explore more clever ways of writing
    /// back slots into storage that are field agnostic.
    function store(SwapStorage memory sCache) internal {
        SwapStorage storage ss = load();
        // These two fields could be written back with one SSTORE if we can figure out the assembly
        // to do it.
        ss.mLiq = sCache.mLiq;
        ss.tLiq = sCache.tLiq;

        ss.sqrtP = sCache.sqrtP;
    }
}

struct SwapStorage {
    uint128 mLiq;
    uint128 tLiq;

    // The price of the pool. Swapping changes this price.
    Price sqrtP; // 160 bits

    /*
      We could store the TableIndex so the LiqFacets can use it without
      computing it every time.
      We choose not to because we would either store:
      1. The TableIndex the swap last landed on.
      2. The TableIndex corresponding to the current price.
      These are NOT the same.

      1. can be a tick well below 2. 1. is either an initialized tick
      or the furthest tick we searched. Adding liquidiy can change which
      tick is the largest initialized tick below the current sqrtP. Thus
      storing 1. is unreliable.

      2. must be computed at the end of the swap for around ~3000 gas (Price to Tick)
      and stored for another ~5000 gas and then read for 2100 gas. Ultimately
      what we need to know for the LiqFacets is where the current price is relative
      to a range. It is cheaper to convert two tableIndex's (the range) into
      prices to do the comparison (< 1000 gas each) than to even do the read.
      Thus we avoid ever computing the current TableIndex and always use the sqrt price
      outside of modifying the TickTable and LiquidityTree.
    */
}

/// The fee lib also has its own storage lib because its load and store are
/// unique to the fee collector
library FeeStorageLib {
    bytes32 public constant FEE_STORAGE_POSITION = keccak256("v4.fee.diamond.storage");

    // This is the number of slots the storage type takes up (struct byte size / 32)
    // CAREFUL: This needs to be updated when the storage type changes because the Solidity compiler
    // doesn't currently expose struct sizes.
    // TODO : Currently not used since we don't have an optimized store.
    // uint256 constant NUM_SLOTS = 9;

    function load() internal pure returns (FeeCollector storage fs) {
        bytes32 position = FEE_STORAGE_POSITION;
        assembly {
            fs.slot := position
        }
    }

    /// A custom storage function for writing back FeeCollector values to storage.
    /// This is meant for conventional use AFTER initialization and will not initialize variables
    /// that are semantically immutable.
    /// @dev We only write back certain variables because members like the FeeCal are expected to
    /// not change during the lifetime of this contract.
    /// TODO explore ways of storing the entire struct back without going entry by entry.
    /// see below for example code.
    function store(FeeCollector memory fCache) internal {
        FeeCollector storage stored = load();
        stored.protocolOwnedX = fCache.protocolOwnedX;
        stored.protocolOwnedY = fCache.protocolOwnedY;
        stored.globalFeeRateAccumX128 = fCache.globalFeeRateAccumX128;
    }

    // One day we can explore doing something like this to avoid using multiple SSTORES
    // for variables that share the same slot in memory.
    // bytes32 position = FEE_STORAGE_POSITION;
    // for (uint256 i = 0; i < NUM_SLOTS; ++i) {
    //     assembly ("memory-safe") {
    //         let loaded := mload(add(fCache, i))
    //         sstore(add(position, i), loaded)
    //     }
    // }
}
/* solhint-enable */

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

interface IPoolLens {

    /// Return the pair of tokens this pool swaps.
    /// @return tokenX The risk asset of this pool, the numerator of the price.
    /// @return tokenY The numeraire of this pool, the denominator of the price.
    function getTokenPair() external view returns (address tokenX, address tokenY);

    /// Get the current sqrt price of the pool.
    /// @return sqrtPriceX96 The price is returned as its square root value as an X96 number.
    function getCurrentSqrtPrice() external view returns (uint160 sqrtPriceX96);

    /// Get the PortfolioManager for this pool.
    function getPM() external view returns (address PM);

    /// Get the TableIndex that corresponds to the current price.
    function getCurrentTableIndex() external view returns (int24 tableIndex);

    /// Get the current bid ask for this block.
    function getBidAsk() external view returns (uint160 bidSqrtX96, uint160 askSqrtX96);

    /// Returns the spacing used in the Tick Table.
    /// This lets users compute their table index offline.
    function getTickSpacing() external view returns (uint24 spacing);

    /// Get the corresponding table index for a given price.
    function getTableIndex(uint160 sqrtPriceX96) external view returns (int24 tableIndex);

    /// Get the corresponding price for a given Table Index
    function getSqrtPrice(int24 tableIndex) external view returns (uint160 sqrtPriceX96);

    /* Liquidity */

    /// Get the liquidity values we're currently swapping with in our tick.
    function getCurrentLiqs() external view returns (uint128 mLiq, uint128 tLiq);

    /// Get the liquidity deltas for a given table index.
    function getTableDelta(int24 tableIndex) external view returns (int128 mDelta, int128 tDelta);

    /// Get the liquidity deltas for a contiguous range of TableIndex's
    /// @param lowIndex The table index of the lowest tick we fetch deltas for. The lower bound is inclusive.
    /// @param highIndex The first table index above lowIndex we don't fetch deltas for. The high bound is exclusive.
    /// @return mLiqs An array of mLiq deltas starting from the lowIndex up to the highIndex.
    /// @return tLiqs An array of tLiq deltas starting from the lowIndex up tot he highIndex.
    function getTableDeltas(int24 lowIndex, int24 highIndex)
    external view returns (int128[] memory mLiqs, int128[] memory tLiqs);

    /* Tick Traversal */

    /// Get the next utilized table index above the given table index.
    /// @return exists Whether a next utilized table index exists or not in the table's search range.
    /// @return nextTable The next utilized table index, or the last search one if it doesn't exist.
    function getNextActiveTableIndex(int24 tableIndex) external view returns (bool exists, int24 nextTable);

    /// Get the prev utilized table index above the given table index.
    /// @return exists Whether a previous utilized table index exists or not in the table's search range.
    /// @return prevTable The previous utilized table index, or the last search one if it doesn't exist.
    function getPrevActiveTableIndex(int24 tableIndex) external view returns (bool exists, int24 prevTable);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

import { IERC20Minimal } from "../ERC/interfaces/IERC20Minimal.sol";
import { ContractLib } from "./Contract.sol";

type Token is address;

library TokenImpl {
    error TokenBalanceInvalid();
    error TokenTransferFailure();

    /// Wrap an address into a Token and verify it's a contract.
    // @dev It's important to verify addr is a contract before we
    // transfer to it or else it will be a false success.
    function make(address _addr) internal view returns (Token) {
        ContractLib.assertContract(_addr);
        return Token.wrap(_addr);
    }

    /// Unwrap into an address
    function addr(Token self) internal pure returns (address) {
        return Token.unwrap(self);
    }

    /// Query the balance of this token for the caller.
    function balance(Token self) internal view returns (uint256) {
        (bool success, bytes memory data) =
            addr(self).staticcall(abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, address(this)));
        if (!(success && data.length >= 32)) {
            revert TokenBalanceInvalid();
        }
        return abi.decode(data, (uint256));
    }

    /// Transfer this token from caller to recipient.
    function transfer(Token self, address recipient, uint256 amount) internal {
        if (amount == 0) return; // Short circuit

        (bool success, bytes memory data) =
            addr(self).call(abi.encodeWithSelector(IERC20Minimal.transfer.selector, recipient, amount));
        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) {
            revert TokenTransferFailure();
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

type TickIndex is int24;
type Price is uint160; // Price is a 64X96 value.

/// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128.
/// Tick indices are inclusive of the min tick.
int24 constant MIN_TICK = -887272;
/// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
/// Tick indices are inclusive of the max tick.
int24 constant MAX_TICK = -MIN_TICK;
int24 constant NUM_TICKS = MAX_TICK - MIN_TICK;

/// @dev The minimum sqrt price we can have. Equivalent to toSqrtPrice(MIN_TICK). Inclusive.
uint160 constant MIN_SQRT_RATIO = 4295128739;
/// @dev The maximum sqrt price we can have. Equivalent to toSqrtPrice(MAX_TICK). Inclusive.
uint160 constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

/// @dev Price versions of the above.
Price constant MIN_PRICE = Price.wrap(MIN_SQRT_RATIO);
Price constant MAX_PRICE = Price.wrap(MAX_SQRT_RATIO);

library TickLib {
    /// How to create a TickIndex for user facing functions
    function newTickIndex(int24 num) public pure returns (TickIndex res) {
        res = TickIndex.wrap(num);
        TickIndexImpl.validate(res);
    }
}

/**
 * @title TickIndex utilities and primarily tick to price conversions
 * @author UniswapV3 (https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/TickMath.sol)
 * @notice Converts between square root of price and TickIndex for prices in the range of 2^-128 to 2^128.
 * Essentially Uniswap's GPL implementation of TickMath with very minor edits.
 **/
library TickIndexImpl {
    error TickIndexOutOfBounds();

    /// Ensure the tick index is in range.
    function validate(TickIndex ti) internal pure {
        int24 num = TickIndex.unwrap(ti);
        if (num > MAX_TICK || num < MIN_TICK) {
            revert TickIndexOutOfBounds();
        }
    }

    /// @notice Returns if the TickIndex is within the given range
    /// @dev This is inclusive on the lower end, and exclusive on the upper end like all Tick operations.
    function inRange(TickIndex self, TickIndex lower, TickIndex upper) internal pure returns (bool) {
        int24 num = TickIndex.unwrap(self);
        return (TickIndex.unwrap(lower) <= num) && (num < TickIndex.unwrap(upper));
    }

    /// Clamp tick index to be within range.
    function clamp(TickIndex self) internal pure returns (TickIndex) {
        int24 ti = TickIndex.unwrap(self);
        if (ti < MIN_TICK)
            return TickIndex.wrap(MIN_TICK);
        else if (ti > MAX_TICK)
            return TickIndex.wrap(MAX_TICK);
        else
            return self;
    }

    /// Decrements the TickIndex by 1
    function dec(TickIndex ti) internal pure returns (TickIndex) {
        int24 num = TickIndex.unwrap(ti);
        require(num > MIN_TICK);
        unchecked { return TickIndex.wrap(num - 1); }
    }

    /// Increments the TickIndex by 1
    function inc(TickIndex ti) internal pure returns (TickIndex) {
        int24 num = TickIndex.unwrap(ti);
        require(num < MAX_TICK);
        unchecked { return TickIndex.wrap(num + 1); }
    }

    /* Comparisons */

    /// Returns if self is less than other.
    function isLT(TickIndex self, TickIndex other) internal pure returns (bool) {
        return TickIndex.unwrap(self) < TickIndex.unwrap(other);
    }

    function isEq(TickIndex self, TickIndex other) internal pure returns (bool) {
        return TickIndex.unwrap(self) == TickIndex.unwrap(other);
    }


    /**
     * @notice Calculates sqrt(1.0001^tick) * 2^96
     * @dev Throws if |tick| > max tick
     * @param ti TickIndex wrapping a tick representing the price as 1.0001^tick.
     * @return sqrtP A Q64.96 representation of the sqrt of the price represented by the given tick.
     **/
    function toSqrtPrice(TickIndex ti) internal pure returns (Price sqrtP) {
        uint160 sqrtPriceX96;
        int256 tick = int256(TickIndex.unwrap(ti));
        uint256 absTick = tick < 0 ? uint256(-tick) : uint256(tick);
        require(absTick <= uint256(int256(MAX_TICK)), "TickIndexImpl:SqrtMax");

        // We first handle it as if it were a negative index to allow a later trick for the reciprocal.
        // Iteratively multiply by the precomputed Q128.128 of 1.0001 to various negative powers
        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        // Get the reciprocal if the index was positive.
        if (tick > 0) ratio = type(uint256).max / ratio;

        // This divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        unchecked { sqrtPriceX96 = uint160((ratio >> 32) + (uint32(ratio) == 0 ? 0 : 1)); }
        sqrtP = Price.wrap(sqrtPriceX96);
    }

    /**
     * @notice Calculates sqrt(1.0001^-tick) * 2^96
     * @dev Calls into toSqrtPrice. Not currently used.
     **/
    function toRecipSqrtPrice(TickIndex ti) internal pure returns (Price sqrtRecip) {
        TickIndex inv = TickIndex.wrap(-TickIndex.unwrap(ti));
        sqrtRecip = toSqrtPrice(inv);
        // This is surprisingly equally accurate afaik.
        // sqrtPriceX96 = uint160((1<< 192) / uint256(toSqrtPrice(ti)));
    }
}

library PriceImpl {
    function unwrap(Price self) internal pure returns (uint160) {
        return Price.unwrap(self);
    }

    /* Comparison functions */
    function eq(Price self, Price other) internal pure returns (bool) {
        return Price.unwrap(self) == Price.unwrap(other);
    }

    function gt(Price self, Price other) internal pure returns (bool) {
        return Price.unwrap(self) > Price.unwrap(other);
    }

    function gteq(Price self, Price other) internal pure returns (bool) {
        return Price.unwrap(self) >= Price.unwrap(other);
    }

    function lt(Price self, Price other) internal pure returns (bool) {
        return Price.unwrap(self) < Price.unwrap(other);
    }

    function lteq(Price self, Price other) internal pure returns (bool) {
        return Price.unwrap(self) <= Price.unwrap(other);
    }

    function max(Price self, Price other) internal pure returns (Price) {
        return unwrap(self) > unwrap(other) ? self : other;
    }
}

library SqrtPriceLib {
    error PriceOutOfBounds(uint160 sqrtPX96);

    function make(uint160 sqrtPX96) internal pure returns (Price sqrtP) {
        if (sqrtPX96 < MIN_SQRT_RATIO || MAX_SQRT_RATIO < sqrtPX96) {
            revert PriceOutOfBounds(sqrtPX96);
        }
        return Price.wrap(sqrtPX96);
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtP A Q64.96 value representing the sqrt of the tick's price.
    /// @return ti The greatest tick whose price is less than or equal to the input price.
    function toTick(Price sqrtP) internal pure returns (TickIndex ti) {
        uint160 sqrtPriceX96 = Price.unwrap(sqrtP);
        // I believe the Uni requirement that sqrtPriceX96 < MAX_SQRT_RATIO is incorrect.
        // The toSqrtPrice function clearly goes to MAX_SQRT_RATIO.
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 <= MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        unchecked {
        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        int24 tick = (tickLow == tickHi ?
                      tickLow :
                      (Price.unwrap(TickIndexImpl.toSqrtPrice(TickIndex.wrap(tickHi))) <= sqrtPriceX96 ?
                       tickHi : tickLow));
        ti = TickIndex.wrap(tick);
        TickIndexImpl.validate(ti);
        }
    }

    /// Determine if a price is within the range we operate the AMM in.
    function isValid(Price self) internal pure returns (bool) {
        uint160 num = Price.unwrap(self);
        return  MIN_SQRT_RATIO <= num && num < MAX_SQRT_RATIO;
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { Price, PriceImpl } from "Ticks/Tick.sol";
import { FullMath } from "Math/FullMath.sol";

/// Stores the within-block bid and ask.
/// @dev 2 slots
struct BidAsk {
    // @TODO (terence): Change this appropriately for L2 blocks.
    // The block number this bidask applies to.
    uint64 blockNum;

    Price bidSP;
    Price askSP;
}


/// BidAsk is used to prevent sandwich attacks and repetitive burn attacks.
/// Previous swaps within the same block set the bid and ask.
/// The Bid is the lowest price swapped to in this block and the ask is the highest
/// price swapped to within the current block.
library BidAskImpl {
    using PriceImpl for Price;

    /// Fetch the effective bid price.
    /// @param sqrtP The current swap price. Used at the start of a new block.
    function getBid(BidAsk storage self, Price sqrtP) internal returns (Price bid) {
        uint64 newBlock = uint64(block.number);
        // If this is the first swap in this block, the bid and ask don't apply yet.
        if (newBlock != self.blockNum) {
            self.blockNum = newBlock;
            self.bidSP = sqrtP;
            self.askSP = sqrtP;
            return sqrtP;
        } else {
            return self.bidSP;
        }
    }

    /// Fetch the effective Ask price.
    /// @param sqrtP The current swap price. Used at the start of a new block.
    function getAsk(BidAsk storage self, Price sqrtP) internal returns (Price ask) {
        uint64 newBlock = uint64(block.number);
        // If this is the first swap in this block, the bid and ask don't apply yet.
        if (newBlock != self.blockNum) {
            self.blockNum = newBlock;
            self.bidSP = sqrtP;
            self.askSP = sqrtP;
            return sqrtP;
        } else {
            return self.askSP;
        }
    }

    /// Fetch the effective bid price without modifying storage.
    /// Used in place of getBid when calling from simSwap.
    function dryGetBid(BidAsk storage self, Price sqrtP) internal view returns (Price bid) {
        uint64 newBlock = uint64(block.number);
        if (newBlock != self.blockNum) {
            return sqrtP;
        } else {
            return self.bidSP;
        }
    }

    /// Fetch the effective bid price without modifying storage.
    /// Used in place of getBid when calling from simSwap.
    function dryGetAsk(BidAsk storage self, Price sqrtP) internal view returns (Price ask) {
        uint64 newBlock = uint64(block.number);
        if (newBlock != self.blockNum) {
            return sqrtP;
        } else {
            return self.askSP;
        }
    }

    /// After a sell swap, we set the bid to the new price if its lower.
    function storePostSwapBid(
        BidAsk storage self,
        Price postSP
    ) internal {
        if (postSP.lt(self.bidSP)) {
            self.bidSP = postSP;
        }
    }

    /// After a sell swap, we set the bid to the new price if its greater.
    function storePostSwapAsk(
        BidAsk storage self,
        Price postSP
    ) internal {
        if (postSP.gt(self.askSP)) {
            self.askSP = postSP;
        }
    }
}

/// Helpers for working with BidAsk results.
library BidAskLib {
    /// Calculate the y we should return to a user as if they
    /// sold their entire x at the given price.
    /// @param x The input swap size which we require to be limited to 128 bits
    /// as swap inputs are.
    /// @dev Computing x * sp = y
    function sell(
        Price sp, uint256 x
    ) internal pure returns (uint256 y) {
        uint160 spX96 = Price.unwrap(sp);
        (uint256 bot, uint256 top) = FullMath.mul512(spX96, spX96); // 320 used bits, X192

        // At most 64 bits are used in top. Let's shift in those 64 bits and drop to X128.
        uint256 pX128 = (bot >> 64) + (top << 192);

        (bot, top) = FullMath.mul512(x, pX128);
        // Drop the X128 and shift in top's 128 bits.
        y = (bot >> 128) + (top << 128);

        // We know the result fits if the input is limited to 128 bits.
    }

    /// Calculate the x we should return to a user as if they
    /// bought their entire y at the given price.
    /// @param y The input swap size which we require to be limited to 128 bits
    /// as swap inputs are.
    /// @dev Computing y / sp = x
    function buy(
        Price sp, uint256 y
    ) internal pure returns (uint256 x) {
        uint160 spX96 = Price.unwrap(sp);
        (uint256 bot, uint256 top) = FullMath.mul512(spX96, spX96); // 320 used bits, X192

        // At most 64 bits are used in top. Let's shift in those 64 bits and drop to X128.
        uint256 pX128 = (bot >> 64) + (top << 192);

        // We know y is at most 128 bits so this fits
        x = (y << 128) / pX128;
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

type TableIndex is int24;

/**
 * @title TableIndexImpl
 * @notice TickTable type implementation. Make clear how we access tables.
 * @dev TableIndex is just the Tick Index divided by spacing and rounded down.
 **/
library TableIndexImpl {
    // Split into the two ints used to access the bitmap.
    function split(TableIndex bi) internal pure returns(int16 top, uint8 bot) {
        int24 i = TableIndex.unwrap(bi);
        top = int16(i >> 8);
        bot = uint8(int8(i));
    }

    /// @notice Increment by 1
    /// @dev unchecked is a little dangerous here since we may go over the theoretical max TableIndex.
    /// We don't actually store the Table Index bounds anywhere. They are just the tick index bounds divided
    /// by spacing. We make sure to check tick index bounds to avoid this issue. Table indices going out of bounds
    /// doesn't fundamentally break anything.
    function inc(TableIndex bi) internal pure returns(TableIndex) {
        unchecked { return TableIndex.wrap(TableIndex.unwrap(bi) + 1); }
    }

    /// @notice Decrement by 1
    /// @dev unchecked is a little dangerous here since we may go below the theoretical min TableIndex.
    /// We don't actually store the Table Index bounds anywhere. They are just the tick index bounds divided
    /// by spacing. We make sure to check tick index bounds to avoid this issue. Table indices going out of bounds
    /// doesn't fundamentally break anything.
    function dec(TableIndex bi) internal pure returns(TableIndex) {
        unchecked { return TableIndex.wrap(TableIndex.unwrap(bi) - 1); }
    }

    function isLT(TableIndex self, TableIndex other) internal pure returns(bool) {
        return TableIndex.unwrap(self) < TableIndex.unwrap(other);
    }

    function isEq(TableIndex self, TableIndex other) internal pure returns(bool) {
        return TableIndex.unwrap(self) == TableIndex.unwrap(other);
    }

    function isLTE(TableIndex self, TableIndex other) internal pure returns (bool) {
        return TableIndex.unwrap(self) <= TableIndex.unwrap(other);
    }
}

/// The Inverse of TableIndexImpl.split. Free function since it can't be in the library.
function TableIndexJoin(int16 top, uint8 bot) pure returns(TableIndex) {
    unchecked { return TableIndex.wrap(int24((uint24(uint16(top)) << 8) + bot)); }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { MIN_TICK, MAX_TICK, TickIndex } from "Ticks/Tick.sol";
import { TableIndex, TableIndexImpl, TableIndexJoin } from "Ticks/Table.sol";
import { Bitmap, BitmapImpl } from "Ticks/Bitmap.sol";
import { TickData } from "Ticks/Data.sol";

struct TickTable {
    /// Mapping from ticks to TickData
    /// @dev We use mapping instead of a fixed array here so that we can extend the TickData type.
    mapping(TableIndex => TickData) table;

    /// Map from table indices to a bitmap of which ticks are initialized.
    /// @dev TODO: we can consider switching this to a fixed array to save gas.
    mapping(int16 => Bitmap) bitmaps;

    /// @notice The tick spacing used. Aka the divisor for ticks to table indices.
    /// @dev Would like to make this immutable but with a struct it's all or nothing.
    /// A int despite always being positive to reduce casts in the math.
    int24 spacing;
}


/**
 * @title TickTableImpl
 * @author Terence An
 * @notice TickTable type implementation. Manages Tick interactions.
 * @custom:security High
 **/
library TickTableImpl {
    using BitmapImpl for Bitmap;
    using TableIndexImpl for TableIndex;

    error UnspacedTickIndex(int24 spacing, int24 tick);
    error TableIndexOutOfBounds(int24 spacing, int24 tableIndex);
    /*
      The MAX_TOP and MIN_TOP are gross overestimates of the bounds. They're only present in the event
      that something has catastrophically gone wrong. Instead bounds checking should happen at the
      TickIndex level.
    */

    /// Highest the top 16 bits the TableIndex can be. Overestimates by a factor of "spacing". Inclusive.
    /// Note this is inclusive while MAX_TICK is not.
    int16 constant MAX_TOP = int16(MAX_TICK >> 8);

    /// Lowest the top 16 bits the TableIndex can be. Overestimates by a factor of "spacing". Inclusive.
    int16 constant MIN_TOP = int16(MIN_TICK >> 8);

    /// The number of bitmaps to search for the subsequent initialized tick. Currently set to 4 which is roughly
    /// an 11% slippage in price which should be more than reasonable.
    int16 constant SUBSEQUENT_TOPS = 4;


    /* TableIndex conversion functions */

    /// Convert TickIndex to the index we use to fetch TickData. The bitmap's "table index".
    function getTableIndex(TickTable storage self, TickIndex ti) internal view returns(TableIndex) {
        int24 tick = TickIndex.unwrap(ti);
        if (tick < 0) {
            // Solidity rounds negative numbers towards 0.
            unchecked { return TableIndex.wrap(((tick + 1) / self.spacing) - 1); }
        } else {
            return TableIndex.wrap(tick / self.spacing);
        }
    }

    function getTickIndex(TickTable storage self, TableIndex bi) internal view returns (TickIndex) {
        unchecked { return TickIndex.wrap(TableIndex.unwrap(bi) * self.spacing); }
    }

    function makeTableIndex(TickTable storage self, int24 raw) internal view returns (TableIndex bi) {
        bi = TableIndex.wrap(raw);
        validateTableIndexBounds(self, bi);
    }

    function validateTickIndexSpacing(TickTable storage self, TickIndex ti) internal view {
        if (TickIndex.unwrap(ti) % self.spacing != 0)
            revert UnspacedTickIndex(self.spacing, TickIndex.unwrap(ti));
    }

    function validateTableIndexBounds(TickTable storage self, TableIndex bi) internal view {
        int24 tick = TableIndex.unwrap(bi) * self.spacing;
        if (tick < MIN_TICK || MAX_TICK <= tick)
            revert TableIndexOutOfBounds(self.spacing, TableIndex.unwrap(bi));
    }

    /* Bitmaps-only table iteration functions */

    /// @notice Get the table index of the next initialized tick.
    /// @dev It is cheaper to iterate in TableIndex and avoids rounding ambiguity.
    function getNextTableIndex(TickTable storage self, TableIndex bi) internal view returns (bool, TableIndex) {
        return getAtOrNextTableIndex(self, bi.inc());
    }

    /// @notice Workhorse for getting next tick
    /// @dev At most search a fixed number of subsequent bitmaps before giving up.
    /// @return exists Indicator if a next initialized tick exists.
    /// @return next The next table index greater than or equal to the given one if found. If not, the max index searched.
    function getAtOrNextTableIndex(TickTable storage self, TableIndex bi) internal view returns(bool exists, TableIndex next) {
        (int16 top, uint8 bot) = bi.split();
        // Search initial bitmap
        (bool found, uint8 nextBot) = self.bitmaps[top].getAtOrNext(bot);
        if (found) {
            return (true, TableIndexJoin(top, nextBot));
        }

        // Search all subsequent bitmaps
        int16 maxTop = top + SUBSEQUENT_TOPS;
        unchecked {
        for (int16 i = top + 1; i <= maxTop && i <= MAX_TOP; ++i) {
            (found, nextBot) = self.bitmaps[i].getAtOrNext(0);
            if (found) {
                return (true, TableIndexJoin(i, nextBot));
            }
        }

        // No next tick found
        return (false, TableIndexJoin(maxTop, type(uint8).max));
        }
    }

    /// @notice Get the table index of the previous initialized tick.
    /// @dev It is cheaper to iterate in TableIndex and avoids rounding ambiguity.
    function getPrevTableIndex(TickTable storage self, TableIndex bi) internal view returns(bool, TableIndex) {
        return getAtOrPrevTableIndex(self, bi.dec());
    }

    /// @notice Workhorse for getting prev tick
    /// @dev At most search a fixed number of subsequent bitmaps before giving up.
    /// @return exists Indicator if a prev initialized tick exists.
    /// @return next The prev table index less than or equal to the given one if found. If not, the min index searched.
    function getAtOrPrevTableIndex(TickTable storage self, TableIndex bi) internal view returns(bool exists, TableIndex next) {
        (int16 top, uint8 bot) = bi.split();
        // Search initial bitmap
        (bool found, uint8 prevBot) = self.bitmaps[top].getAtOrPrev(bot);
        if (found) {
            return (true, TableIndexJoin(top, prevBot));
        }

        // Search 4 subsequent bitmaps
        int16 minTop = top - SUBSEQUENT_TOPS;
        unchecked {
        for (int16 i = top - 1; i >= minTop && i >= MIN_TOP; --i) {
            (found, prevBot) = self.bitmaps[i].getAtOrPrev(type(uint8).max);
            if (found) {
                return (true, TableIndexJoin(i, prevBot));
            }
        }

        // No next tick exists
        return (false, TableIndexJoin(minTop, 0));
        }
    }

    /* Table interacting functions */

    /// First convert your TickIndex to a TableIndex to then fetch TickData here.
    function getData(TickTable storage self, TableIndex bi) internal view returns(TickData storage) {
        return self.table[bi];
    }

    /* Bitmap interaction functions */

    /// Sets the bit in the TickTable bitmap to indicate the index has data.
    /// This allows the get{Next,Prev} TableIndex iteration functions to find this TableIndex.
    function setBit(TickTable storage self, TableIndex bi) internal {
        (int16 top, uint8 bot) = bi.split();
        self.bitmaps[top].trySet(bot);
    }

    /// Clears the bit in the TickTable bitmap to indicate the index has no data to inspect.
    /// This removes this index from the result of the get{Next,Prev} TableIndex iteration functions to.
    function clearBit(TickTable storage self, TableIndex bi) internal {
        (int16 top, uint8 bot) = bi.split();
        self.bitmaps[top].clear(bot);
    }

    /// Indicates if a bit in the TickTable bitmap is set and the Tick is initialized or not.
    function isSet(TickTable storage self, TableIndex bi) internal view returns (bool) {
        (int16 top, uint8 bot) = bi.split();
        return self.bitmaps[top].isSet(bot);
    }

    /// TODO: REVISIT THIS. MAYBE WE CAN DELETE OR RELEGATE TO TESTING.
    /// @notice Save the given TickData at the given table index.
    /// @dev CAUTION. Always only add one reference to the data at time before saving. Saving multiple new
    /// references will cause the bitmaps entry to remain blank.
    /// This used to work by saving memory to storage, that way is safer but in theory more gas costly.
    /// We should revisit this.
    /// @param data We don't need this param but we always have the data pointer when calling this function
    /// so just provide the argument to save us a separate lookup.
    function ensureBitmap(TickTable storage self, TableIndex bi, TickData storage data) internal {
        if (data.refCount == 0) {
            // Deleting this entry.
            require(data.mLiqDelta == 0);
            require(data.tLiqDelta == 0);
            (int16 top, uint8 bot) = bi.split();
            self.bitmaps[top].clear(bot);
        } else if (data.refCount == 1) {
            // Doesn't matter if the ref count went up or down to 1.
            // As a gas compromise we don't check storage, just set the bitmap anyways.
            // BE VERY CAREFUL HERE. WE ASSUME SAVES HAPPEN INCREMENTALLY.
            // I.e. if you add two references and then save, the bitmap will not be set.
            (int16 top, uint8 bot) = bi.split();
            self.bitmaps[top].trySet(bot);
        }
    }

    /// Utility function for testing convenience.
    /// @dev Uses an in-memory TickData since it's testing.
    function saveData(TickTable storage self, TableIndex bi, TickData memory memData) internal {
        self.table[bi] = memData;
        TickData storage data = self.table[bi];
        ensureBitmap(self, bi, data);
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { TableIndex, TableIndexImpl } from "Ticks/Table.sol";
import { FeeRateAccumulator, FeeRateAccumulatorImpl } from "Fee/Fees.sol";
import { SwapStorage } from "../../src/Storage.sol";
import { U128Ops } from "Math/Ops.sol";


/// @notice The information stored at each tick
/// @dev Each TickData belongs to the lower price of its range.
struct TickData {
    /// Change in Maker liquidity when crossing into this tick from the left.
    int128 mLiqDelta;
    /// Change in Taker liquidity when crossing into this tick from the left.
    int128 tLiqDelta;

    /// The total number of maker and taker positions that reference this tick.
    /// Used to clear ticks that we no longer have to iterate through
    uint128 refCount;

    /// @notice The cumulative fee rate owed to Makers and by Takers for the non-active side.
    /// @dev IMPORTANT! Notice that this value does not need initialization. This is important to understand.
    /// First you should understand the outside/inside fee mechanics and then read below.
    /// Given any tick, we can denote two values, a and b. a + b = F where F is the total number of fees collected
    /// so far. Regardless of the initial values of a and b, as long a + b = F is true for all ticks, and b increases
    /// when F increases while the price is below the tick and a increases with F while the price is above the tick
    /// then the values we use to compute regional fees, a2-a1, b1-b2, F-a1-b2, can be used for checkpointing fees.
    FeeRateAccumulator outsideFeeRateAccumX128;

    //TODO: Add token rewards.
    //TODO: Determine if we need the extra Uniswap Tick.Info members.
}


/**
 * @notice Methods for interacting with TickData. Correct use is up to the user.
 **/
library TickDataImpl {
    using FeeRateAccumulatorImpl for FeeRateAccumulator;
    using TableIndexImpl for TableIndex;

    /***********************
     * Liquidity Utilities *
     ***********************/

    /// @dev Note that even if we add to an uninitialized tick, we assume the fees are all accumulated inside
    /// so we avoid initializing the outsideFee variables. We do however return information for the table to
    /// @return isNew Indicates to the caller this is a tick with new data.
    /// This should be reported to the TickTable bookkeeping.
    function addMakerLiq(TickData storage data, int128 liq) internal returns (bool isNew) {
        data.mLiqDelta += liq;
        uint128 refs = data.refCount;
        isNew = refs == 0;
        data.refCount = refs + 1;
    }

    /// @return isNew Indicates to the caller this is a tick with new data.
    /// This should be reported to the TickTable bookkeeping.
    function addTakerLiq(TickData storage data, int128 liq) internal returns (bool isNew) {
        data.tLiqDelta += liq;
        uint128 refs = data.refCount;
        isNew = refs == 0;
        data.refCount = refs + 1;
    }

    /// @return isEmpty Indicates to the caller this tick now has no data and should be cleared
    /// in the TickTable bookkeeping.
    function removeMakerLiq(TickData storage data, int128 liq) internal returns (bool isEmpty) {
        // Will revert on over/underflow;
        data.mLiqDelta -= liq;
        uint128 refs = data.refCount;
        isEmpty = refs == 1;
        data.refCount = refs - 1;
    }

    /// @return isEmpty Indicates to the caller this tick now has no data and should be cleared
    /// in the TickTable bookkeeping.
    function removeTakerLiq(TickData storage data, int128 liq) internal returns (bool isEmpty) {
        data.tLiqDelta -= liq;
        uint128 refs = data.refCount;
        isEmpty = refs == 1;
        data.refCount = refs - 1;
    }

    /// Increment the refCount of this tick. This is only used in the scenario where a position
    /// using this tick is split into two. Liquidity numbers don't have to change.
    /// @dev This TickData cannot possibly be new.
    function incRefCount(TickData storage data) internal {
        data.refCount += 1;
    }

    /******************
     * Swap Utilities *
     ******************/

    /// Update state and tick when crossing into this tick.
    function crossInto(
        TickData storage data,
        SwapStorage memory swapStore,
        FeeRateAccumulator memory globalAccumX128
    ) internal {
        data.outsideFeeRateAccumX128.subFrom(globalAccumX128);
        swapStore.mLiq = U128Ops.add(swapStore.mLiq, data.mLiqDelta);
        swapStore.tLiq = U128Ops.add(swapStore.tLiq, data.tLiqDelta);
    }

    /// Update state and tick when crossing out of this tick.
    function crossOutOf(
        TickData storage data,
        SwapStorage memory swapStore,
        FeeRateAccumulator memory globalAccumX128
    ) internal {
        data.outsideFeeRateAccumX128.subFrom(globalAccumX128);
        swapStore.mLiq = U128Ops.sub(swapStore.mLiq, data.mLiqDelta);
        swapStore.tLiq = U128Ops.sub(swapStore.tLiq, data.tLiqDelta);
    }

    /// Update swap liquidity but don't modify the tick's storage.
    /// Used for simulated swaps.
    function dryCrossInto(
        TickData storage data,
        SwapStorage memory swapStore
    ) internal view {
        swapStore.mLiq = U128Ops.add(swapStore.mLiq, data.mLiqDelta);
        swapStore.tLiq = U128Ops.add(swapStore.tLiq, data.tLiqDelta);
    }

    /// Update swap liquidity but don't modify the tick's storage.
    /// Used for simulated swaps.
    function dryCrossOutOf(
        TickData storage data,
        SwapStorage memory swapStore
    ) internal view {
        swapStore.mLiq = U128Ops.sub(swapStore.mLiq, data.mLiqDelta);
        swapStore.tLiq = U128Ops.sub(swapStore.tLiq, data.tLiqDelta);
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { Price } from "Ticks/Tick.sol";
import { TableIndex, TableIndexImpl } from "Ticks/Table.sol";
import { TickTable } from "Ticks/TickTable.sol";
import { TableFeeLib } from "Fee/Table.sol";
import { FeeCollector, FeeRateAccumulator } from "Fee/Fees.sol";
import { StorageLib, FeeStorageLib } from "../../src/Storage.sol";
import { LiqTree } from "Liq/Tree.sol";
import { LiqMath } from "Liq/Math.sol";
import { Accum, AccumImpl } from "Util/Accum.sol";
import { X64, X128 } from "Math/Ops.sol";
import { TBP, TBPImpl } from "Borrow/TBP.sol";
import { RangeLiq, RangeLiqImpl, RangeBool } from "Liq/Structs.sol";
import { FeeRateSnapshot } from "Fee/Snap.sol";

/// Storage for asset tracking
struct AssetBook {
    // We assign asset ids incrementally.
    // With 2^256 asset ids, if we create 1 trillion new assets per second,
    // it would still take >3e57 years to run out of IDs.
    // By that time if this contract is still in use we deserve problems.
    uint256 assetCount;

    /// Every asset can be queried by its asset id.
    /// Users are expected to track the PositionID assigned by the PositionManager
    /// (an external contract that manages all Itos platform positions),
    /// and then query that position manager to get their asset's details.
    /// Directly accessing it through this mapping is rare.
    mapping(uint256 => Asset) book; // assetId to asset
}

/// Utility library for interaction with assets
library AssetBookImpl {
    event AssetCreated(uint256 assetId, int24 lowTBIdx, int24 highTBIdx, uint128 liq, AssetType aType);
    event AssetDestroyed(uint256 assetId, int24 lowTBIdx, int24 highTBIdx, uint128 liq, AssetType aType);

    /// Thrown when someone tries to destroy a non-existant asset.
    error AssetNotFound(uint256 assetId);

    /// Generate a new assetId to use.
    function getNewAssetId(AssetBook storage self) private returns (uint256 assetId) {
        // Increment first so asset numbers start at 0, since missing assets will return 0 from the book.
        unchecked {
            // 2^256 is soooo high we'll never increment to that number.
            self.assetCount += 1;
        }
        assetId = self.assetCount;
    }

    function record(AssetBook storage self, Asset memory asset) internal returns (uint256 assetId) {
        assetId = getNewAssetId(self);
        self.book[assetId] = asset;
        emit AssetCreated(assetId,
                          TableIndex.unwrap(asset.low),
                          TableIndex.unwrap(asset.high),
                          asset.liquidity, asset.aType);
    }

    function erase(AssetBook storage self, uint256 assetId) internal returns (Asset memory asset) {
        asset = self.book[assetId];

        // Check if the asset was actually created. No asset's liquidity can be zero.
        if (asset.liquidity == 0)
            revert AssetNotFound(assetId);

        delete self.book[assetId];
        emit AssetDestroyed(assetId,
                            TableIndex.unwrap(asset.low),
                            TableIndex.unwrap(asset.high),
                            asset.liquidity, asset.aType);
    }

    /// Returns essentially a mutable reference to the asset stored at an assetId
    function get(AssetBook storage self, uint256 assetId) internal view returns (Asset storage asset) {
        asset = self.book[assetId];
    }
}

/// The type of Asset the 2sAMM can open.
/// @dev We can have at most 127 different types before we have to change the Asset struct.
enum AssetType {
    Maker, // A regular maker.
    WideMaker, // A maker covering the infinite price range.
    TakerCall, // A Taker that has opted to lend the reserved assets.
    TakerPut // A Taker that opted to hold the reserved assets and avoid illiquidity risk.
}

/// Assets tell us how a user affects the liquidity in a pool so we can retrieve their underlyers
/// and also snapshot earnings/fees from swaps and borrows.
/// We make a clear distinction between Assets and Positions. Positions are held on the PortfolioManager
/// and have a clear owner. They contribute to the accounting in portfolios. Assets are entirely
/// encapsulated in Asset Producers, have no concept of an owner, and can be created, valued, and destroyed.
struct Asset {
    // Price at the time the asset was created
    Price originalSP; // 160 bits

    // Lower table tick is inclusive
    TableIndex low; // 24 bits
    // Upper table tick is exclusive
    TableIndex high; // 24 bits

    AssetType aType; // 8 bits

    /* 256 */

    uint128 liquidity; // 128 bits

    /* 256 */

    FeeRateSnapshot tableFeeRateSnapX128; // 512 bits

    /* 256 */
    // For Takers, this rate is a perToken value and X64
    // For Makers, this rate is a perLiq value and X128
    FeeRateSnapshot cumBorrowRateSnap; // 512 bits
}

library AssetLib {
    using TableIndexImpl for TableIndex;
    using TBPImpl for TBP;

    /// Create a new Maker
    /// @param rangeBool Where the current tabIdx is relative to the given rLiq.
    /// @param treeEarnSnap This earn rate comes externally because it's extrememly expensive
    /// to query the liquidity tree. Thus we get all the information at once in the LiqFacet
    /// and pass it where it needs to go.
    function makeM(
        RangeLiq memory rLiq,
        RangeBool rangeBool,
        Price currentSP,
        FeeRateSnapshot memory treeEarnSnap,
        TickTable storage table
    ) internal view returns (Asset memory a) {
        a.originalSP = currentSP;

        a.low = rLiq.low;
        a.high = rLiq.high;

        a.aType = AssetType.Maker;

        a.liquidity = rLiq.liq;

        // Take snapshots
        FeeCollector storage feeCollector = FeeStorageLib.load();
        FeeRateAccumulator storage globalAccum = feeCollector.globalFeeRateAccumX128;

        a.tableFeeRateSnapX128 = TableFeeLib.getMRangeFee(
            table, rLiq.low, rLiq.high, rangeBool, globalAccum.MX, globalAccum.MY);

        // We can't just assign treeEarnSnap to cumBorrowRateSnap because
        // solidity will just make the memory pointers the same.
        // This is dangerous, any modifications will affect both.
        a.cumBorrowRateSnap.X = treeEarnSnap.X;
        a.cumBorrowRateSnap.Y = treeEarnSnap.Y;
    }

    /// Create a new Taker
    /// @param rangeBool Where the current tabIdx is relative to the given rLiq.
    /// This is slightly redundant since we can compute this from currentSP,
    /// but we save a slight bit of gas by just passing this param along in multiple place.
    /// This value and currentSP must report the same range comparison!
    /// @dev Regardless of which Taker we open, we always borrow the same amounts.
    /// The differentiation comes later when the held amount is calculated.
    function makeT(
        AssetType aType,
        RangeLiq memory rLiq,
        RangeBool rangeBool,
        Price currentSP,
        TickTable storage table
    ) internal view returns (Asset memory a) {
        a.originalSP = currentSP;

        a.low = rLiq.low;
        a.high = rLiq.high;

        a.aType = aType;

        a.liquidity = rLiq.liq;

        // Take snapshots
        FeeCollector storage feeCollector = FeeStorageLib.load();
        FeeRateAccumulator storage globalAccum = feeCollector.globalFeeRateAccumX128;

        a.tableFeeRateSnapX128 = TableFeeLib.getTRangeFee(
            table, rLiq.low, rLiq.high, rangeBool, globalAccum.TX, globalAccum.TY);

        // Slight optimization to avoid reading/writing storage unnecessarily
        if (rangeBool == RangeBool.Below) {
            // If the current tick is lower than the low tick,
            // our complementary Maker is entirely in X.
            TBP storage xtbp = StorageLib.xTBP();
            a.cumBorrowRateSnap.X = xtbp.value();
        } else if (rangeBool == RangeBool.Above) {
            // If the current tick is higher than the high tick,
            // our complmentary Maker is entirely in Y.
            TBP storage ytbp = StorageLib.yTBP();
            a.cumBorrowRateSnap.Y = ytbp.value();
        } else { // We have a mix
            TBP storage xtbp = StorageLib.xTBP();
            TBP storage ytbp = StorageLib.yTBP();
            a.cumBorrowRateSnap.X = xtbp.value();
            a.cumBorrowRateSnap.Y = ytbp.value();
        }
    }

    /// Specific factory function for WideMakers.
    function makeWideM(uint128 liq, FeeRateSnapshot memory treeEarnSnap) internal view returns (Asset memory a) {
        // No need for original price or ticks.

        a.aType = AssetType.WideMaker;
        a.liquidity = liq;

        FeeCollector storage feeCollector = FeeStorageLib.load();
        FeeRateAccumulator storage globalAccum = feeCollector.globalFeeRateAccumX128;
        a.tableFeeRateSnapX128.X = globalAccum.MX;
        a.tableFeeRateSnapX128.Y = globalAccum.MY;

        a.cumBorrowRateSnap.X = treeEarnSnap.X;
        a.cumBorrowRateSnap.Y = treeEarnSnap.Y;
    }
}

library AssetImpl {
    using AccumImpl for Accum;
    using TBPImpl for TBP;

    /// The Taker fees are too high to repay at once. This will basically never happen.
    /// But if it ever does the solution is to just split the asset first.
    error TakerTimeFeeOverflow(uint256 top, uint256 bot, uint256 rateX32, uint256 borrowed);

    function isMaker(Asset memory self) internal pure returns (bool) {
        return (self.aType == AssetType.Maker) || (self.aType == AssetType.WideMaker);
    }

    /// Determine the fees earned by this Maker.
    /// The time and volatility fees are summed together.
    /// @param rangeBool Where the current table index is relative to the given low and high SPs.
    function calcMakerFees(
        Asset memory self,
        RangeBool rangeBool,
        TickTable storage table,
        FeeRateSnapshot memory treeEarnSnap
    ) internal view returns (uint256 xFee, uint256 yFee) {

        FeeRateSnapshot memory currentFeeRateX128;

        { // Oh now stupid the Solidity compiler is...
            FeeCollector storage feeCollector = FeeStorageLib.load();
            FeeRateAccumulator storage globalAccum = feeCollector.globalFeeRateAccumX128;

            TableIndex low = self.low;
            TableIndex high = self.high;

            currentFeeRateX128 = TableFeeLib.getMRangeFee(
                table, low, high, rangeBool, globalAccum.MX, globalAccum.MY
            );
        }

        // Table Fees are a per liq rate and X128
        uint256 xFeeRate = currentFeeRateX128.X.diff(self.tableFeeRateSnapX128.X);
        uint256 yFeeRate = currentFeeRateX128.Y.diff(self.tableFeeRateSnapX128.Y);

        // Add tree perLiq fees as well.
        xFeeRate += treeEarnSnap.X.diff(self.cumBorrowRateSnap.X);
        yFeeRate += treeEarnSnap.Y.diff(self.cumBorrowRateSnap.Y);

        // Revert on overflow. Earning more than 2^256 in fees is absolute batshit insane.
        xFee += X128.mul256(self.liquidity, xFeeRate);
        yFee += X128.mul256(self.liquidity, yFeeRate);
    }

    /// Determine the fees owed by this Taker.
    /// The time and volatility fees are summed together.
    /// @param rangeBool Where the current table index is relative to the given low and high SPs.
    /// @dev Reverts on fee overflows. Paying more than 2^256 in fees is absolute insanity.
    /// But if it does happen just split the asset and close each separately.
    function calcTakerFees(
        Asset memory self,
        uint256 borrowedX,
        uint256 borrowedY,
        RangeBool rangeBool,
        TickTable storage table
    ) internal view returns (uint256 xFee, uint256 yFee) {
        FeeRateSnapshot memory currentFees;
        { // Again this is for the stack depth, because Solc needs some hand holding.
            FeeCollector storage feeCollector = FeeStorageLib.load();
            FeeRateAccumulator storage globalAccum = feeCollector.globalFeeRateAccumX128;
            currentFees = TableFeeLib.getTRangeFee(
                table, self.low, self.high, rangeBool, globalAccum.TX, globalAccum.TY
            );
        }
        uint256 xFeeRate = currentFees.X.diff(self.tableFeeRateSnapX128.X);
        uint256 yFeeRate = currentFees.Y.diff(self.tableFeeRateSnapX128.Y);
        xFee += X128.mul256(self.liquidity, xFeeRate);
        yFee += X128.mul256(self.liquidity, yFeeRate);

        if (borrowedX > 0) {
            TBP storage xtbp = StorageLib.xTBP();
            uint256 rateX64 = xtbp.value().diff(self.cumBorrowRateSnap.X);
            (uint256 botX, uint256 topX) = X64.mul512(rateX64, borrowedX);
            if (topX > 0) {
                // This asset has somehow managed to earn more money than god.
                // Please split the asset to withdraw it.
                revert TakerTimeFeeOverflow(topX, botX, rateX64, borrowedX);
            }
            xFee += botX;
        }
        if (borrowedY > 0) {
            TBP storage ytbp = StorageLib.yTBP();
            uint256 rateX64 = ytbp.value().diff(self.cumBorrowRateSnap.Y);
            (uint256 botY, uint256 topY) = X64.mul512(rateX64, borrowedY);
            if (topY > 0) {
                // This asset has somehow managed to earn more money than god.
                // Please split the asset to withdraw it.
                revert TakerTimeFeeOverflow(topY, botY, rateX64, borrowedY);
            }
            yFee += botY;
        }
    }

    /// Calculate fee earnings for a wide Maker.
    function calcWideMakerFees(Asset memory self, FeeRateSnapshot memory treeEarnSnap)
    internal view returns (uint256 xFee, uint256 yFee) {
        // Asset type should have been verified before calling this function.

        FeeCollector storage feeCollector = FeeStorageLib.load();
        FeeRateAccumulator storage globalAccum = feeCollector.globalFeeRateAccumX128;
        uint256 xFeeRate = globalAccum.MX.diff(self.tableFeeRateSnapX128.X);
        uint256 yFeeRate = globalAccum.MY.diff(self.tableFeeRateSnapX128.Y);

        // Add tree perLiq fees as well.
        xFeeRate += treeEarnSnap.X.diff(self.cumBorrowRateSnap.X);
        yFeeRate += treeEarnSnap.Y.diff(self.cumBorrowRateSnap.Y);

        // Revert on overflow. Paying more than 2^256 in fees is absolute batshit insane.
        xFee += X128.mul256(self.liquidity, xFeeRate);
        yFee += X128.mul256(self.liquidity, yFeeRate);
    }

    function rangeLiq(Asset memory self) internal view returns (RangeLiq memory rLiq) {
        return RangeLiqImpl.fromTables(self.liquidity, self.low, self.high);
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { TableIndex } from "Ticks/Table.sol";
import { Accum, AccumImpl } from "Util/Accum.sol";
import { RangeLiq } from "Liq/Structs.sol";
import { FeeRateSnapshot } from "Fee/Snap.sol";

// This is the underlying library for the range tree mechanics.
// import { LiqTree, RangeTreeImpl } from "Tree/Tree.sol";

// Replace with real liq tree when that is ready.
struct LiqTree {
    uint128 wideMLiq;
}

/// Utility functions for the LiqFacets when opening and closing positions
library LiqTreeImpl {
    // using RangeTreeImpl for LiqTree;

    /// Adds Wide Maker Liquidity and returns a snapshot of the fees.
    function addWideMLiq(LiqTree storage self, uint128 liq) internal returns (FeeRateSnapshot memory snap) {
        // self.addWideMLiq(liq);
    }

    /// Adds Maker Liquidity and returns a snapshot of the fees.
    function addMLiq(LiqTree storage self, RangeLiq memory rLiq) internal returns (FeeRateSnapshot memory snap) {
        // self.addMLiq(TableIndex.unwrap(rLiq.low), TableIndex.unwrap(rLiq.high));
    }

    /// Adds Taker Liquidity, validates the liquidity limits, and borrows the given amounts
    function addTLiq(LiqTree storage self, RangeLiq memory rLiq, uint256 borrowedX, uint256 borrowedY) internal {
        // self.addTLiqAndValidate(TableIndex.unwrap(rLiq.low), TableIndex.unwrap(rLiq.high));
    }

    /// Removes Wide Maker Liquidity, validates the liquidity limits, and returns a snapshot of the fees.
    function subWideMLiq(LiqTree storage self, uint128 liq) internal returns (FeeRateSnapshot memory snap) {
        // self.subWideMLiq(liq);
    }

    /// Removes Maker Liquidity, validates the liquidity limits, and returns a snapshot of the fees.
    function subMLiq(LiqTree storage self, RangeLiq memory rLiq) internal returns (FeeRateSnapshot memory snap) {
        // self.subMLiqAndValidate(TableIndex.unwrap(rLiq.low), TableIndex.unwrap(rLiq.high));
    }

    /// Removes Taker liquidity and repays the borrowed amounts.
    function subTLiq(LiqTree storage self, RangeLiq memory rLiq, uint256 borrowedX, uint256 borrowedY) internal {
        // self.subTLiq(TableIndex.unwrap(rLiq.low), TableIndex.unwrap(rLiq.high));
    }
}

/// Utility functions for querying fee accumulators for given ranges.
/// Used for valuing makers since we're not modifying the maker position
/// and can't get the earn rate any other way.
library EarnTreeImpl {
    // using RangeTreeImpl for LiqTree;

    function earnSnap(LiqTree storage self, TableIndex low, TableIndex high)
    internal view returns (FeeRateSnapshot memory snap) {
        // (uint256 xSnap, uint256 ySnap) = self.queryCumEarnRates(low, high);
        // snap.X = AccumImpl.from(xSnap);
        // snap.Y = AccumImpl.from(ySnap);
    }

    function wideEarnSnap(LiqTree storage self) internal view returns (FeeRateSnapshot memory snap) {
        // (uint256 xSnap, uint256 ySnap) = self.queryCumEarnRates(low, high);
        // snap.X = AccumImpl.from(xSnap);
        // snap.Y = AccumImpl.from(ySnap);
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { Accum, AccumImpl } from "Util/Accum.sol";
import { InternalBorrower } from "Borrow/Internal.sol";
import { IAAVEReserveData } from "../interfaces/IAAVEReserveData.sol";

// @notice The data structure for tracking interest accrued by Taker borrows.
// @dev Note that we don't write down the borrow amount.
// That is stored in the Asset struct. We convenient don't need it to calculate
// the cumulativeEarningsPerToken.
// We calculate cumulative (borrow * APR * time / borrow) thus the borrow cancels.
struct TBP {
    Accum cumulativeEarningsPerTokenX64; // 256 bits

    // The address from which we pull the borrowing interest rate.
    address rateOracle;

    // The current interest rate as an X64 number.
    // This is Seconds Percentage Rate.
    // This should be the APR divided by 365 * 24 * 60 * 60.
    // We support a min rate of 0.01% APR which is roughly 3e-12 SPR.
    // And a max rate of 100,000% APR which is 3e-5 SPR.
    // Thus as decimal bits, the first significant bit will be after the 14th decimal
    // bit and leading bit will never be after the 39th decimal.
    // Thus an X64, 64 bit number is more than sufficient.
    uint64 SPRX64;

    // Last Unix timstamp at which any node in our tree has accumulated tsecs.
    // We update this timestamp whenever any node in our subtree updates its tLiq.
    uint64 lastTimestamp;

    // We could store the token here because technically each rate oracle is token specific.
    // But let's just keep the bookkeeping in InfoStorage to avoid accidental decoupling.
}

library TBPImpl {
    using AccumImpl for Accum;

    /// Throw error if the new timestamp is younger than the old timestamp.
    error TimestampManipulation(uint64 newTime, uint64 oldTime);

    event TBPUpdatedSPR(uint64 newSPRX64, uint64 timestamp);

    uint256 constant SECONDS_PER_YEAR = 31536000;

    /// Update the current rate with a new second percent rate.
    /// This also collects the fee to be up-to-date.
    function updateSPR(TBP storage self, uint64 newSPRX64) internal returns (Accum cumEarnPerTokenX64) {
        // This shouldn't occur very frequently.
        emit TBPUpdatedSPR(newSPRX64, uint64(block.timestamp));

        cumEarnPerTokenX64 = collect(self);
        self.SPRX64 = newSPRX64;
    }

    /// Collects the fees up to the current time and returns the updated fee accumulation.
    function collect(TBP storage self) internal returns (Accum cumEarnPerTokenX64) {
        self.cumulativeEarningsPerTokenX64 = value(self);
        self.lastTimestamp = uint64(block.timestamp);
        return self.cumulativeEarningsPerTokenX64;
    }

    /// When the rate doesn't change, we don't actually need to collect any fees as long
    /// as we don't change the timestamp either.
    /// Thus to keep certain methods view methods, we use this function to get an up to date
    /// value of the cumulative earn without actually collecting and modifying storage.
    function value(TBP storage self) internal view returns (Accum cumEarnPerTokenX64) {
        uint64 newTime = uint64(block.timestamp);
        if (newTime < self.lastTimestamp) {
            revert TimestampManipulation(newTime, self.lastTimestamp);
        }

        uint256 collectedX64 = uint256(self.SPRX64) * (newTime - self.lastTimestamp);
        cumEarnPerTokenX64 = self.cumulativeEarningsPerTokenX64.add(collectedX64);
    }

    /// Refresh the interest rate from the rate oracle if enough time has passed.
    function pull(TBP storage self, address token, uint32 updateIntervalSecs) internal {
        if (uint64(block.timestamp) < self.lastTimestamp + updateIntervalSecs)
            return;

        (,,,,,, uint256 variableBorrowRate,,,,,) = IAAVEReserveData(self.rateOracle).getReserveData(token);
        // The rate is current in APR ray, we want it as an X64 SPR.
        // So we have to divide by the seconds in a year and 10e18 and multiply by 2^64.
        // We know that 10e18 is just under 64 bits, which means the interest rate
        // has another 192 bits to work with.
        // There is NO WAY it uses more than 128 of those, that would be an interest rate
        // of 3.4e40%. Let's relax there buddy.
        // Thus we can do all of this math without worry.
        updateSPR(self, uint64(variableBorrowRate << 64 / (10e18 * SECONDS_PER_YEAR)));
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

/// The configuration for the Internal Borrower.
/// The IBR is another assymptotic function like the fee calculator.
/// @dev We use lower precision here than in fee calculator to accomodate
/// maxUtils that are over 1 (which avoids div by 0).
/// Plus precision is not as important in this rate.
struct IBRConfig {
    uint120 invAlphaX120; // Always less than 1

    // We assume this value has already had the BETA_OFFSET added to it.
    // Otherwise it can be negative.
    uint72 betaX64; // Give it the extra bits so I don't have to think as hard.

    uint64 maxUtilX56; // Will be every so slightly greater than 1
} // 256 bits

struct InternalBorrower {
    // The total nominal liquidity values. I.E. liq * ticks width.
    // These can only take up to 128 + 24 = 152 bits.
    int256 totalMLiq;
    int256 totalTLiq;

    // How this IBR is configured.
    IBRConfig config; // 256 bits
}

library InternalBorrowerImpl {

    uint120 public constant DEFAULT_INVALPHAX120 = 3242783188242379110212435968;
    uint72 public constant DEFAULT_BETAX64 = 18446744031676564409;
    uint64 public constant DEFAULT_MAXUTILX56 = 72129651631965856;

    /// We use a beta offset so we can do all our operations in uint.
    uint72 private constant BETA_OFFSET = 1 << 64;

    /// The internal rate only changes with liquidity changes
    /// so we update liquidity and return the new rate at the same time.
    /// @return borrowRateX64 The SPR for the TBP. This is ALWAYS much less than 1 since its an SPR.
    function updateLiqs(InternalBorrower storage self, int256 mLiqDelta, int256 tLiqDelta) internal returns (uint64 borrowRateX64) {
        int256 m = self.totalMLiq + mLiqDelta;
        int256 t = self.totalTLiq + tLiqDelta;

        // Recall that t is at most 152 bits so this is a safe shift.
        // We know that t < m so this is a safe cast.
        uint64 utilX56 = uint64(uint256((t << 56) / m));
        // We know our util can't go over 1 due to liquidity constraints.
        // So we set our maxUtil to be slightly greater than 1 to avoid a divide by 0.

        borrowRateX64 = uint64(self.config.betaX64 + self.config.invAlphaX120 / (self.config.maxUtilX56 - utilX56) - BETA_OFFSET);

        self.totalMLiq = m;
        self.totalTLiq = t;
    }

    function getDefaultConfig() public pure returns (IBRConfig memory config) {
        config.invAlphaX120 = DEFAULT_INVALPHAX120;
        config.betaX64 = DEFAULT_BETAX64;
        config.maxUtilX56 = DEFAULT_MAXUTILX56;
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { X128 } from "Math/Ops.sol";
import { UnsafeMath } from "Math/UnsafeMath.sol";
import { SafeCast } from "Math/Cast.sol";
import { Accum, AccumImpl } from "Util/Accum.sol";

/// Type used to calculate swap fees and internal borrow fees from assymptotic rational function.
struct FeeCalculator {
    uint256 invAlphaX224;
    uint128 betaX96;
    uint128 maxUtil; // X128 since always less than 1.
}

/**
 * @notice Math utilities for calculating swap fees
 * @dev The FeeCalculator should be used in memory since we read it once.
 **/
library FeeCalculatorImpl {
    using SafeCast for uint256;
    using SafeCast for int256;

    uint128 private constant BETA_OFFSET = 1 << 96;
    uint96 private constant ONEX96 = type(uint96).max;

    /// @notice Initialization function to be called on contract setup on its FeeCalculator.
    /// @param betaX96 is the beta term but notice it's a signed int because beta can be negative.
    /// To accomodate the signed bit we only use X96 in a 128 bit number.
    /// @param maxUtilX128 is always positive and less than 1 so we use the full 128 bits for the decimal places.
    /// This way both beta and maxUtil can fit into one storage slot.
    /// @param invAlphaX224 is X224 because it gets divided by the util units and the result should be in the
    /// same units as beta which is the units the fee rate will be in. Thus 96 + 128 = 224.
    /// @dev To avoid casts back and forth and doing operations with a signed value and unsigned values, we offset
    /// beta by an amount and subtract the offset when actually calculating the fee rate.
    function init(FeeCalculator memory self, uint256 invAlphaX224, int128 betaX96, uint128 maxUtilX128) internal pure {
        self.invAlphaX224 = invAlphaX224;
        self.betaX96 = int256(betaX96 + int128(BETA_OFFSET)).toUint128();
        self.maxUtil = maxUtilX128;
    }

    /// @notice Calculate the fee rate to be paid at this tick according to liquidity utilization based on takers.
    /// @dev We're calculating feeRate = beta + invAlpha / (maxUtil - util)
    /// This means feeRate and the two summands have the same x96 units.
    function calcFeeRate(
        FeeCalculator memory self,
        uint128 mLiq,
        uint128 tLiq
    ) internal pure returns (uint96 feeRateX96) {
        // utilizations are always X128
        uint128 util = ((uint256(tLiq) << 128) / mLiq).toUint128(); // Implicitly checks tLiq < mLiq;

        if (util > self.maxUtil) {
            // If we're somehow in an overutilization scenario, although it should be impossible,
            // we don't error. We use a 100% fee rate and a single swap will burn Takers and reduce
            // the utilization back down.
            return ONEX96;
        }

        uint256 fullFeeRate = self.betaX96 + self.invAlphaX224 / (self.maxUtil - util) - BETA_OFFSET;

        // We don't allow fee rates over one of course since swaps just become a money pit.
        // A single swap will liquidate a bunch of Takers and help reduce util back down.
        if (fullFeeRate > ONEX96) {
            fullFeeRate = ONEX96;
        }

        feeRateX96 = uint96(fullFeeRate);
    }

    /// Calc the nominal amount of fees applicable to the given traded value.
    /// Use this over discountAmount when you have the token amount traded.
    function calcFeeAmount(
        FeeCalculator memory self,
        uint128 mLiq,
        uint128 tLiq,
        uint256 val
    ) internal pure returns (uint256 feeAmount) {
        // Widen to 128 to use X128 lib.
        uint128 feeRateX96 = calcFeeRate(self, mLiq, tLiq);
        feeAmount = X128.mul256RoundUp(feeRateX96 << 32, val);
    }

    /// Discounts fees from the given amount to estimate the tradeable size.
    /// Use this over calcFeeAmount when you have the total amount of a token to trade.
    /// @dev Where f is the fee rate, this just computes v / (1 + f).
    /// @param amount The total swap amount, i.e. the trade input size.
    /// We rely on the fact that this value is at most 128 bits.
    function discountSize(
        FeeCalculator memory self,
        uint128 mLiq,
        uint128 tLiq,
        uint256 amount
    ) internal pure returns (uint256 discountedAmount) {
        // Widen to 128 to use X128 lib.
        uint128 feeRateX96 = calcFeeRate(self, mLiq, tLiq);
        discountedAmount = (amount << 96) / ((1 << 96) + feeRateX96);
    }
}

/// Type used to track fees earned by ticks
struct FeeRateAccumulator {
    Accum MX; // Maker earned X
    Accum MY;
    Accum TX; // Taker owed X
    Accum TY;
}

/**
 * @notice Convenience functions for accumulating fees earned by ticks
 **/
library FeeRateAccumulatorImpl {
    using AccumImpl for Accum;

    /// Subtract this accumulator from another, and store the results in this one.
    /// @dev We're subtracting an in-memory accumulator from an in-storage accumulator.
    /// This is used for crossing table ticks.
    function subFrom(FeeRateAccumulator storage self, FeeRateAccumulator memory other) internal {
        self.MX = other.MX.diffAccum(self.MX);
        self.MY = other.MY.diffAccum(self.MY);
        self.TX = other.TX.diffAccum(self.TX);
        self.TY = other.TY.diffAccum(self.TY);
    }
}

/// Overall type used to interface fees by both swaps and liquidity ops
struct FeeCollector { // 9 * 32 Bytes
    FeeCalculator feeCalc; // 512 bits;

    uint128 protocolTakeRateX128;
    uint128 _extraSpacing;

    /* 256 */

    uint256 protocolOwnedX;
    uint256 protocolOwnedY;

    // Accumulator variables
    // These are stored last so that we can extend the struct with rewards if needed.
    FeeRateAccumulator globalFeeRateAccumX128; // 1024 bits
}

/// Main functions for collecting fees from swaps
library FeeCollectorImpl {
    using AccumImpl for Accum;

    error CollectSizeTooLarge();
    // If this is encountered, we just have to add liquidity to the current tick
    // to "fix" the state, until a code patch is pushed.
    error ImproperSwapState();

    /// Collect the given fees from the swapper, and then charge the appropriate amount to Takers.
    /// @param liq This is mLiq - tLiq, we use the overall net liq here for convenience
    /// @dev since the fee is the amount paid by the trader, we calculate fee*tLiq/liq to get the
    /// fees charged to Takers.
    /// If liq is 0 this will have division error. We should never be collecting fees when there is no
    function collectSwapFees(
        FeeCollector memory self,
        bool isX,
        uint256 traderFees,
        uint128 tLiq,
        uint128 liq
    ) internal pure {
        // We avoid Fullmath muldiv here by restricting fees to a uint128.
        // It is HIGHLY unlikely fees will be over uint128's max so instead of eating an extra 400 gas
        // to accomodate it, we revert.
        if (traderFees > type(uint128).max) {
            // Could report the largest collect/swap size later if it's important.
            revert CollectSizeTooLarge();
        }

        if (liq == 0) {
            // There should be no fees to collect.
            if (traderFees != 0) {
                revert ImproperSwapState();
            }
            return;
        }

        // Takers and Traders pay the same fee rate.
        uint256 takerFeeRateX128 = UnsafeMath.divRoundingUp((traderFees << 128), liq);
        // Round down. Give extra to Makers.
        uint256 protocolRateX128 = X128.mul256(self.protocolTakeRateX128, takerFeeRateX128);
        uint256 makerFeeRateX128 = takerFeeRateX128 - protocolRateX128;

        uint128 mLiq = liq + tLiq;
        // Round down dropping dust.
        uint256 addend = X128.mul256(mLiq, protocolRateX128);

        if (isX) {
            if (type(uint256).max - self.protocolOwnedX < addend) {
                // If we can't add these fees, we don't do anything fancy.
                // Just give it all to the makers.
                makerFeeRateX128 = takerFeeRateX128;
            } else {
                self.protocolOwnedX += addend;
            }

            self.globalFeeRateAccumX128.MX = self.globalFeeRateAccumX128.MX.add(makerFeeRateX128);
            self.globalFeeRateAccumX128.TX = self.globalFeeRateAccumX128.TX.add(takerFeeRateX128);
        } else {
            if (type(uint256).max - self.protocolOwnedY < addend) {
                // If we can't add these fees, we don't do anything fancy.
                // Just give it all to the makOBers.
                makerFeeRateX128 = takerFeeRateX128;
            } else {
                self.protocolOwnedY += addend;
            }

            self.globalFeeRateAccumX128.MY = self.globalFeeRateAccumX128.MY.add(makerFeeRateX128);
            self.globalFeeRateAccumX128.TY = self.globalFeeRateAccumX128.TY.add(takerFeeRateX128);
        }
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { AdminFlags } from "Pool/Admin.sol";
import { AdminLib } from "Util/Admin.sol";
import { InfoStorage, StorageLib } from "../../src/Storage.sol";

/// The current state of the 2sAMM
/// @dev We only consider the contract transacting when we pass the control sequences outside the contract
/// which is the only time we have to worry about reentrancy.
enum Status {
    Idle, // No on-going transactions
    Transacting, // A transaction is in progress.
    Halted, // The 2sAMM is temporarily halted
    Unhalting // The 2sAMM is going to unpause.
}

library StatusLib {
    error ImproperStatusTransition(Status current, Status attempted);
    error ImproperUnhalt();

    /// Turn on the halt status. No time delay on this.
    function halt() internal {
        InfoStorage storage info = StorageLib.info();
        if (info.status == Status.Unhalting) {
            // If the status is unhalting, an unhalter could stop it.
            AdminLib.validateRights(AdminFlags.UNHALT);
        } else if (info.status == Status.Transacting) {
            // We don't allow mid-transaction halts.
            revert ImproperStatusTransition(info.status, Status.Halted);
        } else {
            // Otherwise just need halt rights.
            AdminLib.validateRights(AdminFlags.HALT);
        }

        // When halting, current pending cuts can go through.
        // And new ones can be initiated, but cannot
        // be accepted.

        info.status = Status.Halted;
    }

    // Turn off the halting status. This must be time delayed by at least the short delay.
    // This can also be used to extend the unhalt period.
    function startUnhalt(uint32 delaySecs) internal {
        InfoStorage storage info = StorageLib.info();
        if (info.status != Status.Halted && info.status != Status.Unhalting)
            revert ImproperStatusTransition(info.status, Status.Unhalting);

        if (info.numPendingCuts != 0)
            AdminLib.validateRights(AdminFlags.UNHALT_WITH_CHANGES);
        else
            AdminLib.validateRights(AdminFlags.UNHALT);

        if (delaySecs < info.shortDelay)
            revert ImproperUnhalt();

        info.unhaltTime = uint64(block.timestamp) + delaySecs;
        info.status = Status.Unhalting;
    }

    // Return from unhalting back to normal.
    // Anyone with the unhalt right can finalize this change.
    function finishUnhalt() internal {
        AdminLib.validateRights(AdminFlags.UNHALT);

        InfoStorage storage info = StorageLib.info();
        if (uint64(block.timestamp) < info.unhaltTime)
            revert ImproperUnhalt();

        if (info.status != Status.Unhalting)
            revert ImproperStatusTransition(info.status, Status.Idle);

        info.status = Status.Idle;
    }
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
pragma solidity ^0.8.13;

library ContractLib {
    error NotAContract();

    // @dev It's important to verify an address is a contract if you're going
    // to call methods on it because many transfer functions check the returned
    // data length to determine success and an address with no bytecode will
    // return no data thus appearing like a success.
   function isContract(address addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(addr)
        }
        return (size > 0);
    }

    function assertContract(address addr) internal view {
        if (!isContract(addr)) {
            revert NotAContract();
        }
    }

    /// An address created with CREATE2 is deterministic.
    /// Given the input arguments, we know exactly what the resulting
    /// deployed contract's address will be.
    /// @param deployer The address that created the contract.
    /// @param salt The salt used when creating the contract.
    /// @param initCodeHash The keccak hash of the initCode of the deployed contract.
    function getCreate2Address(
        address deployer,
        bytes32 salt,
        bytes32 initCodeHash
    ) public pure returns (address deployedAddr) {
        deployedAddr = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            deployer,
                            salt,
                            initCodeHash
                        )
                    )
                )
            )
        );
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @author Uniswap Team
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = uint256(-int256(denominator)) & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        unchecked {
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4

            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
        }
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }

    /// Calculates a 512 bit product of two 256 bit numbers.
    /// @return r0 The lower 256 bits of the result.
    /// @return r1 The higher 256 bits of the result.
    function mul512(uint256 a, uint256 b)
    internal pure returns(uint256 r0, uint256 r1) {
        assembly {
            let mm := mulmod(a, b, not(0))
            r0 := mul(a, b)
            r1 := sub(sub(mm, r0), lt(mm, r0))
        }
    }

    /// Short circuit mulDiv if the multiplicands don't overflow.
    /// Use this when you expect the input values to be small in most cases.
    /// @dev This charges an extra ~20 gas on top of the regular mulDiv if used, but otherwise costs 30 gas
    function shortMulDiv(
        uint256 m0,
        uint256 m1,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        uint256 num;
        unchecked {
            num = m0 * m1;
        }
        if (num / m0 == m1) {
            return num / denominator;
        } else {
            return mulDiv(m0, m1, denominator);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.13;

/// A generic bitmap used by the TickTable.
struct Bitmap {
    uint256 num;
}

/**
 * @title BitmapImpl
 * @notice Utility for tracking set bits in a bit map;
 **/
library BitmapImpl {

    function isSet(Bitmap storage self, uint8 idx) internal view returns(bool set) {
        return ((self.num >> idx) & 0x1 == 1);
    }

    function trySet(Bitmap storage self, uint8 idx) internal {
        self.num |= uint(1) << idx;
    }

    function clear(Bitmap storage self, uint8 idx) internal {
        self.num &= ~(uint(1) << idx);
    }

    function getAtOrNext(Bitmap storage self, uint8 idx) internal view returns(bool exists, uint8 nextIdx) {
        uint8 shift = idx;
        uint256 shifted = self.num >> shift;
        if (shifted == 0) {
            return (false, 0);
        }

        uint8 lsb = getLSBIdx(Bitmap({num: shifted}));
        unchecked {
            return (true, lsb + shift);
        }
    }

    function getAtOrPrev(Bitmap storage self, uint8 idx) internal view returns(bool exists, uint8 prevIdx) {
        unchecked {
        uint8 shift = 255 - idx;
        uint256 shifted = self.num << shift;
        if (shifted == 0) {
            return (false, 0);
        }

        uint8 msb = getMSBIdx(Bitmap({num: shifted}));
        return (true, msb - shift);
        }
    }

    /// Get idx of the most significant bit
    function getMSBIdx(Bitmap memory self) internal pure returns(uint8 idx) {
        uint256 num = self.num;
        require(num != 0);

        unchecked {
        idx = 0;
        if (num > type(uint128).max) {
            idx += 128;
            num >>= 128;
        }
        if (num > type(uint64).max) {
            idx += 64;
            num >>= 64;
        }
        if (num > type(uint32).max) {
            idx += 32;
            num >>= 32;
        }
        if (num > type(uint16).max) {
            idx += 16;
            num >>= 16;
        }
        if (num > type(uint8).max) {
            idx += 8;
            num >>= 8;
        }
        if (num > 15) {
            idx += 4;
            num >>= 4;
        }
        if (num > 3) {
            idx += 2;
            num >>= 2;
        }
        if (num > 1) {
            idx += 1;
        }
        }
    }

    /// Get idx of the least significant bit
    function getLSBIdx(Bitmap memory self) internal pure returns(uint8 idx) {
        uint256 num = self.num;
        require(num != 0);

        unchecked {
        idx = 0;
        if (num & type(uint128).max == 0) {
            idx += 128;
            num >>= 128;
        }
        if (num & type(uint64).max == 0) {
            idx += 64;
            num >>= 64;
        }
        if (num & type(uint32).max == 0) {
            idx += 32;
            num >>= 32;
        }
        if (num & type(uint16).max == 0) {
            idx += 16;
            num >>= 16;
        }
        if (num & type(uint8).max == 0) {
            idx += 8;
            num >>= 8;
        }
        if (num & 0x0F == 0) {
            idx += 4;
            num >>= 4;
        }
        if (num & 0x03 == 0) {
            idx += 2;
            num >>= 2;
        }
        if (num & 0x01 == 0) {
            idx += 1;
        }
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { FullMath } from "Math/FullMath.sol";

library X32 {
    // Multiply two 256 bit numbers to a 512 number, but one of the 256's is X32.
    function mul512(uint256 a, uint256 b)
    internal pure returns (uint256 bot, uint256 top) {
        (uint256 rawB, uint256 rawT) = FullMath.mul512(a, b);
        bot = (rawB >> 32) + (rawT << 224);
        top = rawT >> 32;
    }
}

library X64 {
    // Multiply two 256 bit numbers to a 512 number, but one of the 256's is X32.
    function mul512(uint256 a, uint256 b)
    internal pure returns (uint256 bot, uint256 top) {
        (uint256 rawB, uint256 rawT) = FullMath.mul512(a, b);
        bot = (rawB >> 64) + (rawT << 192);
        top = rawT >> 64;
    }
}

/**
 * @notice Utility for Q64.96 operations
 **/
library Q64X96 {

    uint256 constant PRECISION = 96;

    uint256 constant SHIFT = 1 << 96;

    error Q64X96Overflow(uint160 a, uint256 b);

    /// Multiply an X96 precision number by an arbitrary uint256 number.
    /// Returns with the same precision as b.
    /// The result takes up 256 bits. Will error on overflow.
    function mul(uint160 a, uint256 b, bool roundUp) internal pure returns(uint256 res) {
        (uint256 bot, uint256 top) = FullMath.mul512(a, b);
        if ((top >> 96) > 0) {
            revert Q64X96Overflow(a, b);
        }
        assembly {
            res := add(shr(96, bot), shl(160, top))
        }
        if (roundUp && (bot % SHIFT > 0)) {
            res += 1;
        }
    }

    /// Same as the regular mul but without checking for overflow
    function unsafeMul(uint160 a, uint256 b, bool roundUp) internal pure returns(uint256 res) {
        (uint256 bot, uint256 top) = FullMath.mul512(a, b);
        assembly {
            res := add(shr(96, bot), shl(160, top))
        }
        if (roundUp) {
            uint256 modby = SHIFT;
            assembly {
                res := add(res, gt(mod(bot, modby), 0))
            }
        }
    }

    /// Divide a uint160 by a Q64X96 number.
    /// Returns with the same precision as num.
    /// @dev uint160 is chosen because once the 96 bits of precision are cancelled out,
    /// the result is at most 256 bits.
    function div(uint160 num, uint160 denom, bool roundUp)
    internal pure returns (uint256 res) {
        uint256 fullNum = uint256(num) << PRECISION;
        res = fullNum / denom;
        if (roundUp) {
            assembly {
                res := add(res, gt(fullNum, mul(res, denom)))
            }
        }
    }
}

library X96 {
    uint256 constant PRECISION = 96;
    uint256 constant SHIFT = 1 << 96;
}

library X128 {
    uint256 constant PRECISION = 128;

    uint256 constant SHIFT = 1 << 128;

    /// Multiply a 256 bit number by a 128 bit number. Either of which is X128.
    /// @dev This rounds results down.
    function mul256(uint128 a, uint256 b) internal pure returns (uint256) {
        (uint256 bot, uint256 top) = FullMath.mul512(a, b);
        return (bot >> 128) + (top << 128);
    }

    /// Multiply a 256 bit number by a 128 bit number. Either of which is X128.
    /// @dev This rounds results up.
    function mul256RoundUp(uint128 a, uint256 b) internal pure returns (uint256 res) {
        (uint256 bot, uint256 top) = FullMath.mul512(a, b);
        uint256 modmax = SHIFT;
        assembly {
            res := add(add(shr(128, bot), shl(128, top)), gt(mod(bot, modmax), 0))
        }
    }

    /// Multiply a 256 bit number by a 256 bit number, either of which is X128, to get 384 bits.
    /// @dev This rounds results down.
    /// @return bot The bottom 256 bits of the result.
    /// @return top The top 128 bits of the result.
    function mul512(uint256 a, uint256 b) internal pure returns (uint256 bot, uint256 top) {
        (uint256 _bot, uint256 _top) = FullMath.mul512(a, b);
        bot = (_bot >> 128) + (_top << 128);
        top = _top >> 128;
    }
}

/// Convenience library for interacting with Uint128s by other types.
library U128Ops {

    function add(uint128 self, int128 other) public pure returns (uint128) {
        if (other >= 0) {
            return self + uint128(other);
        } else {
            return self - uint128(-other);
        }
    }

    function sub(uint128 self, int128 other) public pure returns (uint128) {
        if (other >= 0) {
            return self - uint128(other);
        } else {
            return self + uint128(-other);
        }
    }
}

library U256Ops {
    function add(uint256 self, int256 other) public pure returns (uint256) {
        if (other >= 0) {
            return self + uint256(other);
        } else {
            return self - uint256(-other);
        }
    }

    function sub(uint256 self, uint256 other) public pure returns (int256) {
        if (other >= self) {
            uint256 temp = other - self;
            // Yes technically the max should be -type(int256).max but that's annoying to
            // get right and cheap for basically no benefit.
            require(temp <= uint256(type(int256).max));
            return -int256(temp);
        } else {
            uint256 temp = self - other;
            require(temp <= uint256(type(int256).max));
            return int256(temp);
        }
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { TableIndex, TableIndexImpl } from "Ticks/Table.sol";
import { TickTable, TickTableImpl } from "Ticks/TickTable.sol";
import { TickData } from "Ticks/Data.sol";
import { Accum, AccumImpl } from "Util/Accum.sol";
import { FeeRateSnapshot } from "Fee/Snap.sol";
import { RangeBool } from "Liq/Structs.sol";


/// Utility functions for querying fees from the TickTable.
/// @dev We use sqrtPrice when  because table->SP is much cheaper than SP->table.
library TableFeeLib {
    using TableIndexImpl for TableIndex;
    using TickTableImpl for TickTable;
    using AccumImpl for Accum;

    /// Calculate the inside fee accumulation for Maker earnings since contract deployement in a given range
    /// @dev Recall the inside feeRate is the feeRate for the range usually calculated as the
    /// difference of two outside feeRates or the global rate minus two outside fee rates.
    /// Because it is the result of differences it can be negative.
    function getMRangeFee(
        TickTable storage table,
        TableIndex low,
        TableIndex high,
        RangeBool rBool,
        Accum globalMX,
        Accum globalMY) internal view returns (FeeRateSnapshot memory makerSnap) {
        require(low.isLT(high), "MRF");

        // Data we fetch should be set. Fortunately this should happen
        // from a previous step where liquidity is added.
        TickData storage lowData = table.getData(low);
        TickData storage highData = table.getData(high);

        if (rBool == RangeBool.Below) {
            makerSnap.X = lowData.outsideFeeRateAccumX128.MX.diffAccum(highData.outsideFeeRateAccumX128.MX);
            makerSnap.Y = lowData.outsideFeeRateAccumX128.MY.diffAccum(highData.outsideFeeRateAccumX128.MY);
        } else if (rBool == RangeBool.Within) {
            makerSnap.X = globalMX.diffAccum(lowData.outsideFeeRateAccumX128.MX).diffAccum(highData.outsideFeeRateAccumX128.MX);
            makerSnap.Y = globalMY.diffAccum(lowData.outsideFeeRateAccumX128.MY).diffAccum(highData.outsideFeeRateAccumX128.MY);
        } else {
            makerSnap.X = highData.outsideFeeRateAccumX128.MX.diffAccum(lowData.outsideFeeRateAccumX128.MX);
            makerSnap.Y = highData.outsideFeeRateAccumX128.MY.diffAccum(lowData.outsideFeeRateAccumX128.MY);
        }
    }

    /// Calculate the inside fee accumulation for Taker debts since contract deployement in a given range
    /// @dev Recall the inside feeRate is the feeRate for the range usually calculated as the
    /// difference of two outside feeRates or the global rate minus two outside fee rates.
    /// Because it is the result of differences it can be negative.
    function getTRangeFee(
        TickTable storage table,
        TableIndex low,
        TableIndex high,
        RangeBool rBool,
        Accum globalTX,
        Accum globalTY) internal view returns (FeeRateSnapshot memory takerSnap) {
        require(low.isLT(high), "TRF");

        // Data we fetch should be set. Fortunately this should happen
        // in a follow up step where liquidity is added to the table.
        TickData storage lowData = table.getData(low);
        TickData storage highData = table.getData(high);

        if (rBool == RangeBool.Below) {
            takerSnap.X = lowData.outsideFeeRateAccumX128.TX.diffAccum(highData.outsideFeeRateAccumX128.TX);
            takerSnap.Y = lowData.outsideFeeRateAccumX128.TY.diffAccum(highData.outsideFeeRateAccumX128.TY);
        } else if (rBool == RangeBool.Within) {
            takerSnap.X = globalTX.diffAccum(lowData.outsideFeeRateAccumX128.TX).diffAccum(highData.outsideFeeRateAccumX128.TX);
            takerSnap.Y = globalTY.diffAccum(lowData.outsideFeeRateAccumX128.TY).diffAccum(highData.outsideFeeRateAccumX128.TY);
        } else {
            takerSnap.X = highData.outsideFeeRateAccumX128.TX.diffAccum(lowData.outsideFeeRateAccumX128.TX);
            takerSnap.Y = highData.outsideFeeRateAccumX128.TY.diffAccum(lowData.outsideFeeRateAccumX128.TY);
        }
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { SwapMath } from "Swap/Math.sol";
import { Price, PriceImpl, SqrtPriceLib } from "Ticks/Tick.sol";
import { Q64X96 } from "Math/Ops.sol";
import { RangeLiq } from "Liq/Structs.sol";

// For LibDeployMath
import { FullMath } from "Math/FullMath.sol";
import { UnsafeMath } from "Math/UnsafeMath.sol";
import { MathUtils } from "Math/Utils.sol";
import { SafeCast } from "Math/Cast.sol";

library LiqMath {
    using PriceImpl for Price;

    // @notice Calculate the token holdings for a Maker.
    // @param roundUp Round up if we're opening the position or calculating borrows.
    // We round up user owed values and round down protocol owed values depending on the action.
    // This is to protect protocol solvency.
    function calcMakerHoldings(
        RangeLiq memory rLiq,
        Price currentSP,
        bool roundUp
    ) internal pure returns (uint256 x, uint256 y) {
        // On open, we round up the owed amount. On close we return the rounded down amount.
        return calcMakerHoldingsHelper(rLiq.lowSP, rLiq.highSP, currentSP, rLiq.liq, roundUp);
    }

    // @notice Underlying function to compute a Maker position's holdings.
    // This takes the sqrt prices directly so its more accessible for Asset.sol to use.
    function calcMakerHoldingsHelper(
        Price lowSP,
        Price highSP,
        Price currentSP,
        uint128 liq,
        bool roundUp
    ) internal pure returns (uint256 x, uint256 y) {
        if (currentSP.lt(lowSP)) {
            x = SwapMath.calcXFromPriceDelta(lowSP, highSP, liq, roundUp);
        } else if (currentSP.lt(highSP)) {
            x = SwapMath.calcXFromPriceDelta(currentSP, highSP, liq, roundUp);
            y = SwapMath.calcYFromPriceDelta(lowSP, currentSP, liq, roundUp);
        } else {
            y = SwapMath.calcYFromPriceDelta(lowSP, highSP, liq, roundUp);
        }
    }

    /// Calculate the holdings for a wide Maker.
    /// @dev We calculate x holdings as L/sqrt(P) and y holdings as Lsqrt(p)
    function calcWideMakerHoldings(Price currentSP, uint128 liq, bool roundUp)
    internal pure returns (uint256 x, uint256 y) {
        uint160 sp = currentSP.unwrap();
        x = Q64X96.div(liq, sp, roundUp);
        y = Q64X96.mul(sp, liq, roundUp);
    }

    /// Determine the terminal and borrowed balances of a Taker position when opening.
    /// @return terminalX The most amount of X the complementary Maker can have, rounded up.
    /// @return terminalY the most amount of Y the complementary Maker can have, rounded up.
    /// @return makerX The amount of X the complementary Maker current has, rounded up.
    /// @return makerY The amount of Y the complementary Maker current has, rounded up.
    function calcTakerAmounts(
        RangeLiq memory rLiq,
        Price currentSP
    ) internal pure returns (uint256 terminalX, uint256 terminalY, uint256 makerX, uint256 makerY) {
        uint160 lowX96 = rLiq.lowSP.unwrap();
        uint160 highX96 = rLiq.highSP.unwrap();
        uint128 liq = rLiq.liq;

        // We're essentially computing calc{X,Y} from price delta, but directly here to save gas.
        uint160 diffX96 = highX96 - lowX96;
        terminalY = Q64X96.unsafeMul(diffX96, liq, true);
        terminalX = UnsafeMath.divRoundingUp(FullMath.mulDiv(uint256(liq) << 96, diffX96, lowX96), highX96);

        (makerX, makerY) = calcMakerHoldingsHelper(rLiq.lowSP, rLiq.highSP, currentSP, liq, true);
    }

    // @notice Use this when we decrease the Taker Borrow Pool's balance. This DOES NOT
    // indicate how much Taker's repay or receive when borrowing. That is still determined
    // by the calcTaker functions. It just so happens on open, the borrowed values between
    // this function and the calcTaker functions are the same. On close, the borrowed amounts
    // from Makers and the borrow balancein the TBP are different.
    // @param originalSP The square root of the price the Taker was originally opened at.
    function calcTBPBorrow(
        Price lowSP,
        Price highSP,
        Price originalSP,
        uint128 liq
    ) internal pure returns (uint256 TBPX, uint256 TBPY) {
        (TBPX, TBPY) = calcMakerHoldingsHelper(lowSP, highSP, originalSP, liq, true);
    }
}

/// Helper library for liquidity related math that is specific to the deployment process.
library LiqDeployMath {
    // Deployers can seed the deployed pool with token amounts to start the pool.
    // See 2sAMMDiamond constructor for seed minimums.
    // We use the seeded amounts to determine the starting price and liquidity.
    // @dev The starting price and liquidity need to be computed together so we can
    // validate their implied quantities are not larger than the actual quantities.
    // This means there is the potential for lowering liquidity to satisfy
    // numerical imprecision in the price's square root.
    function calcWideSqrtPriceAndMLiq(uint256 amountX, uint256 amountY) internal pure returns (Price sqrtP, uint128 mLiq) {
        // First convert amounts into square roots because computing the ratio directly as X192 (2 * X96)
        // can easily overflow.
        uint256 sqrtX = MathUtils.sqrt(amountX); // Rounds down
        uint256 sqrtY = MathUtils.sqrt(amountY); // Rounds down

        uint256 sqrtPriceX96 = FullMath.mulDiv(1 << 96, sqrtX, sqrtY); // Rounds down the price
        sqrtP = SqrtPriceLib.make(SafeCast.toUint160(sqrtPriceX96));

        // Now there is some imprecision with the price. But this isn't an amount users get back,
        // this is just to give a pool the bare minimum in liquidity.

        // Due to this imprecision we calculate the mLiq in two ways and take the one that is smaller.
        // The chosen mLiq implies a certain amount of each token that can be traded against, and we
        // need to make sure that implied amount is less than the actual amount.
        uint128 yL = SafeCast.toUint128((amountY << 96) / sqrtPriceX96);
        uint128 xL = SafeCast.toUint128((amountX * sqrtPriceX96) >> 96);

        mLiq = xL < yL ? xL : yL;
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

type Accum is uint256;

/// Type accum is an accumulator variable that can overflow and wrap around.
/// It is used for values that grow in size but can't grow so fast that a user could reasonably wrap around.
/// For example a user might collect fees over the lifetime of their positions. 2^256 is so large
/// that it is practically impossible for them to wrap all the way around.
/// However we want to do this safely so we wrap this in a type that doesn't allow subtraction.
library AccumImpl {
    /// Construct accumulator from a uint value
    function from(uint256 num) public pure returns (Accum) {
        return Accum.wrap(num);
    }

    /// Construct accumulator from a signed int.
    function from(int256 num) public pure returns (Accum) {
        // We can just cast to a uint because all ints wrap around the same way which
        // is the only property we need here.
        return Accum.wrap(uint256(num));
    }

    /// Add to the accumulator.
    /// @param addend the value being added
    /// @return acc The new accumulated value
    function add(Accum self, uint256 addend) internal pure returns (Accum acc) {
        unchecked {
            return Accum.wrap(Accum.unwrap(self) + addend);
        }
    }

    /// Calc the difference between self and other. This tells us how much has accumulated.
    /// @param other the value being subtracted from the accumulation
    /// @return difference The difference between other and self which is always positive.
    function diff(Accum self, Accum other) internal pure returns (uint256) {
        unchecked { // underflow is okay
            return Accum.unwrap(self) - Accum.unwrap(other);
        }
    }

    /// Also calculates the difference between self and other, telling us the total accumlation.
    /// @return diffAccum The difference between self and other but as an Accum
    function diffAccum(Accum self, Accum other) internal pure returns (Accum) {
        return Accum.wrap(diff(self, other));
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;
import { TickIndex, TickIndexImpl, TickLib } from "Ticks/Tick.sol";
import { PriceImpl, Price } from "Ticks/Tick.sol";
import { TableIndex, TableIndexImpl } from "Ticks/Table.sol";
import { TickTable, TickTableImpl } from "Ticks/TickTable.sol";
import { StorageLib } from "../../src/Storage.sol";

/// Transient struct used by the LiqFacets for constructing assets and modifying liquidity.
struct RangeLiq {
    // We give each entry its own slot because we're not storing this so space is cheap
    // and we want it to be cheaply read and written to. So we make it the first
    // in a 256 bit slot.
    // This remains cheap as our as our memory usage is limited to below the quadratic range.
    uint128 liq;
    uint128 _padding0;
    /* 256 */
    TableIndex low; // 24
    uint232 _padding1;
    /* 256 */
    TableIndex high; // 24
    uint232 _padding2;
    /* 256 */
    Price lowSP; // 160
    uint96 _padding3;
    /* 256 */
    Price highSP; // 160
    uint96 _padding4;
    /* 256 */


}

library RangeLiqImpl {
    using PriceImpl for Price;
    using TickIndexImpl for TickIndex;
    using TickTableImpl for TickTable;
    using TableIndexImpl for TableIndex;

    /// Used by external functions to get a RangeLiq object to work with.
    function fromTicks(uint128 liq, int24 lowerTick, int24 upperTick) internal view returns (RangeLiq memory rLiq) {
        rLiq.liq = liq;

        // validates range
        TickIndex lowTickIndex = TickLib.newTickIndex(lowerTick);
        TickIndex highTickIndex = TickLib.newTickIndex(upperTick);

        // validates spacing
        TickTable storage table = StorageLib.table();
        table.validateTickIndexSpacing(lowTickIndex);
        table.validateTickIndexSpacing(highTickIndex);

        rLiq.lowSP = lowTickIndex.toSqrtPrice();
        rLiq.highSP = highTickIndex.toSqrtPrice();

        rLiq.low = table.getTableIndex(lowTickIndex);
        rLiq.high = table.getTableIndex(highTickIndex);
    }

    /// Used by assets to provide a RangeLiq object to work with.
    function fromTables(uint128 liq, TableIndex low, TableIndex high) internal view returns (RangeLiq memory rLiq) {
        rLiq.liq = liq;
        rLiq.low = low;
        rLiq.high = high;

        TickTable storage table = StorageLib.table();
        TickIndex lowerTick = table.getTickIndex(low);
        TickIndex upperTick = table.getTickIndex(high);

        rLiq.lowSP = lowerTick.toSqrtPrice();
        rLiq.highSP = upperTick.toSqrtPrice();
    }

    /// Return true if the table index is within the RangeLiq's range.
    function contains(RangeLiq memory self, TableIndex tabIdx) internal pure returns (bool) {
        return (self.low.isLTE(tabIdx) && tabIdx.isLT(self.high));
    }

    /// Return true if the price is within the RangeLiq's range.
    function contains(RangeLiq memory self, Price sqrtP) internal pure returns (bool) {
        return (self.lowSP.lteq(sqrtP) && sqrtP.lt(self.highSP));
    }

    /// Returns the Range bool for comparing a price to the range.
    function compare(RangeLiq memory self, Price sqrtP) internal pure returns (RangeBool) {
        if (sqrtP.lt(self.lowSP)) {
            return RangeBool.Below;
        } else if (sqrtP.lt(self.highSP)) {
            return RangeBool.Within;
        } else {
            return RangeBool.Above;
        }
    }
}

/// Enum for indicating where a value is relative to a given range.
/// Primarily used for indicating if the current price is within
/// a price range.
enum RangeBool {
    Below, // The comparison was below the range.
    Within, // The comparison value was within the range.
    Above // The comparison value was above the range.
}

/// Container for all the relevant token values of a position.
/// Just used in memory for when we value a position.
/// Maker positions only have cX and cY values;
struct Valuation {
    uint256 cX; // Creditted X
    uint256 cY; // Creditted Y
    uint256 dX; // Debted X
    uint256 dY; // Debted Y
    uint256 deltaX;
    uint256 deltaY;
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { Accum } from "Util/Accum.sol";

/// A snapshot of the inside fee rate at the time a position was opened/last updated.
struct FeeRateSnapshot {
    Accum X;
    Accum Y;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

/// Interface for interacting with AAVE v3 borrow/lending reserves.
interface IAAVEReserveData {
    /**
     * @notice Returns the reserve data
     * @param asset The address of the underlying asset of the reserve
     * @return unbacked The amount of unbacked tokens
     * @return accruedToTreasuryScaled The scaled amount of tokens accrued to treasury that is to be minted
     * @return totalAToken The total supply of the aToken
     * @return totalStableDebt The total stable debt of the reserve
     * @return totalVariableDebt The total variable debt of the reserve
     * @return liquidityRate The liquidity rate of the reserve
     * @return variableBorrowRate The variable borrow rate of the reserve
     * @return stableBorrowRate The stable borrow rate of the reserve
     * @return averageStableBorrowRate The average stable borrow rate of the reserve
     * @return liquidityIndex The liquidity index of the reserve
     * @return variableBorrowIndex The variable borrow index of the reserve
     * @return lastUpdateTimestamp The timestamp of the last update of the reserve
     */
  function getReserveData(
    address asset
  )
    external
    view
    returns (
      uint256 unbacked,
      uint256 accruedToTreasuryScaled,
      uint256 totalAToken,
      uint256 totalStableDebt,
      uint256 totalVariableDebt,
      uint256 liquidityRate,
      uint256 variableBorrowRate,
      uint256 stableBorrowRate,
      uint256 averageStableBorrowRate,
      uint256 liquidityIndex,
      uint256 variableBorrowIndex,
      uint40 lastUpdateTimestamp
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math functions that do not check inputs or outputs
/// @notice Contains methods that perform common math functions but do not do any overflow or underflow checks
library UnsafeMath {
    /// @notice Returns ceil(x / y)
    /// @dev division by 0 returns 0
    /// @param x The dividend
    /// @param y The divisor
    /// @return z The quotient, ceil(x / y)
    function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

/// Library for safe casting
library SafeCast {
    /// Casting too large an int to a signed int with the given maximum value.
    error UnsafeICast(uint256 val, int256 max);
    /// Casting too large an int to an unsigned int with the given maximum value.
    error UnsafeUCast(uint256 val, uint256 max);
    /// Casting a negative number to an unsigned int.
    error NegativeUCast(int256 val);

    function toUint256(int256 i) internal pure returns (uint256) {
        if (i < 0) {
            revert NegativeUCast(i);
        }
        return uint256(i);
    }

    function toInt256(uint256 u) internal pure returns (int256) {
        if (u > uint256(type(int256).max)) {
            revert UnsafeICast(u, type(int256).max);
        }
        return int256(u);
    }

    function toInt128(uint256 u) internal pure returns (int128) {
        if (u > uint256(uint128(type(int128).max))) {
            revert UnsafeICast(u, type(int128).max);
        }
        return int128(uint128(u));
    }

    function toUint128(uint256 u) internal pure returns (uint128) {
        if (u > type(uint128).max) {
            revert UnsafeUCast(u, type(uint128).max);
        }
        return uint128(u);
    }

    function toUint128(int256 i) internal pure returns (uint128) {
        return toUint128(toUint256(i));
    }

    function toUint160(uint256 u) internal pure returns (uint160) {
        if (u > type(uint160).max) {
            revert UnsafeUCast(u, type(uint160).max);
        }
        return uint160(u);
    }

    function toUint96(uint256 u) internal pure returns (uint96) {
        if (u > type(uint96).max) {
            revert UnsafeUCast(u, type(uint96).max);
        }
        return uint96(u);
    }

    function toUint96(int256 i) internal pure returns (uint96) {
        return toUint96(toUint256(i));
    }

    function toInt24(uint24 u) internal pure returns (int24) {
        if (u > uint24(type(int24).max)) {
            revert UnsafeICast(u, type(int24).max);
        }
        return int24(u);
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

/**
 * How administration of the pool is handled.
 * Establishes what privileges users can have.
 **/

library AdminFlags {
    // Someone who can submit precommits
    uint256 public constant SUBMIT = 0x1;

    // Rights for address that can accept the precommits
    uint256 public constant FEES = 0x2;
    uint256 public constant BORROW = 0x4;
    uint256 public constant TIMES = 0x8;

    // Defensive rights.
    uint256 public constant HALT = 0x100;
    uint256 public constant UNHALT = 0x200;
    uint256 public constant UNHALT_WITH_CHANGES = 0x600; // 400 | 200

    // High-powered rights.
    uint256 public constant VETO = 0x10000; // Blanket veto powers
    uint256 public constant CUT = 0x20000; // Timed Facet Cut powers

    // Misc.
    uint256 public constant COLLECT = 0x1000000; // Collect protocol's earned fees.
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { IERC173 } from "../ERC/interfaces/IERC173.sol";

/**
 * @title Administrative Library
 * @author Terence An
 * @notice This contains an administrative utility that uses diamond storage.
 * This is used to add and remove administrative privileges from addresses.
 * It also has validation functions for those privileges.
 * It adheres to ERC-173 which establishes an owernship standard.
 * @dev Administrative right assignments should be time-gated and veto-able for modern
 * contracts.
 **/

/// These are flags that can be joined so each is assigned its own hot bit.
/// @dev These flags get the very top bits so that user specific flags are given the lower bits.
library AdminFlags {
    uint256 public constant NULL  = 0; // No clearance at all. Default value.
    uint256 public constant OWNER = 0x8000000000000000000000000000000000000000000000000000000000000000;
    uint256 public constant VETO  = 0x4000000000000000000000000000000000000000000000000000000000000000;
}

struct AdminRegistry {
    // The owner actually does not have any rights except the ability to assign rights to users.
    // Of course it can assign rights to itself.
    // Thus it is probably desireable to qualify this ability, for example by time-gating it.
    address owner;

    // Rights are one hot encodings of permissions granted to users.
    // Each right should be a single bit in the uint256.
    mapping(address => uint256) rights;
}

/// Utility functions for checking, registering, and deregisterying administrative credentials
/// in a Diamond storage context. Most contracts that need this level of security sophistication
/// are probably large enough to required diamond storage.
library AdminLib {
    bytes32 constant ADMIN_STORAGE_POSITION = keccak256("v4.admin.diamond.storage");

    error NotOwner();
    error InsufficientCredentials(address caller, uint256 expectedRights, uint256 actualRights);
    error CannotReinitializeOwner(address existingOwner);

    event AdminAdded(address admin, uint256 newRight, uint256 existing);
    event AdminRemoved(address admin, uint256 removedRight, uint256 existing);

    function adminStore() internal pure returns (AdminRegistry storage adReg) {
        bytes32 position = ADMIN_STORAGE_POSITION;
        assembly {
            adReg.slot := position
        }
    }

    /* Getters */

    function getOwner() external view returns (address) {
        return adminStore().owner;
    }

    // @return lvl Will be cast to uint8 on return to external contracts.
    function getAdminRights(address addr) external view returns (uint256 rights) {
        return adminStore().rights[addr];
    }

    /* Validating Helpers */

    function validateOwner() internal view {
        if (msg.sender != adminStore().owner) {
            revert NotOwner();
        }
    }

    /// Revert if the msg.sender does not have the expected right.
    function validateRights(uint256 expected) internal view {
        AdminRegistry storage adReg = adminStore();
        uint256 actual = adReg.rights[msg.sender];
        if (actual & expected != expected) {
            revert InsufficientCredentials(msg.sender, expected, actual);
        }
    }

    /* Registry functions */

    /// Called when there is no owner so one can be set for the first time.
    function initOwner(address owner) internal {
        AdminRegistry storage adReg = adminStore();
        if (adReg.owner != address(0))
            revert CannotReinitializeOwner(adReg.owner);
        adReg.owner = owner;
    }

    /// Move ownership to another address
    /// @dev Remember to initialize the owner to a contract that can reassign on construction.
    function reassignOwner(address newOwner) internal {
        validateOwner();
        adminStore().owner = newOwner;
    }

    /// Add a right to an address
    /// @dev When actually using, the importing function should add restrictions to this.
    function register(address admin, uint256 right) internal {
        AdminRegistry storage adReg = adminStore();
        uint256 existing = adReg.rights[admin];
        adReg.rights[admin] = existing | right;
        emit AdminAdded(admin, right, existing);
    }

    /// Remove a right from an address.
    /// @dev When using, the wrapper function should add restrictions.
    function deregister(address admin, uint256 right) internal {
        AdminRegistry storage adReg = adminStore();
        uint256 existing = adReg.rights[admin];
        adReg.rights[admin] = existing & (~right);
        emit AdminRemoved(admin, right, existing);

    }
}

/// Base class for an admin facet with external interactions with the AdminLib
contract BaseAdminFacet is IERC173 {
    function transferOwnership(address _newOwner) external override {
        AdminLib.reassignOwner(_newOwner);
    }

    function owner() external override view returns (address owner_) {
        owner_ = AdminLib.getOwner();
    }

    /// Fetch the admin level for an address.
    function adminRights(address addr) external view returns (uint256 rights) {
        return AdminLib.getAdminRights(addr);
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

// Types
import { Price, PriceImpl, MIN_PRICE, MAX_PRICE, MAX_SQRT_RATIO } from "Ticks/Tick.sol";
// Utils
import { X96, Q64X96 } from "Math/Ops.sol";
import { MathUtils } from "Math/Utils.sol";
import { FullMath } from "Math/FullMath.sol";
import { UnsafeMath } from "Math/UnsafeMath.sol";


library SwapMath {
    using PriceImpl for Price;

    /// @notice Calculate the new price resulting from additional X
    /// @dev We round up to minimize price impact of X.
    /// We should also be sure to clamp this result after, because it could be below MIN_PRICE.
    /// We want to compute L\sqrt(P) / (L + x\sqrt(P))
    /// If liq is 0, slippage is infinite, and we snap to the minimum valid price.
    /// @param x The amount of x being exchanged. If 0 this reverts.
    function calcNewPriceFromAddX(
        uint128 liq,
        Price oldSqrtPrice,
        uint256 x
    ) public pure returns (Price newSqrtPrice) {
        if (liq == 0) {
            return MIN_PRICE;
        }

        // We're adding x, pushing down the price, we need to round up the price.
        uint256 liqX96 = uint256(liq) << 96;
        uint160 rp = Price.unwrap(oldSqrtPrice);
        uint256 xrp;
        unchecked {
            xrp = x * rp;
        }
        if ((xrp / x) == rp) { // If we don't overflow
            uint256 denom;
            unchecked {
                denom = xrp + liqX96;
            }
            if (denom > liqX96) { // Check the denom hasn't overflowed
                // Will always fit since denom >= liqX96
                return Price.wrap(uint160(FullMath.mulDivRoundingUp(liqX96, rp, denom)));
            }
        }
        // This will also always fit since liqx96/rp is 64 bits.
        return Price.wrap(uint160(UnsafeMath.divRoundingUp(liqX96, (liqX96 / rp) + x)));
    }

    /// @notice Calculate the new price resulting from removing X
    /// @dev We round up to maximize price impact from removing X.
    /// We want to compute L\sqrt(P) / (L - x\sqrt(P))
    /// If liq is 0, slippage is infinite, and we snap to the maximum valid price.
    function calcNewPriceFromSubX(
        uint128 liq,
        Price oldSqrtPrice,
        uint256 x
    ) public pure returns (Price newSqrtPrice) {
        if (liq == 0) {
            return MAX_PRICE;
        }
        uint256 liqX96 = uint256(liq) << 96;

        // We're removing x, pushing up the price. They expect a certain amount of x out,
        // so we have to round up.
        uint160 rp = Price.unwrap(oldSqrtPrice);
        uint256 xrp;
        unchecked {
            xrp = x * rp;
        }
        if ((xrp / x) == rp) { // If we don't overflow
            uint256 shortDenom;
            unchecked {
                shortDenom = liqX96 - xrp;
            }
            if (shortDenom < liqX96) { // Check the denom hasn't underflowed
                // This might go over max price.
                uint256 newSP = FullMath.mulDivRoundingUp(liqX96, rp, shortDenom);
                // We don't need this check on the down side because swap clamps the result
                // afterwards anyways. But here we really use this check to make sure the result
                // fits in a uint160 which it won't in the extremes. If we're checking for that
                // we might as well just clamp here now, ergo compare to MAX_SQRT_RATIO.
                if (newSP > MAX_SQRT_RATIO) {
                    return MAX_PRICE;
                } else {
                    return Price.wrap(uint160(newSP));
                }
            }
        }

        // This tick doesn't have sufficient liquidity to support this move.
        // So we return MAX_PRICE hoping some other tick is sufficient.
        uint256 ratio = liqX96 / rp;
        if (ratio < x) {
            return MAX_PRICE;
        }
        uint256 denom;
        unchecked { // Already checked
            denom = ratio - x;
        }
        return Price.wrap(uint160(UnsafeMath.divRoundingUp(liqX96, denom)));
    }

    /// @notice Calculate the new price resulting from adding Y
    /// @dev We round down to minimize price impact of adding Y.
    /// We want to compute y / L + \sqrt(P).
    /// If liq is 0, slippage is infinite, and we snap to the maximum valid price.
    function calcNewPriceFromAddY(
        uint128 liq,
        Price oldSqrtPrice,
        uint256 y
    ) public pure returns (Price newSqrtPrice) {
        if (liq == 0) {
            return MAX_PRICE;
        }

        // We're adding y which buys x and pushes the price up. Round down to minimize x bought.
        uint256 rp = Price.unwrap(oldSqrtPrice); // 160, but used as 256 to save gas

        // If y is small enough, we don't have to resort to full division.
        uint256 delta = ((y <= type(uint160).max)
                         ? (y << 96) / liq
                         : FullMath.mulDiv(X96.SHIFT, y, liq));

        // If this ticks liquidity is insufficient and will send the price crazy high,
        // we return MAX_PRICE and hope some other tick's liquidity is sufficient.
        // That high price might not fit in a uint160 so we might as well compare to
        // MAX_SQRT_RATIO anyways, and return that if we're too high.
        uint256 newSP = delta + rp;
        if (newSP > MAX_SQRT_RATIO) {
            return MAX_PRICE;
        }
        return Price.wrap(uint160(newSP));
    }

    /// @notice Calculate the new price resulting from subtracing Y
    /// @dev We round down to maximize the price impact of removing Y.
    /// We want to compute \sqrt(P) - y / L.
    /// If liq is 0, slippage is infinite, and we snap to the minimum valid price.
    function calcNewPriceFromSubY(
        uint128 liq,
        Price oldSqrtPrice,
        uint256 y
    ) public pure returns (Price newSqrtPrice) {
        if (liq == 0) {
            return MIN_PRICE;
        }

        // We're adding y which buys x and pushes the price up. Round down to minimize x bought.
        uint256 rp = Price.unwrap(oldSqrtPrice); // 160, but used as 256 to save gas

        // If y is small enough, we don't have to resort to full division.
        uint256 delta = ((y <= type(uint160).max)
                         ? (y << 96) / liq
                         : FullMath.mulDiv(X96.SHIFT, y, liq));

        // This tick doesn't have sufficient liquidty to support this move.
        // But we return MIN_PRICE hoping another tick is sufficient.
        if (delta >= rp) {
            return MIN_PRICE;
        }
        unchecked {
            return Price.wrap(uint160(rp - delta));
        }
    }

    /// @notice Given a price change, determine the corresponding change in X in absolute terms.
    /// @dev We are computing L(\sqrt{p} - \sqrt{p'}) / \sqrt{pp'} where p > p'
    /// If this is called for a zero liquidity region, the returned delta is 0.
    function calcXFromPriceDelta(
        Price lowSP,
        Price highSP,
        uint128 liq,
        bool roundUp
    ) internal pure returns (uint256 deltaX) {
        if (liq == 0) {
            return 0;
        }

        uint160 pX96 = highSP.unwrap();
        uint160 ppX96 = lowSP.unwrap();
        if (pX96 < ppX96) {
            (pX96, ppX96) = (ppX96, pX96);
        }

        uint256 diffX96 = pX96 - ppX96;
        uint256 liqX96 = uint256(liq) << 96;
        if (roundUp) {
            return UnsafeMath.divRoundingUp(FullMath.mulDivRoundingUp(liqX96, diffX96, pX96), ppX96);
        } else {
            return FullMath.mulDiv(liqX96, diffX96, pX96) / ppX96;
        }
    }

    /// @notice Given a price change, determine the corresponding change in Y in absolute terms.
    /// @dev We are computing L(\sqrt{p'} - \sqrt{p}) where p' > p;
    /// If this is called for a zero liquidity region, the returned delta is 0.
    /// This differs slightly from the Uniswap version. It's cheaper and matches identically.
    function calcYFromPriceDelta(
        Price lowSP,
        Price highSP,
        uint128 liq,
        bool roundUp
    ) internal pure returns (uint256 deltaY) {
        if (liq == 0) {
            return 0;
        }

        uint160 pX96 = lowSP.unwrap();
        uint160 ppX96 = highSP.unwrap();
        if (ppX96 < pX96) {
            (pX96, ppX96) = (ppX96, pX96);
        }

        uint160 diffX96 = ppX96 - pX96;
        // We know this uses at most 128 bits and 160.
        return Q64X96.unsafeMul(diffX96, liq, roundUp);
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

library MathUtils {

    function abs(int256 self) internal pure returns (int256) {
        return self >= 0 ? self : -self;
    }

    /// @notice Calculates the square root of x using the Babylonian method.
    ///
    /// @dev See https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    /// Copied from PRBMath: https://github.com/PaulRBerg/prb-math/blob/83b3a0dcd4aaca779d0632118772f00611340e79/src/Common.sol
    ///
    /// Notes:
    /// - If x is not a perfect square, the result is rounded down.
    /// - Credits to OpenZeppelin for the explanations in comments below.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as a uint256.
    /// @custom:smtchecker abstract-function-nondet
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // For our first guess, we calculate the biggest power of 2 which is smaller than the square root of x.
        //
        // We know that the "msb" (most significant bit) of x is a power of 2 such that we have:
        //
        // $$
        // msb(x) <= x <= 2*msb(x)$
        // $$
        //
        // We write $msb(x)$ as $2^k$, and we get:
        //
        // $$
        // k = log_2(x)
        // $$
        //
        // Thus, we can write the initial inequality as:
        //
        // $$
        // 2^{log_2(x)} <= x <= 2*2^{log_2(x)+1}
        // sqrt(2^k) <= sqrt(x) < sqrt(2^{k+1})
        // 2^{k/2} <= sqrt(x) < 2^{(k+1)/2} <= 2^{(k/2)+1}
        // $$
        //
        // Consequently, $2^{log_2(x) /2} is a good first approximation of sqrt(x) with at least one correct bit.
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 2 ** 128) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 2 ** 64) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 2 ** 32) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 2 ** 16) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 2 ** 8) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 2 ** 4) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 2 ** 2) {
            result <<= 1;
        }

        // At this point, `result` is an estimation with at least one bit of precision. We know the true value has at
        // most 128 bits, since it is the square root of a uint256. Newton's method converges quadratically (precision
        // doubles at every iteration). We thus need at most 7 iteration to turn our partial result with one bit of
        // precision into the expected uint128 result.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;

            // If x is not a perfect square, round the result toward zero.
            uint256 roundedResult = x / result;
            if (result >= roundedResult) {
                result = roundedResult;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}