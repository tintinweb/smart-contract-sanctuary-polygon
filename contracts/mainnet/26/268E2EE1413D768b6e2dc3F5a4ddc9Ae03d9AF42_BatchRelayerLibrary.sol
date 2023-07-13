// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

import "../solidity-utils/openzeppelin/IERC20.sol";

/**
 * @dev Base minter interface, applicable to Mainnet minter or L2 pseudo minters.
 */
interface IBalancerMinter {
    event Minted(address indexed recipient, address gauge, uint256 minted);

    /**
     * @notice Returns the address of the Balancer Governance Token
     */
    function getBalancerToken() external view returns (IERC20);

    /**
     * @notice Mint everything which belongs to `msg.sender` and send to them
     * @param gauge `LiquidityGauge` address to get mintable amount from
     */
    function mint(address gauge) external returns (uint256);

    /**
     * @notice Mint everything which belongs to `msg.sender` across multiple gauges
     * @param gauges List of `LiquidityGauge` addresses
     */
    function mintMany(address[] calldata gauges) external returns (uint256);

    /**
     * @notice Mint tokens for `user`
     * @dev Only possible when `msg.sender` has been approved by `user` to mint on their behalf
     * @param gauge `LiquidityGauge` address to get mintable amount from
     * @param user Address to mint to
     */
    function mintFor(address gauge, address user) external returns (uint256);

    /**
     * @notice Mint tokens for `user` across multiple gauges
     * @dev Only possible when `msg.sender` has been approved by `user` to mint on their behalf
     * @param gauges List of `LiquidityGauge` addresses
     * @param user Address to mint to
     */
    function mintManyFor(address[] calldata gauges, address user) external returns (uint256);

    /**
     * @notice The total number of tokens minted for `user` from `gauge`
     */
    function minted(address user, address gauge) external view returns (uint256);

    /**
     * @notice Whether `minter` is approved to mint tokens for `user`
     */
    function getMinterApproval(address minter, address user) external view returns (bool);

    /**
     * @notice Set whether `minter` is approved to mint tokens on your behalf
     */
    function setMinterApproval(address minter, bool approval) external;

    /**
     * @notice Set whether `minter` is approved to mint tokens on behalf of `user`, who has signed a message authorizing
     * them.
     */
    function setMinterApprovalWithSignature(
        address minter,
        bool approval,
        address user,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    // The below functions are near-duplicates of functions available above.
    // They are included for ABI compatibility with snake_casing as used in vyper contracts.
    // solhint-disable func-name-mixedcase

    /**
     * @notice Whether `minter` is approved to mint tokens for `user`
     */
    function allowed_to_mint_for(address minter, address user) external view returns (bool);

    /**
     * @notice Mint everything which belongs to `msg.sender` across multiple gauges
     * @dev This function is not recommended as `mintMany()` is more flexible and gas efficient
     * @param gauges List of `LiquidityGauge` addresses
     */
    function mint_many(address[8] calldata gauges) external;

    /**
     * @notice Mint tokens for `user`
     * @dev Only possible when `msg.sender` has been approved by `user` to mint on their behalf
     * @param gauge `LiquidityGauge` address to get mintable amount from
     * @param user Address to mint to
     */
    function mint_for(address gauge, address user) external;

    /**
     * @notice Toggle whether `minter` is approved to mint tokens for `user`
     */
    function toggle_approve_mint(address minter) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

// For compatibility, we're keeping the same function names as in the original Curve code, including the mixed-case
// naming convention.
// solhint-disable func-name-mixedcase
// solhint-disable func-param-name-mixedcase

interface ILiquidityGauge {
    // solhint-disable-next-line var-name-mixedcase
    event RelativeWeightCapChanged(uint256 new_relative_weight_cap);

    /**
     * @notice Returns BAL liquidity emissions calculated during checkpoints for the given user.
     * @param user User address.
     * @return uint256 BAL amount to issue for the address.
     */
    function integrate_fraction(address user) external view returns (uint256);

    /**
     * @notice Record a checkpoint for a given user.
     * @param user User address.
     * @return bool Always true.
     */
    function user_checkpoint(address user) external returns (bool);

    /**
     * @notice Returns true if gauge is killed; false otherwise.
     */
    function is_killed() external view returns (bool);

    /**
     * @notice Kills the gauge so it cannot mint BAL.
     */
    function killGauge() external;

    /**
     * @notice Unkills the gauge so it can mint BAL again.
     */
    function unkillGauge() external;

    /**
     * @notice Sets a new relative weight cap for the gauge.
     * The value shall be normalized to 1e18, and not greater than MAX_RELATIVE_WEIGHT_CAP.
     * @param relativeWeightCap New relative weight cap.
     */
    function setRelativeWeightCap(uint256 relativeWeightCap) external;

    /**
     * @notice Gets the relative weight cap for the gauge.
     */
    function getRelativeWeightCap() external view returns (uint256);

    /**
     * @notice Returns the gauge's relative weight for a given time, capped to its relative weight cap attribute.
     * @param time Timestamp in the past or present.
     */
    function getCappedRelativeWeight(uint256 time) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../solidity-utils/openzeppelin/IERC20.sol";

// For compatibility, we're keeping the same function names as in the original Curve code, including the mixed-case
// naming convention.
// solhint-disable func-name-mixedcase, var-name-mixedcase

interface IRewardTokenDistributor {
    struct Reward {
        IERC20 token;
        address distributor;
        uint256 period_finish;
        uint256 rate;
        uint256 last_update;
        uint256 integral;
    }

    function reward_tokens(uint256 index) external view returns (IERC20);

    function reward_data(IERC20 token) external view returns (Reward memory);

    function claim_rewards(address user) external;

    function add_reward(IERC20 rewardToken, address distributor) external;

    function set_reward_distributor(IERC20 rewardToken, address distributor) external;

    function deposit_reward_token(IERC20 rewardToken, uint256 amount) external;

    function claimable_reward(address rewardToken, address user) external view returns (uint256);

    function claimable_reward_write(address rewardToken, address user) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../solidity-utils/openzeppelin/IERC20.sol";

import "./ILiquidityGauge.sol";
import "./IRewardTokenDistributor.sol";

// For compatibility, we're keeping the same function names as in the original Curve code, including the mixed-case
// naming convention.
// solhint-disable func-name-mixedcase, var-name-mixedcase

interface IStakingLiquidityGauge is IRewardTokenDistributor, ILiquidityGauge, IERC20 {
    function initialize(address lpToken, uint256 relativeWeightCap) external;

    function lp_token() external view returns (IERC20);

    function deposit(uint256 value, address recipient) external;

    function withdraw(uint256 value) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

library StablePoolUserData {
    enum JoinKind { INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT, ALL_TOKENS_IN_FOR_EXACT_BPT_OUT }
    enum ExitKind { EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT, EXACT_BPT_IN_FOR_ALL_TOKENS_OUT }

    function joinKind(bytes memory self) internal pure returns (JoinKind) {
        return abi.decode(self, (JoinKind));
    }

    function exitKind(bytes memory self) internal pure returns (ExitKind) {
        return abi.decode(self, (ExitKind));
    }

    // Joins

    function initialAmountsIn(bytes memory self) internal pure returns (uint256[] memory amountsIn) {
        (, amountsIn) = abi.decode(self, (JoinKind, uint256[]));
    }

    function exactTokensInForBptOut(bytes memory self)
        internal
        pure
        returns (uint256[] memory amountsIn, uint256 minBPTAmountOut)
    {
        (, amountsIn, minBPTAmountOut) = abi.decode(self, (JoinKind, uint256[], uint256));
    }

    function tokenInForExactBptOut(bytes memory self) internal pure returns (uint256 bptAmountOut, uint256 tokenIndex) {
        (, bptAmountOut, tokenIndex) = abi.decode(self, (JoinKind, uint256, uint256));
    }

    function allTokensInForExactBptOut(bytes memory self) internal pure returns (uint256 bptAmountOut) {
        (, bptAmountOut) = abi.decode(self, (JoinKind, uint256));
    }

    // Exits

    function exactBptInForTokenOut(bytes memory self) internal pure returns (uint256 bptAmountIn, uint256 tokenIndex) {
        (, bptAmountIn, tokenIndex) = abi.decode(self, (ExitKind, uint256, uint256));
    }

    function exactBptInForTokensOut(bytes memory self) internal pure returns (uint256 bptAmountIn) {
        (, bptAmountIn) = abi.decode(self, (ExitKind, uint256));
    }

    function bptInForExactTokensOut(bytes memory self)
        internal
        pure
        returns (uint256[] memory amountsOut, uint256 maxBPTAmountIn)
    {
        (, amountsOut, maxBPTAmountIn) = abi.decode(self, (ExitKind, uint256[], uint256));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

import "../solidity-utils/openzeppelin/IERC20.sol";

library WeightedPoolUserData {
    // In order to preserve backwards compatibility, make sure new join and exit kinds are added at the end of the enum.
    enum JoinKind { INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT, ALL_TOKENS_IN_FOR_EXACT_BPT_OUT }
    enum ExitKind { EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, EXACT_BPT_IN_FOR_TOKENS_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT }

    function joinKind(bytes memory self) internal pure returns (JoinKind) {
        return abi.decode(self, (JoinKind));
    }

    function exitKind(bytes memory self) internal pure returns (ExitKind) {
        return abi.decode(self, (ExitKind));
    }

    // Joins

    function initialAmountsIn(bytes memory self) internal pure returns (uint256[] memory amountsIn) {
        (, amountsIn) = abi.decode(self, (JoinKind, uint256[]));
    }

    function exactTokensInForBptOut(bytes memory self)
        internal
        pure
        returns (uint256[] memory amountsIn, uint256 minBPTAmountOut)
    {
        (, amountsIn, minBPTAmountOut) = abi.decode(self, (JoinKind, uint256[], uint256));
    }

    function tokenInForExactBptOut(bytes memory self) internal pure returns (uint256 bptAmountOut, uint256 tokenIndex) {
        (, bptAmountOut, tokenIndex) = abi.decode(self, (JoinKind, uint256, uint256));
    }

    function allTokensInForExactBptOut(bytes memory self) internal pure returns (uint256 bptAmountOut) {
        (, bptAmountOut) = abi.decode(self, (JoinKind, uint256));
    }

    // Exits

    function exactBptInForTokenOut(bytes memory self) internal pure returns (uint256 bptAmountIn, uint256 tokenIndex) {
        (, bptAmountIn, tokenIndex) = abi.decode(self, (ExitKind, uint256, uint256));
    }

    function exactBptInForTokensOut(bytes memory self) internal pure returns (uint256 bptAmountIn) {
        (, bptAmountIn) = abi.decode(self, (ExitKind, uint256));
    }

    function bptInForExactTokensOut(bytes memory self)
        internal
        pure
        returns (uint256[] memory amountsOut, uint256 maxBPTAmountIn)
    {
        (, amountsOut, maxBPTAmountIn) = abi.decode(self, (ExitKind, uint256[], uint256));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.1 <0.9.0;

// solhint-disable

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 * Uses the default 'BAL' prefix for the error code
 */
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) _revert(errorCode);
}

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 */
function _require(
    bool condition,
    uint256 errorCode,
    bytes3 prefix
) pure {
    if (!condition) _revert(errorCode, prefix);
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 * Uses the default 'BAL' prefix for the error code
 */
function _revert(uint256 errorCode) pure {
    _revert(errorCode, 0x42414c); // This is the raw byte representation of "BAL"
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
function _revert(uint256 errorCode, bytes3 prefix) pure {
    uint256 prefixUint = uint256(uint24(prefix));
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // 'BAL#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full string.
        // We first append the '#' character (0x23) to the prefix. In the case of 'BAL', it results in 0x42414c23 ('BAL#')
        // Then, we shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).
        let formattedPrefix := shl(24, add(0x23, shl(8, prefixUint)))

        let revertReason := shl(200, add(formattedPrefix, add(add(units, shl(8, tenths)), shl(16, hundreds))))

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
        // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        // The string length is fixed: 7 characters.
        mstore(0x24, 7)
        // Finally, the string itself is stored.
        mstore(0x44, revertReason)

        // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}

library Errors {
    // Math
    uint256 internal constant ADD_OVERFLOW = 0;
    uint256 internal constant SUB_OVERFLOW = 1;
    uint256 internal constant SUB_UNDERFLOW = 2;
    uint256 internal constant MUL_OVERFLOW = 3;
    uint256 internal constant ZERO_DIVISION = 4;
    uint256 internal constant DIV_INTERNAL = 5;
    uint256 internal constant X_OUT_OF_BOUNDS = 6;
    uint256 internal constant Y_OUT_OF_BOUNDS = 7;
    uint256 internal constant PRODUCT_OUT_OF_BOUNDS = 8;
    uint256 internal constant INVALID_EXPONENT = 9;

    // Input
    uint256 internal constant OUT_OF_BOUNDS = 100;
    uint256 internal constant UNSORTED_ARRAY = 101;
    uint256 internal constant UNSORTED_TOKENS = 102;
    uint256 internal constant INPUT_LENGTH_MISMATCH = 103;
    uint256 internal constant ZERO_TOKEN = 104;
    uint256 internal constant INSUFFICIENT_DATA = 105;

    // Shared pools
    uint256 internal constant MIN_TOKENS = 200;
    uint256 internal constant MAX_TOKENS = 201;
    uint256 internal constant MAX_SWAP_FEE_PERCENTAGE = 202;
    uint256 internal constant MIN_SWAP_FEE_PERCENTAGE = 203;
    uint256 internal constant MINIMUM_BPT = 204;
    uint256 internal constant CALLER_NOT_VAULT = 205;
    uint256 internal constant UNINITIALIZED = 206;
    uint256 internal constant BPT_IN_MAX_AMOUNT = 207;
    uint256 internal constant BPT_OUT_MIN_AMOUNT = 208;
    uint256 internal constant EXPIRED_PERMIT = 209;
    uint256 internal constant NOT_TWO_TOKENS = 210;
    uint256 internal constant DISABLED = 211;

    // Pools
    uint256 internal constant MIN_AMP = 300;
    uint256 internal constant MAX_AMP = 301;
    uint256 internal constant MIN_WEIGHT = 302;
    uint256 internal constant MAX_STABLE_TOKENS = 303;
    uint256 internal constant MAX_IN_RATIO = 304;
    uint256 internal constant MAX_OUT_RATIO = 305;
    uint256 internal constant MIN_BPT_IN_FOR_TOKEN_OUT = 306;
    uint256 internal constant MAX_OUT_BPT_FOR_TOKEN_IN = 307;
    uint256 internal constant NORMALIZED_WEIGHT_INVARIANT = 308;
    uint256 internal constant INVALID_TOKEN = 309;
    uint256 internal constant UNHANDLED_JOIN_KIND = 310;
    uint256 internal constant ZERO_INVARIANT = 311;
    uint256 internal constant ORACLE_INVALID_SECONDS_QUERY = 312;
    uint256 internal constant ORACLE_NOT_INITIALIZED = 313;
    uint256 internal constant ORACLE_QUERY_TOO_OLD = 314;
    uint256 internal constant ORACLE_INVALID_INDEX = 315;
    uint256 internal constant ORACLE_BAD_SECS = 316;
    uint256 internal constant AMP_END_TIME_TOO_CLOSE = 317;
    uint256 internal constant AMP_ONGOING_UPDATE = 318;
    uint256 internal constant AMP_RATE_TOO_HIGH = 319;
    uint256 internal constant AMP_NO_ONGOING_UPDATE = 320;
    uint256 internal constant STABLE_INVARIANT_DIDNT_CONVERGE = 321;
    uint256 internal constant STABLE_GET_BALANCE_DIDNT_CONVERGE = 322;
    uint256 internal constant RELAYER_NOT_CONTRACT = 323;
    uint256 internal constant BASE_POOL_RELAYER_NOT_CALLED = 324;
    uint256 internal constant REBALANCING_RELAYER_REENTERED = 325;
    uint256 internal constant GRADUAL_UPDATE_TIME_TRAVEL = 326;
    uint256 internal constant SWAPS_DISABLED = 327;
    uint256 internal constant CALLER_IS_NOT_LBP_OWNER = 328;
    uint256 internal constant PRICE_RATE_OVERFLOW = 329;
    uint256 internal constant INVALID_JOIN_EXIT_KIND_WHILE_SWAPS_DISABLED = 330;
    uint256 internal constant WEIGHT_CHANGE_TOO_FAST = 331;
    uint256 internal constant LOWER_GREATER_THAN_UPPER_TARGET = 332;
    uint256 internal constant UPPER_TARGET_TOO_HIGH = 333;
    uint256 internal constant UNHANDLED_BY_LINEAR_POOL = 334;
    uint256 internal constant OUT_OF_TARGET_RANGE = 335;
    uint256 internal constant UNHANDLED_EXIT_KIND = 336;
    uint256 internal constant UNAUTHORIZED_EXIT = 337;
    uint256 internal constant MAX_MANAGEMENT_SWAP_FEE_PERCENTAGE = 338;
    uint256 internal constant UNHANDLED_BY_MANAGED_POOL = 339;
    uint256 internal constant UNHANDLED_BY_PHANTOM_POOL = 340;
    uint256 internal constant TOKEN_DOES_NOT_HAVE_RATE_PROVIDER = 341;
    uint256 internal constant INVALID_INITIALIZATION = 342;
    uint256 internal constant OUT_OF_NEW_TARGET_RANGE = 343;
    uint256 internal constant FEATURE_DISABLED = 344;
    uint256 internal constant UNINITIALIZED_POOL_CONTROLLER = 345;
    uint256 internal constant SET_SWAP_FEE_DURING_FEE_CHANGE = 346;
    uint256 internal constant SET_SWAP_FEE_PENDING_FEE_CHANGE = 347;
    uint256 internal constant CHANGE_TOKENS_DURING_WEIGHT_CHANGE = 348;
    uint256 internal constant CHANGE_TOKENS_PENDING_WEIGHT_CHANGE = 349;
    uint256 internal constant MAX_WEIGHT = 350;
    uint256 internal constant UNAUTHORIZED_JOIN = 351;
    uint256 internal constant MAX_MANAGEMENT_AUM_FEE_PERCENTAGE = 352;
    uint256 internal constant FRACTIONAL_TARGET = 353;
    uint256 internal constant ADD_OR_REMOVE_BPT = 354;
    uint256 internal constant INVALID_CIRCUIT_BREAKER_BOUNDS = 355;
    uint256 internal constant CIRCUIT_BREAKER_TRIPPED = 356;
    uint256 internal constant MALICIOUS_QUERY_REVERT = 357;
    uint256 internal constant JOINS_EXITS_DISABLED = 358;

    // Lib
    uint256 internal constant REENTRANCY = 400;
    uint256 internal constant SENDER_NOT_ALLOWED = 401;
    uint256 internal constant PAUSED = 402;
    uint256 internal constant PAUSE_WINDOW_EXPIRED = 403;
    uint256 internal constant MAX_PAUSE_WINDOW_DURATION = 404;
    uint256 internal constant MAX_BUFFER_PERIOD_DURATION = 405;
    uint256 internal constant INSUFFICIENT_BALANCE = 406;
    uint256 internal constant INSUFFICIENT_ALLOWANCE = 407;
    uint256 internal constant ERC20_TRANSFER_FROM_ZERO_ADDRESS = 408;
    uint256 internal constant ERC20_TRANSFER_TO_ZERO_ADDRESS = 409;
    uint256 internal constant ERC20_MINT_TO_ZERO_ADDRESS = 410;
    uint256 internal constant ERC20_BURN_FROM_ZERO_ADDRESS = 411;
    uint256 internal constant ERC20_APPROVE_FROM_ZERO_ADDRESS = 412;
    uint256 internal constant ERC20_APPROVE_TO_ZERO_ADDRESS = 413;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_ALLOWANCE = 414;
    uint256 internal constant ERC20_DECREASED_ALLOWANCE_BELOW_ZERO = 415;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_BALANCE = 416;
    uint256 internal constant ERC20_BURN_EXCEEDS_ALLOWANCE = 417;
    uint256 internal constant SAFE_ERC20_CALL_FAILED = 418;
    uint256 internal constant ADDRESS_INSUFFICIENT_BALANCE = 419;
    uint256 internal constant ADDRESS_CANNOT_SEND_VALUE = 420;
    uint256 internal constant SAFE_CAST_VALUE_CANT_FIT_INT256 = 421;
    uint256 internal constant GRANT_SENDER_NOT_ADMIN = 422;
    uint256 internal constant REVOKE_SENDER_NOT_ADMIN = 423;
    uint256 internal constant RENOUNCE_SENDER_NOT_ALLOWED = 424;
    uint256 internal constant BUFFER_PERIOD_EXPIRED = 425;
    uint256 internal constant CALLER_IS_NOT_OWNER = 426;
    uint256 internal constant NEW_OWNER_IS_ZERO = 427;
    uint256 internal constant CODE_DEPLOYMENT_FAILED = 428;
    uint256 internal constant CALL_TO_NON_CONTRACT = 429;
    uint256 internal constant LOW_LEVEL_CALL_FAILED = 430;
    uint256 internal constant NOT_PAUSED = 431;
    uint256 internal constant ADDRESS_ALREADY_ALLOWLISTED = 432;
    uint256 internal constant ADDRESS_NOT_ALLOWLISTED = 433;
    uint256 internal constant ERC20_BURN_EXCEEDS_BALANCE = 434;
    uint256 internal constant INVALID_OPERATION = 435;
    uint256 internal constant CODEC_OVERFLOW = 436;
    uint256 internal constant IN_RECOVERY_MODE = 437;
    uint256 internal constant NOT_IN_RECOVERY_MODE = 438;
    uint256 internal constant INDUCED_FAILURE = 439;
    uint256 internal constant EXPIRED_SIGNATURE = 440;
    uint256 internal constant MALFORMED_SIGNATURE = 441;
    uint256 internal constant SAFE_CAST_VALUE_CANT_FIT_UINT64 = 442;
    uint256 internal constant UNHANDLED_FEE_TYPE = 443;
    uint256 internal constant BURN_FROM_ZERO = 444;

    // Vault
    uint256 internal constant INVALID_POOL_ID = 500;
    uint256 internal constant CALLER_NOT_POOL = 501;
    uint256 internal constant SENDER_NOT_ASSET_MANAGER = 502;
    uint256 internal constant USER_DOESNT_ALLOW_RELAYER = 503;
    uint256 internal constant INVALID_SIGNATURE = 504;
    uint256 internal constant EXIT_BELOW_MIN = 505;
    uint256 internal constant JOIN_ABOVE_MAX = 506;
    uint256 internal constant SWAP_LIMIT = 507;
    uint256 internal constant SWAP_DEADLINE = 508;
    uint256 internal constant CANNOT_SWAP_SAME_TOKEN = 509;
    uint256 internal constant UNKNOWN_AMOUNT_IN_FIRST_SWAP = 510;
    uint256 internal constant MALCONSTRUCTED_MULTIHOP_SWAP = 511;
    uint256 internal constant INTERNAL_BALANCE_OVERFLOW = 512;
    uint256 internal constant INSUFFICIENT_INTERNAL_BALANCE = 513;
    uint256 internal constant INVALID_ETH_INTERNAL_BALANCE = 514;
    uint256 internal constant INVALID_POST_LOAN_BALANCE = 515;
    uint256 internal constant INSUFFICIENT_ETH = 516;
    uint256 internal constant UNALLOCATED_ETH = 517;
    uint256 internal constant ETH_TRANSFER = 518;
    uint256 internal constant CANNOT_USE_ETH_SENTINEL = 519;
    uint256 internal constant TOKENS_MISMATCH = 520;
    uint256 internal constant TOKEN_NOT_REGISTERED = 521;
    uint256 internal constant TOKEN_ALREADY_REGISTERED = 522;
    uint256 internal constant TOKENS_ALREADY_SET = 523;
    uint256 internal constant TOKENS_LENGTH_MUST_BE_2 = 524;
    uint256 internal constant NONZERO_TOKEN_BALANCE = 525;
    uint256 internal constant BALANCE_TOTAL_OVERFLOW = 526;
    uint256 internal constant POOL_NO_TOKENS = 527;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_BALANCE = 528;

    // Fees
    uint256 internal constant SWAP_FEE_PERCENTAGE_TOO_HIGH = 600;
    uint256 internal constant FLASH_LOAN_FEE_PERCENTAGE_TOO_HIGH = 601;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_FEE_AMOUNT = 602;
    uint256 internal constant AUM_FEE_PERCENTAGE_TOO_HIGH = 603;

    // FeeSplitter
    uint256 internal constant SPLITTER_FEE_PERCENTAGE_TOO_HIGH = 700;

    // Misc
    uint256 internal constant UNIMPLEMENTED = 998;
    uint256 internal constant SHOULD_NOT_HAPPEN = 999;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

interface IAuthentication {
    /**
     * @dev Returns the action identifier associated with the external function described by `selector`.
     */
    function getActionId(bytes4 selector) external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev Interface for the SignatureValidator helper, used to support meta-transactions.
 */
interface ISignaturesValidator {
    /**
     * @dev Returns the EIP712 domain separator.
     */
    function getDomainSeparator() external view returns (bytes32);

    /**
     * @dev Returns the next nonce used by an address to sign messages.
     */
    function getNextNonce(address user) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev Interface for the TemporarilyPausable helper.
 */
interface ITemporarilyPausable {
    /**
     * @dev Emitted every time the pause state changes by `_setPaused`.
     */
    event PausedStateChanged(bool paused);

    /**
     * @dev Returns the current paused state.
     */
    function getPausedState()
        external
        view
        returns (
            bool paused,
            uint256 pauseWindowEndTime,
            uint256 bufferPeriodEndTime
        );
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

/**
 * @notice Simple interface to retrieve the version of a deployed contract.
 */
interface IVersion {
    /**
     * @dev Returns a JSON representation of the contract version containing name, version number and task ID.
     */
    function version() external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

import "../openzeppelin/IERC20.sol";

interface IERC4626 is IERC20 {
    /**
     * @dev `caller` has exchanged `assets` for `shares`, and transferred those `shares` to `owner`.
     */
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    /**
     * @dev `caller` has exchanged `shares`, owned by `owner`, for `assets`,
     *      and transferred those `assets` to `receiver`.
     */
    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Mints `shares` Vault shares to `receiver` by depositing exactly `amount` of underlying tokens.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Burns exactly `shares` from `owner` and sends `assets` of underlying tokens to `receiver`.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);

    /**
     * @dev The address of the underlying token that the Vault uses for accounting, depositing, and withdrawing.
     */
    function asset() external view returns (address);

    /**
     * @dev Total amount of the underlying asset that is “managed” by Vault.
     */
    function totalAssets() external view returns (uint256);

    /**
     * @dev The amount of `assets` that the Vault would exchange for the amount
     *      of `shares` provided, in an ideal scenario where all the conditions are met.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev The amount of `shares` that the Vault would exchange for the amount
     *      of `assets` provided, in an ideal scenario where all the conditions are met.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

import "../openzeppelin/IERC20.sol";

/**
 * @dev Interface for WETH9.
 * See https://github.com/gnosis/canonical-weth/blob/0dd1ea3e295eef916d0c6223ec63141137d22d67/contracts/WETH9.sol
 */
interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

interface IERC20PermitDAI {
    /**
     * @notice update allowance with a signed permit
     * @param holder    Token owner's address (Authorizer)
     * @param spender   Spender's address
     * @param nonce     The permit nonce
     * @param expiry    The time at which this expires (unix time)
     * @param allowed   Whether the spender is allowed or disallowed from spending
     * @param v         v of the signature
     * @param r         r of the signature
     * @param s         s of the signature
     */
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../vault/IVault.sol";

/**
 * @title IBalancerRelayer
 * @notice Allows safe multicall execution of a relayer's functions
 */
interface IBalancerRelayer {
    function getLibrary() external view returns (address);

    function getVault() external view returns (IVault);

    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

// Source: https://github.com/buttonwood-protocol/button-wrappers/blob/main/contracts/interfaces/IButtonWrapper.sol
// Interface definition for ButtonWrapper contract, which wraps an
// underlying ERC20 token into a new ERC20 with different characteristics.
// NOTE: "uAmount" => underlying token (wrapped) amount and
//       "amount" => wrapper token amount
interface IButtonWrapper {
    //--------------------------------------------------------------------------
    // ButtonWrapper write methods

    /// @notice Transfers underlying tokens from {msg.sender} to the contract and
    ///         mints wrapper tokens.
    /// @param amount The amount of wrapper tokens to mint.
    /// @return The amount of underlying tokens deposited.
    function mint(uint256 amount) external returns (uint256);

    /// @notice Transfers underlying tokens from {msg.sender} to the contract and
    ///         mints wrapper tokens to the specified beneficiary.
    /// @param to The beneficiary account.
    /// @param amount The amount of wrapper tokens to mint.
    /// @return The amount of underlying tokens deposited.
    function mintFor(address to, uint256 amount) external returns (uint256);

    /// @notice Burns wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens back.
    /// @param amount The amount of wrapper tokens to burn.
    /// @return The amount of underlying tokens withdrawn.
    function burn(uint256 amount) external returns (uint256);

    /// @notice Burns wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens to the specified beneficiary.
    /// @param to The beneficiary account.
    /// @param amount The amount of wrapper tokens to burn.
    /// @return The amount of underlying tokens withdrawn.
    function burnTo(address to, uint256 amount) external returns (uint256);

    /// @notice Burns all wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens back.
    /// @return The amount of underlying tokens withdrawn.
    function burnAll() external returns (uint256);

    /// @notice Burns all wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens back.
    /// @param to The beneficiary account.
    /// @return The amount of underlying tokens withdrawn.
    function burnAllTo(address to) external returns (uint256);

    /// @notice Transfers underlying tokens from {msg.sender} to the contract and
    ///         mints wrapper tokens to the specified beneficiary.
    /// @param uAmount The amount of underlying tokens to deposit.
    /// @return The amount of wrapper tokens mint.
    function deposit(uint256 uAmount) external returns (uint256);

    /// @notice Transfers underlying tokens from {msg.sender} to the contract and
    ///         mints wrapper tokens to the specified beneficiary.
    /// @param to The beneficiary account.
    /// @param uAmount The amount of underlying tokens to deposit.
    /// @return The amount of wrapper tokens mint.
    function depositFor(address to, uint256 uAmount) external returns (uint256);

    /// @notice Burns wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens back.
    /// @param uAmount The amount of underlying tokens to withdraw.
    /// @return The amount of wrapper tokens burnt.
    function withdraw(uint256 uAmount) external returns (uint256);

    /// @notice Burns wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens back to the specified beneficiary.
    /// @param to The beneficiary account.
    /// @param uAmount The amount of underlying tokens to withdraw.
    /// @return The amount of wrapper tokens burnt.
    function withdrawTo(address to, uint256 uAmount) external returns (uint256);

    /// @notice Burns all wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens back.
    /// @return The amount of wrapper tokens burnt.
    function withdrawAll() external returns (uint256);

    /// @notice Burns all wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens back.
    /// @param to The beneficiary account.
    /// @return The amount of wrapper tokens burnt.
    function withdrawAllTo(address to) external returns (uint256);

    //--------------------------------------------------------------------------
    // ButtonWrapper view methods

    /// @return The address of the underlying token.
    function underlying() external view returns (address);

    /// @return The total underlying tokens held by the wrapper contract.
    function totalUnderlying() external view returns (uint256);

    /// @param who The account address.
    /// @return The underlying token balance of the account.
    function balanceOfUnderlying(address who) external view returns (uint256);

    /// @param uAmount The amount of underlying tokens.
    /// @return The amount of wrapper tokens exchangeable.
    function underlyingToWrapper(uint256 uAmount) external view returns (uint256);

    /// @param amount The amount of wrapper tokens.
    /// @return The amount of underlying tokens exchangeable.
    function wrapperToUnderlying(uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

// Interface for MidasCapital. An open interest protocol based on
// modified Fuse contracts. Anyone can create an deploy isolated
// lending and borrowing pools with custom parameters.

import "../solidity-utils/openzeppelin/IERC20.sol";

interface ICToken is IERC20 {
    // Error codes referenced in this file can be found here:
    // https://github.com/compound-finance/compound-protocol/blob/a3214f67b73310d547e00fc578e8355911c9d376/contracts/ErrorReporter.sol
    // solhint-disable-previous-line max-line-length

    /**
     * @dev Underlying asset for this CToken
     */
    function underlying() external view returns (address);

    /**
     * @notice Sender supplies assets into the market and receives cTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     * @return uint 0=success, otherwise an error code (see ErrorReporter.sol link above for details)
     */
    function mint(uint256 mintAmount) external returns (uint256);

    /**
     * @notice Sender redeems cTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of cTokens to redeem into underlying
     * @return uint 0=success, otherwise an error code (see ErrorReporter.sol link above for details)
     */
    function redeem(uint256 redeemTokens) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "../solidity-utils/openzeppelin/IERC20.sol";

interface IEulerToken is IERC20 {
    /**
     * @dev Convert an eToken balance to an underlying amount, taking into account current exchange rate
     * @param balance eToken balance, in internal book-keeping units (18 decimals)
     * @return Amount in underlying units, (same decimals as underlying token)
     */
    // https://github.com/euler-xyz/euler-contracts/blob/b1ee3265853628d5a529081d7908c38404201b4e/contracts/modules/EToken.sol#L104
    // solhint-disable-previous-line max-line-length
    function convertBalanceToUnderlying(uint256 balance) external view returns (uint256);

    /**
     * @dev Convert an underlying amount to an eToken balance, taking into account current exchange rate
     * @param underlyingAmount Amount in underlying units (same decimals as underlying token)
     * @return eToken balance, in internal book-keeping units (18 decimals)
     */
    // https://github.com/euler-xyz/euler-contracts/blob/b1ee3265853628d5a529081d7908c38404201b4e/contracts/modules/EToken.sol#L114
    // solhint-disable-previous-line max-line-length
    function convertUnderlyingToBalance(uint256 underlyingAmount) external view returns (uint256);

    /**
     * @dev Transfer underlying tokens from sender to the Euler pool, and increase account's eTokens
     */
    function deposit(uint256 subAccountId, uint256 amount) external;

    /**
     * @dev Transfer underlying tokens from Euler pool to sender, and decrease account's eTokens
     */
    function withdraw(uint256 subAccountId, uint256 amount) external;

    /**
     * @dev Address of underlying asset
     */
    function underlyingAsset() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

import "../solidity-utils/openzeppelin/IERC20.sol";

interface IGearboxDieselToken is IERC20 {
    /**
     * @dev returns the address of the vault
     */
    function owner() external view returns (address);
}

interface IGearboxVault {
    /**
     * @dev returns the address of the underlying asset
     */
    function underlyingToken() external view returns (address);

    /**
     * @dev returns a 27 decimal fixed point 'ray' value so a rate of 1 is represented as 1e27
     */
    // solhint-disable-next-line func-name-mixedcase
    function getDieselRate_RAY() external view returns (uint256);

    /**
     * @dev converts diesel token amount to main token amount
     */
    function fromDiesel(uint256) external view returns (uint256);

    /**
     * @dev converts main token amount to diesel token amount
     */
    function toDiesel(uint256) external view returns (uint256);

    /**
     * @dev Adds liquidity to pool and sends diesel (LP) tokens back to the liquidity provider
     * The Referral code can be 0
     */
    function addLiquidity(
        uint256 underlyingAmount,
        address onBehalfOf,
        uint256 referralCode
    ) external;

    /**
     * @dev Removes liquidity from the pool and sends the underlying tokens to the `to` address
     */
    function removeLiquidity(uint256 dieselAmount, address to) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

import "../solidity-utils/openzeppelin/IERC20.sol";

// Source: https://github.com/Byte-Masons/beet-strat/blob/master/contracts/ReaperVaultv1_4.sol
// Interface definition for the ReaperTokenVault contract, a single strategy vault
// for Reaper Farm crypts. The pricePerFullShare is always represented with 18 decimals,
// regardless of the underlying token decimals.
// ie: If ppfs === 1e18, 1 USDC === 0.000_000_000_001_000_000 rfUSDC
// ie: If ppfs === 1e18, 1 DAI === 1 rfDAI
interface IReaperTokenVault is IERC20 {
    /**
     * @dev returns the address of the vault's underlying asset (mainToken)
     */
    function token() external view returns (address);

    /**
     * @dev returns the price for a single Vault share (ie rf-scfUSDT). The getPricePerFullShare is always in 1e18
     */
    function getPricePerFullShare() external view returns (uint256);

    /**
     * @notice Deposits `_amount` `token`, issuing shares to the caller.
     * If Panic is activated, deposits will not be accepted and this call will fail.
     * @param _amount The quantity of tokens to deposit.
     **/
    function deposit(uint256 _amount) external;

    /**
     * @notice Withdraws the calling account's tokens from this Vault,
     * redeeming amount `_shares` for an appropriate amount of tokens.
     **/
    function withdraw(uint256 _shares) external;

    /**
     * @dev returns the number of decimals for this vault token.
     * For reaper single-strat vaults, the decimals are fixed to 18.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

import "../solidity-utils/openzeppelin/IERC20.sol";

import "./ISilo.sol";

interface IShareToken is IERC20 {
    /**
     * @dev returns the underlying asset
     */
    function asset() external view returns (address);

    /**
     * @dev returns the address of the silo
     */
    function silo() external view returns (ISilo);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./IShareToken.sol";

interface IBaseSilo {
    /// Storage struct that holds all required data for a single token market
    struct AssetStorage {
        // Token that represents a share in totalDeposits of Silo
        IShareToken collateralToken;
        // Token that represents a share in collateralOnlyDeposits of Silo
        IShareToken collateralOnlyToken;
        // Token that represents a share in totalBorrowAmount of Silo
        IShareToken debtToken;
        // COLLATERAL: Amount of asset token that has been deposited to Silo with interest earned by depositors.
        // It also includes token amount that has been borrowed.
        uint256 totalDeposits;
        // COLLATERAL ONLY: Amount of asset token that has been deposited to Silo that can ONLY be used
        // as collateral. These deposits do NOT earn interest and CANNOT be borrowed.
        uint256 collateralOnlyDeposits;
        // DEBT: Amount of asset token that has been borrowed with accrued interest.
        uint256 totalBorrowAmount;
    }

    /**
     * @dev returns the asset storage struct
     * @dev AssetStorage struct contains necessary information for calculating shareToken exchange rates
     */
    function assetStorage(address _asset) external view returns (AssetStorage memory);
}

interface ISilo is IBaseSilo {
    /**
     * @dev Deposits funds into the Silo
     * @param _asset The address of the token to deposit
     * @param _depositor The address of the recipient of collateral tokens
     * @param _amount The amount of the token to deposit
     * @param _collateralOnly: True means your shareToken is protected (cannot be swapped for interest)
     * @return collateralAmount deposited amount
     * @return collateralShare user collateral shares based on deposited amount
     */
    function depositFor(
        address _asset,
        address _depositor,
        uint256 _amount,
        bool _collateralOnly
    ) external returns (uint256 collateralAmount, uint256 collateralShare);

    /**
     * @dev Withdraw `_amount` of `_asset` tokens from the Silo to `msg.sender`
     * @param _asset The address of the token to withdraw
     * @param _amount The amount of the token to withdraw
     * @param _collateralOnly True if withdrawing collateral only deposit
     * @return withdrawnAmount withdrawn amount that was transferred to user
     * @return withdrawnShare burned share based on `withdrawnAmount`
     */
    function withdraw(
        address _asset,
        uint256 _amount,
        bool _collateralOnly
    ) external returns (uint256 withdrawnAmount, uint256 withdrawnShare);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../solidity-utils/openzeppelin/IERC20.sol";

// solhint-disable-next-line max-line-length
// Based on https://github.com/aave/protocol-v2/blob/ac58fea62bb8afee23f66197e8bce6d79ecda292/contracts/interfaces/IStaticATokenLM.sol

interface IStaticATokenLM is IERC20 {
    struct SignatureParams {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /**
     * @notice Deposits `ASSET` in the Aave protocol and mints static aTokens to msg.sender
     * @param recipient The address that will receive the static aTokens
     * @param amount The amount of underlying `ASSET` to deposit (e.g. deposit of 100 USDC)
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param fromUnderlying bool
     * - `true` if the msg.sender comes with underlying tokens (e.g. USDC)
     * - `false` if the msg.sender comes already with aTokens (e.g. aUSDC)
     * @return uint256 The amount of StaticAToken minted, static balance
     **/
    function deposit(
        address recipient,
        uint256 amount,
        uint16 referralCode,
        bool fromUnderlying
    ) external returns (uint256);

    /**
     * @notice Burns `amount` of static aToken, with recipient receiving the corresponding amount of `ASSET`
     * @param recipient The address that will receive the amount of `ASSET` withdrawn from the Aave protocol
     * @param amount The amount to withdraw, in static balance of StaticAToken
     * @param toUnderlying bool
     * - `true` for the recipient to get underlying tokens (e.g. USDC)
     * - `false` for the recipient to get aTokens (e.g. aUSDC)
     * @return amountToBurn: StaticATokens burnt, static balance
     * @return amountToWithdraw: underlying/aToken send to `recipient`, dynamic balance
     **/
    function withdraw(
        address recipient,
        uint256 amount,
        bool toUnderlying
    ) external returns (uint256, uint256);

    /**
     * @notice Burns `amount` of static aToken, with recipient receiving the corresponding amount of `ASSET`
     * @param recipient The address that will receive the amount of `ASSET` withdrawn from the Aave protocol
     * @param amount The amount to withdraw, in dynamic balance of aToken/underlying asset
     * @param toUnderlying bool
     * - `true` for the recipient to get underlying tokens (e.g. USDC)
     * - `false` for the recipient to get aTokens (e.g. aUSDC)
     * @return amountToBurn: StaticATokens burnt, static balance
     * @return amountToWithdraw: underlying/aToken send to `recipient`, dynamic balance
     **/
    function withdrawDynamicAmount(
        address recipient,
        uint256 amount,
        bool toUnderlying
    ) external returns (uint256, uint256);

    /**
     * @notice Implements the permit function as for
     * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
     * @param owner The owner of the funds
     * @param spender The spender
     * @param value The amount
     * @param deadline The deadline timestamp, type(uint256).max for max deadline
     * @param v Signature param
     * @param s Signature param
     * @param r Signature param
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Allows to deposit on Aave via meta-transaction
     * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
     * @param depositor Address from which the funds to deposit are going to be pulled
     * @param recipient Address that will receive the staticATokens, in the average case, same as the `depositor`
     * @param value The amount to deposit
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param fromUnderlying bool
     * - `true` if the msg.sender comes with underlying tokens (e.g. USDC)
     * - `false` if the msg.sender comes already with aTokens (e.g. aUSDC)
     * @param deadline The deadline timestamp, type(uint256).max for max deadline
     * @param sigParams Signature params: v,r,s
     * @return uint256 The amount of StaticAToken minted, static balance
     */
    function metaDeposit(
        address depositor,
        address recipient,
        uint256 value,
        uint16 referralCode,
        bool fromUnderlying,
        uint256 deadline,
        SignatureParams calldata sigParams
    ) external returns (uint256);

    /**
     * @notice Allows to withdraw from Aave via meta-transaction
     * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
     * @param owner Address owning the staticATokens
     * @param recipient Address that will receive the underlying withdrawn from Aave
     * @param staticAmount The amount of staticAToken to withdraw. If > 0, `dynamicAmount` needs to be 0
     * @param dynamicAmount The amount of underlying/aToken to withdraw. If > 0, `staticAmount` needs to be 0
     * @param toUnderlying bool
     * - `true` for the recipient to get underlying tokens (e.g. USDC)
     * - `false` for the recipient to get aTokens (e.g. aUSDC)
     * @param deadline The deadline timestamp, type(uint256).max for max deadline
     * @param sigParams Signature params: v,r,s
     * @return amountToBurn: StaticATokens burnt, static balance
     * @return amountToWithdraw: underlying/aToken send to `recipient`, dynamic balance
     */
    function metaWithdraw(
        address owner,
        address recipient,
        uint256 staticAmount,
        uint256 dynamicAmount,
        bool toUnderlying,
        uint256 deadline,
        SignatureParams calldata sigParams
    ) external returns (uint256, uint256);

    /**
     * @notice Utility method to get the current aToken balance of an user, from his staticAToken balance
     * @param account The address of the user
     * @return uint256 The aToken balance
     **/
    function dynamicBalanceOf(address account) external view returns (uint256);

    /**
     * @notice Converts a static amount (scaled balance on aToken) to the aToken/underlying value,
     * using the current liquidity index on Aave
     * @param amount The amount to convert from
     * @return uint256 The dynamic amount
     **/
    function staticToDynamicAmount(uint256 amount) external view returns (uint256);

    /**
     * @notice Converts an aToken or underlying amount to the what it is denominated on the aToken as
     * scaled balance, function of the principal and the liquidity index
     * @param amount The amount to convert from
     * @return uint256 The static (scaled) amount
     **/
    function dynamicToStaticAmount(uint256 amount) external view returns (uint256);

    /**
     * @notice Returns the Aave liquidity index of the underlying aToken, denominated rate here
     * as it can be considered as an ever-increasing exchange rate
     * @return The liquidity index
     **/
    function rate() external view returns (uint256);

    /**
     * @notice Function to return a dynamic domain separator, in order to be compatible with forks changing chainId
     * @return bytes32 The domain separator
     **/
    function getDomainSeparator() external view returns (bytes32);

    /**
     * @notice Claims rewards from `INCENTIVES_CONTROLLER` and updates internal accounting of rewards.
     */
    function collectAndUpdateRewards() external;

    /**
     * @notice Claim rewards on behalf of a user and send them to a receiver
     * @dev Only callable by if sender is onBehalfOf or sender is approved claimer
     * @param onBehalfOf The address to claim on behalf of
     * @param receiver The address to receive the rewards
     * @param forceUpdate Flag to retrieve latest rewards from `INCENTIVES_CONTROLLER`
     */
    function claimRewardsOnBehalf(
        address onBehalfOf,
        address receiver,
        bool forceUpdate
    ) external;

    /**
     * @notice Claim rewards and send them to a receiver
     * @param receiver The address to receive the rewards
     * @param forceUpdate Flag to retrieve latest rewards from `INCENTIVES_CONTROLLER`
     */
    function claimRewards(address receiver, bool forceUpdate) external;

    /**
     * @notice Claim rewards
     * @param forceUpdate Flag to retrieve latest rewards from `INCENTIVES_CONTROLLER`
     */
    function claimRewardsToSelf(bool forceUpdate) external;

    /**
     * @notice Get the total claimable rewards of the contract.
     * @return The current balance + pending rewards from the `_incentivesController`
     */
    function getTotalClaimableRewards() external view returns (uint256);

    /**
     * @notice Get the total claimable rewards for a user in WAD
     * @param user The address of the user
     * @return The claimable amount of rewards in WAD
     */
    function getClaimableRewards(address user) external view returns (uint256);

    /**
     * @notice The unclaimed rewards for a user in WAD
     * @param user The address of the user
     * @return The unclaimed amount of rewards in WAD
     */
    function getUnclaimedRewards(address user) external view returns (uint256);

    function getAccRewardsPerToken() external view returns (uint256);

    function getLifetimeRewardsClaimed() external view returns (uint256);

    function getLifetimeRewards() external view returns (uint256);

    function getLastRewardBlock() external view returns (uint256);

    // solhint-disable-next-line func-name-mixedcase
    function LENDING_POOL() external returns (address);

    // solhint-disable-next-line func-name-mixedcase
    function INCENTIVES_CONTROLLER() external returns (address);

    // solhint-disable-next-line func-name-mixedcase
    function ATOKEN() external returns (IERC20);

    // solhint-disable-next-line func-name-mixedcase
    function ASSET() external returns (IERC20);

    // solhint-disable-next-line func-name-mixedcase
    function REWARD_TOKEN() external returns (IERC20);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

import "../solidity-utils/openzeppelin/IERC20.sol";

// solhint-disable-next-line max-line-length
// Based on https://github.com/lidofinance/lido-dao/blob/816bf1d0995ba5cfdfc264de4acda34a7fe93eba/contracts/0.4.24/Lido.sol

interface IstETH is IERC20 {
    function submit(address referral) external payable returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

import "../solidity-utils/openzeppelin/IERC20.sol";

interface ITetuSmartVault is IERC20 {
    function deposit(uint256 amount) external;

    function depositFor(uint256 amount, address holder) external;

    function underlyingBalanceInVault() external view returns (uint256);

    function withdraw(uint256 numberOfShares) external;

    function underlyingBalanceWithInvestmentForHolder(address holder) external view returns (uint256);

    function underlying() external view returns (address);

    function underlyingUnit() external view returns (uint256);

    function getPricePerFullShare() external view returns (uint256);

    function strategy() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

import "../solidity-utils/openzeppelin/IERC20.sol";

import "./IButtonWrapper.sol";

// Balancer only supports ERC20 tokens, so we use this intermediate interface
// to enforce ERC20-ness of UnbuttonTokens.
interface IUnbuttonToken is IButtonWrapper, IERC20 {
    // solhint-disable-previous-line no-empty-blocks
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

import "../solidity-utils/openzeppelin/IERC20.sol";

import "./IstETH.sol";

// solhint-disable-next-line max-line-length
// Based on https://github.com/lidofinance/lido-dao/blob/2b46615a11dee77d4d22066f942f6c6afab9b87a/contracts/0.6.12/WstETH.sol

/**
 * @title StETH token wrapper with static balances.
 * @dev It's an ERC20 token that represents the account's share of the total
 * supply of stETH tokens. WstETH token's balance only changes on transfers,
 * unlike StETH that is also changed when oracles report staking rewards and
 * penalties. It's a "power user" token for DeFi protocols which don't
 * support rebasable tokens.
 *
 * The contract is also a trustless wrapper that accepts stETH tokens and mints
 * wstETH in return. Then the user unwraps, the contract burns user's wstETH
 * and sends user locked stETH in return.
 *
 * The contract provides the staking shortcut: user can send ETH with regular
 * transfer and get wstETH in return. The contract will send ETH to Lido submit
 * method, staking it and wrapping the received stETH.
 *
 */
interface IwstETH is IERC20 {
    function stETH() external returns (IstETH);

    /**
     * @notice Exchanges stETH to wstETH
     * @param _stETHAmount amount of stETH to wrap in exchange for wstETH
     * @dev Requirements:
     *  - `_stETHAmount` must be non-zero
     *  - msg.sender must approve at least `_stETHAmount` stETH to this
     *    contract.
     *  - msg.sender must have at least `_stETHAmount` of stETH.
     * User should first approve _stETHAmount to the WstETH contract
     * @return Amount of wstETH user receives after wrap
     */
    function wrap(uint256 _stETHAmount) external returns (uint256);

    /**
     * @notice Exchanges wstETH to stETH
     * @param _wstETHAmount amount of wstETH to uwrap in exchange for stETH
     * @dev Requirements:
     *  - `_wstETHAmount` must be non-zero
     *  - msg.sender must have at least `_wstETHAmount` wstETH.
     * @return Amount of stETH user receives after unwrap
     */
    function unwrap(uint256 _wstETHAmount) external returns (uint256);

    /**
     * @notice Get amount of wstETH for a given amount of stETH
     * @param _stETHAmount amount of stETH
     * @return Amount of wstETH for a given stETH amount
     */
    function getWstETHByStETH(uint256 _stETHAmount) external view returns (uint256);

    /**
     * @notice Get amount of stETH for a given amount of wstETH
     * @param _wstETHAmount amount of wstETH
     * @return Amount of stETH for a given wstETH amount
     */
    function getStETHByWstETH(uint256 _wstETHAmount) external view returns (uint256);

    /**
     * @notice Get amount of wstETH for a one stETH
     * @return Amount of stETH for 1 wstETH
     */
    function stEthPerToken() external view returns (uint256);

    /**
     * @notice Get amount of stETH for a one wstETH
     * @return Amount of wstETH for a 1 stETH
     */
    function tokensPerStEth() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "../solidity-utils/openzeppelin/IERC20.sol";

interface IYearnTokenVault is IERC20 {
    /**
     * @dev returns the address of the vault's underlying asset (mainToken)
     */
    function token() external view returns (address);

    /**
     * @dev returns the price for a single Vault share (ie yvDAI). The pricePerShare is represented
     * in the same decimals as the underlying asset (ie: 6 decimals for USDC)
     */
    function pricePerShare() external view returns (uint256);

    /**
     * @notice Deposits `_amount` `token`, issuing shares to `recipient`.
     * If the Vault is in Emergency Shutdown, deposits will not be accepted and this call will fail.
     * @param _amount The quantity of tokens to deposit, defaults to all.
     * @param recipient The address to issue the shares in this Vault to. Defaults to the caller's address.
     * @return The issued Vault shares.
     */
    function deposit(uint256 _amount, address recipient) external returns (uint256);

    /**
     * @notice Withdraws the calling account's tokens from this Vault,
     * redeeming amount `_shares` for an appropriate amount of tokens.
     * See note on `setWithdrawalQueue` for further details of withdrawal ordering and behavior.
     * @param maxShares How many shares to try and redeem for tokens, defaults to all.
     * @param recipient The address to issue the shares in this Vault to. Defaults to the caller's address.
     * @return redeemed: The quantity of tokens redeemed for `_shares`.
     */
    function withdraw(uint256 maxShares, address recipient) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

interface IAuthorizer {
    /**
     * @dev Returns true if `account` can perform the action described by `actionId` in the contract `where`.
     */
    function canPerform(
        bytes32 actionId,
        address account,
        address where
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

// Inspired by Aave Protocol's IFlashLoanReceiver.

import "../solidity-utils/openzeppelin/IERC20.sol";

interface IFlashLoanRecipient {
    /**
     * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
     *
     * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
     * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
     * Vault, or else the entire flash loan will revert.
     *
     * `userData` is the same value passed in the `IVault.flashLoan` call.
     */
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../solidity-utils/openzeppelin/IERC20.sol";

import "./IVault.sol";
import "./IAuthorizer.sol";

interface IProtocolFeesCollector {
    event SwapFeePercentageChanged(uint256 newSwapFeePercentage);
    event FlashLoanFeePercentageChanged(uint256 newFlashLoanFeePercentage);

    function withdrawCollectedFees(
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        address recipient
    ) external;

    function setSwapFeePercentage(uint256 newSwapFeePercentage) external;

    function setFlashLoanFeePercentage(uint256 newFlashLoanFeePercentage) external;

    function getSwapFeePercentage() external view returns (uint256);

    function getFlashLoanFeePercentage() external view returns (uint256);

    function getCollectedFeeAmounts(IERC20[] memory tokens) external view returns (uint256[] memory feeAmounts);

    function getAuthorizer() external view returns (IAuthorizer);

    function vault() external view returns (IVault);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma experimental ABIEncoderV2;

import "../solidity-utils/openzeppelin/IERC20.sol";
import "../solidity-utils/helpers/IAuthentication.sol";
import "../solidity-utils/helpers/ISignaturesValidator.sol";
import "../solidity-utils/helpers/ITemporarilyPausable.sol";
import "../solidity-utils/misc/IWETH.sol";

import "./IAsset.sol";
import "./IAuthorizer.sol";
import "./IFlashLoanRecipient.sol";
import "./IProtocolFeesCollector.sol";

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev Full external interface for the Vault core contract - no external or public methods exist in the contract that
 * don't override one of these declarations.
 */
interface IVault is ISignaturesValidator, ITemporarilyPausable, IAuthentication {
    // Generalities about the Vault:
    //
    // - Whenever documentation refers to 'tokens', it strictly refers to ERC20-compliant token contracts. Tokens are
    // transferred out of the Vault by calling the `IERC20.transfer` function, and transferred in by calling
    // `IERC20.transferFrom`. In these cases, the sender must have previously allowed the Vault to use their tokens by
    // calling `IERC20.approve`. The only deviation from the ERC20 standard that is supported is functions not returning
    // a boolean value: in these scenarios, a non-reverting call is assumed to be successful.
    //
    // - All non-view functions in the Vault are non-reentrant: calling them while another one is mid-execution (e.g.
    // while execution control is transferred to a token contract during a swap) will result in a revert. View
    // functions can be called in a re-reentrant way, but doing so might cause them to return inconsistent results.
    // Contracts calling view functions in the Vault must make sure the Vault has not already been entered.
    //
    // - View functions revert if referring to either unregistered Pools, or unregistered tokens for registered Pools.

    // Authorizer
    //
    // Some system actions are permissioned, like setting and collecting protocol fees. This permissioning system exists
    // outside of the Vault in the Authorizer contract: the Vault simply calls the Authorizer to check if the caller
    // can perform a given action.

    /**
     * @dev Returns the Vault's Authorizer.
     */
    function getAuthorizer() external view returns (IAuthorizer);

    /**
     * @dev Sets a new Authorizer for the Vault. The caller must be allowed by the current Authorizer to do this.
     *
     * Emits an `AuthorizerChanged` event.
     */
    function setAuthorizer(IAuthorizer newAuthorizer) external;

    /**
     * @dev Emitted when a new authorizer is set by `setAuthorizer`.
     */
    event AuthorizerChanged(IAuthorizer indexed newAuthorizer);

    // Relayers
    //
    // Additionally, it is possible for an account to perform certain actions on behalf of another one, using their
    // Vault ERC20 allowance and Internal Balance. These accounts are said to be 'relayers' for these Vault functions,
    // and are expected to be smart contracts with sound authentication mechanisms. For an account to be able to wield
    // this power, two things must occur:
    //  - The Authorizer must grant the account the permission to be a relayer for the relevant Vault function. This
    //    means that Balancer governance must approve each individual contract to act as a relayer for the intended
    //    functions.
    //  - Each user must approve the relayer to act on their behalf.
    // This double protection means users cannot be tricked into approving malicious relayers (because they will not
    // have been allowed by the Authorizer via governance), nor can malicious relayers approved by a compromised
    // Authorizer or governance drain user funds, since they would also need to be approved by each individual user.

    /**
     * @dev Returns true if `user` has approved `relayer` to act as a relayer for them.
     */
    function hasApprovedRelayer(address user, address relayer) external view returns (bool);

    /**
     * @dev Allows `relayer` to act as a relayer for `sender` if `approved` is true, and disallows it otherwise.
     *
     * Emits a `RelayerApprovalChanged` event.
     */
    function setRelayerApproval(
        address sender,
        address relayer,
        bool approved
    ) external;

    /**
     * @dev Emitted every time a relayer is approved or disapproved by `setRelayerApproval`.
     */
    event RelayerApprovalChanged(address indexed relayer, address indexed sender, bool approved);

    // Internal Balance
    //
    // Users can deposit tokens into the Vault, where they are allocated to their Internal Balance, and later
    // transferred or withdrawn. It can also be used as a source of tokens when joining Pools, as a destination
    // when exiting them, and as either when performing swaps. This usage of Internal Balance results in greatly reduced
    // gas costs when compared to relying on plain ERC20 transfers, leading to large savings for frequent users.
    //
    // Internal Balance management features batching, which means a single contract call can be used to perform multiple
    // operations of different kinds, with different senders and recipients, at once.

    /**
     * @dev Returns `user`'s Internal Balance for a set of tokens.
     */
    function getInternalBalance(address user, IERC20[] memory tokens) external view returns (uint256[] memory);

    /**
     * @dev Performs a set of user balance operations, which involve Internal Balance (deposit, withdraw or transfer)
     * and plain ERC20 transfers using the Vault's allowance. This last feature is particularly useful for relayers, as
     * it lets integrators reuse a user's Vault allowance.
     *
     * For each operation, if the caller is not `sender`, it must be an authorized relayer for them.
     */
    function manageUserBalance(UserBalanceOp[] memory ops) external payable;

    /**
     * @dev Data for `manageUserBalance` operations, which include the possibility for ETH to be sent and received
     without manual WETH wrapping or unwrapping.
     */
    struct UserBalanceOp {
        UserBalanceOpKind kind;
        IAsset asset;
        uint256 amount;
        address sender;
        address payable recipient;
    }

    // There are four possible operations in `manageUserBalance`:
    //
    // - DEPOSIT_INTERNAL
    // Increases the Internal Balance of the `recipient` account by transferring tokens from the corresponding
    // `sender`. The sender must have allowed the Vault to use their tokens via `IERC20.approve()`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset and forwarding ETH in the call: it will be wrapped
    // and deposited as WETH. Any ETH amount remaining will be sent back to the caller (not the sender, which is
    // relevant for relayers).
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - WITHDRAW_INTERNAL
    // Decreases the Internal Balance of the `sender` account by transferring tokens to the `recipient`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset. This will deduct WETH instead, unwrap it and send
    // it to the recipient as ETH.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_INTERNAL
    // Transfers tokens from the Internal Balance of the `sender` account to the Internal Balance of `recipient`.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_EXTERNAL
    // Transfers tokens from `sender` to `recipient`, using the Vault's ERC20 allowance. This is typically used by
    // relayers, as it lets them reuse a user's Vault allowance.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `ExternalBalanceTransfer` event.

    enum UserBalanceOpKind { DEPOSIT_INTERNAL, WITHDRAW_INTERNAL, TRANSFER_INTERNAL, TRANSFER_EXTERNAL }

    /**
     * @dev Emitted when a user's Internal Balance changes, either from calls to `manageUserBalance`, or through
     * interacting with Pools using Internal Balance.
     *
     * Because Internal Balance works exclusively with ERC20 tokens, ETH deposits and withdrawals will use the WETH
     * address.
     */
    event InternalBalanceChanged(address indexed user, IERC20 indexed token, int256 delta);

    /**
     * @dev Emitted when a user's Vault ERC20 allowance is used by the Vault to transfer tokens to an external account.
     */
    event ExternalBalanceTransfer(IERC20 indexed token, address indexed sender, address recipient, uint256 amount);

    // Pools
    //
    // There are three specialization settings for Pools, which allow for cheaper swaps at the cost of reduced
    // functionality:
    //
    //  - General: no specialization, suited for all Pools. IGeneralPool is used for swap request callbacks, passing the
    // balance of all tokens in the Pool. These Pools have the largest swap costs (because of the extra storage reads),
    // which increase with the number of registered tokens.
    //
    //  - Minimal Swap Info: IMinimalSwapInfoPool is used instead of IGeneralPool, which saves gas by only passing the
    // balance of the two tokens involved in the swap. This is suitable for some pricing algorithms, like the weighted
    // constant product one popularized by Balancer V1. Swap costs are smaller compared to general Pools, and are
    // independent of the number of registered tokens.
    //
    //  - Two Token: only allows two tokens to be registered. This achieves the lowest possible swap gas cost. Like
    // minimal swap info Pools, these are called via IMinimalSwapInfoPool.

    enum PoolSpecialization { GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN }

    /**
     * @dev Registers the caller account as a Pool with a given specialization setting. Returns the Pool's ID, which
     * is used in all Pool-related functions. Pools cannot be deregistered, nor can the Pool's specialization be
     * changed.
     *
     * The caller is expected to be a smart contract that implements either `IGeneralPool` or `IMinimalSwapInfoPool`,
     * depending on the chosen specialization setting. This contract is known as the Pool's contract.
     *
     * Note that the same contract may register itself as multiple Pools with unique Pool IDs, or in other words,
     * multiple Pools may share the same contract.
     *
     * Emits a `PoolRegistered` event.
     */
    function registerPool(PoolSpecialization specialization) external returns (bytes32);

    /**
     * @dev Emitted when a Pool is registered by calling `registerPool`.
     */
    event PoolRegistered(bytes32 indexed poolId, address indexed poolAddress, PoolSpecialization specialization);

    /**
     * @dev Returns a Pool's contract address and specialization setting.
     */
    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

    /**
     * @dev Registers `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Pools can only interact with tokens they have registered. Users join a Pool by transferring registered tokens,
     * exit by receiving registered tokens, and can only swap registered tokens.
     *
     * Each token can only be registered once. For Pools with the Two Token specialization, `tokens` must have a length
     * of two, that is, both tokens must be registered in the same `registerTokens` call, and they must be sorted in
     * ascending order.
     *
     * The `tokens` and `assetManagers` arrays must have the same length, and each entry in these indicates the Asset
     * Manager for the corresponding token. Asset Managers can manage a Pool's tokens via `managePoolBalance`,
     * depositing and withdrawing them directly, and can even set their balance to arbitrary amounts. They are therefore
     * expected to be highly secured smart contracts with sound design principles, and the decision to register an
     * Asset Manager should not be made lightly.
     *
     * Pools can choose not to assign an Asset Manager to a given token by passing in the zero address. Once an Asset
     * Manager is set, it cannot be changed except by deregistering the associated token and registering again with a
     * different Asset Manager.
     *
     * Emits a `TokensRegistered` event.
     */
    function registerTokens(
        bytes32 poolId,
        IERC20[] memory tokens,
        address[] memory assetManagers
    ) external;

    /**
     * @dev Emitted when a Pool registers tokens by calling `registerTokens`.
     */
    event TokensRegistered(bytes32 indexed poolId, IERC20[] tokens, address[] assetManagers);

    /**
     * @dev Deregisters `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Only registered tokens (via `registerTokens`) can be deregistered. Additionally, they must have zero total
     * balance. For Pools with the Two Token specialization, `tokens` must have a length of two, that is, both tokens
     * must be deregistered in the same `deregisterTokens` call.
     *
     * A deregistered token can be re-registered later on, possibly with a different Asset Manager.
     *
     * Emits a `TokensDeregistered` event.
     */
    function deregisterTokens(bytes32 poolId, IERC20[] memory tokens) external;

    /**
     * @dev Emitted when a Pool deregisters tokens by calling `deregisterTokens`.
     */
    event TokensDeregistered(bytes32 indexed poolId, IERC20[] tokens);

    /**
     * @dev Returns detailed information for a Pool's registered token.
     *
     * `cash` is the number of tokens the Vault currently holds for the Pool. `managed` is the number of tokens
     * withdrawn and held outside the Vault by the Pool's token Asset Manager. The Pool's total balance for `token`
     * equals the sum of `cash` and `managed`.
     *
     * Internally, `cash` and `managed` are stored using 112 bits. No action can ever cause a Pool's token `cash`,
     * `managed` or `total` balance to be greater than 2^112 - 1.
     *
     * `lastChangeBlock` is the number of the block in which `token`'s total balance was last modified (via either a
     * join, exit, swap, or Asset Manager update). This value is useful to avoid so-called 'sandwich attacks', for
     * example when developing price oracles. A change of zero (e.g. caused by a swap with amount zero) is considered a
     * change for this purpose, and will update `lastChangeBlock`.
     *
     * `assetManager` is the Pool's token Asset Manager.
     */
    function getPoolTokenInfo(bytes32 poolId, IERC20 token)
        external
        view
        returns (
            uint256 cash,
            uint256 managed,
            uint256 lastChangeBlock,
            address assetManager
        );

    /**
     * @dev Returns a Pool's registered tokens, the total balance for each, and the latest block when *any* of
     * the tokens' `balances` changed.
     *
     * The order of the `tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
     * Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.
     *
     * If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
     * order as passed to `registerTokens`.
     *
     * Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
     * the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use `getPoolTokenInfo`
     * instead.
     */
    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            IERC20[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    /**
     * @dev Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
     * trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
     * Pool shares.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
     * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
     * these maximums.
     *
     * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
     * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
     * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
     * back to the caller (not the sender, which is important for relayers).
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
     * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
     * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
     *
     * If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
     * be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
     * withdrawn from Internal Balance: attempting to do so will trigger a revert.
     *
     * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
     * directly to the Pool's contract, as is `recipient`.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    /**
     * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
     * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
     * Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
     * `getPoolTokenInfo`).
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
     * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
     * it just enforces these minimums.
     *
     * If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
     * enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
     * of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
     * be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
     * final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
     *
     * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
     * an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
     * do so will trigger a revert.
     *
     * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
     * `tokens` array. This array must match the Pool's registered tokens.
     *
     * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
     * passed directly to the Pool's contract.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    /**
     * @dev Emitted when a user joins or exits a Pool by calling `joinPool` or `exitPool`, respectively.
     */
    event PoolBalanceChanged(
        bytes32 indexed poolId,
        address indexed liquidityProvider,
        IERC20[] tokens,
        int256[] deltas,
        uint256[] protocolFeeAmounts
    );

    enum PoolBalanceChangeKind { JOIN, EXIT }

    // Swaps
    //
    // Users can swap tokens with Pools by calling the `swap` and `batchSwap` functions. To do this,
    // they need not trust Pool contracts in any way: all security checks are made by the Vault. They must however be
    // aware of the Pools' pricing algorithms in order to estimate the prices Pools will quote.
    //
    // The `swap` function executes a single swap, while `batchSwap` can perform multiple swaps in sequence.
    // In each individual swap, tokens of one kind are sent from the sender to the Pool (this is the 'token in'),
    // and tokens of another kind are sent from the Pool to the recipient in exchange (this is the 'token out').
    // More complex swaps, such as one token in to multiple tokens out can be achieved by batching together
    // individual swaps.
    //
    // There are two swap kinds:
    //  - 'given in' swaps, where the amount of tokens in (sent to the Pool) is known, and the Pool determines (via the
    // `onSwap` hook) the amount of tokens out (to send to the recipient).
    //  - 'given out' swaps, where the amount of tokens out (received from the Pool) is known, and the Pool determines
    // (via the `onSwap` hook) the amount of tokens in (to receive from the sender).
    //
    // Additionally, it is possible to chain swaps using a placeholder input amount, which the Vault replaces with
    // the calculated output of the previous swap. If the previous swap was 'given in', this will be the calculated
    // tokenOut amount. If the previous swap was 'given out', it will use the calculated tokenIn amount. These extended
    // swaps are known as 'multihop' swaps, since they 'hop' through a number of intermediate tokens before arriving at
    // the final intended token.
    //
    // In all cases, tokens are only transferred in and out of the Vault (or withdrawn from and deposited into Internal
    // Balance) after all individual swaps have been completed, and the net token balance change computed. This makes
    // certain swap patterns, such as multihops, or swaps that interact with the same token pair in multiple Pools, cost
    // much less gas than they would otherwise.
    //
    // It also means that under certain conditions it is possible to perform arbitrage by swapping with multiple
    // Pools in a way that results in net token movement out of the Vault (profit), with no tokens being sent in (only
    // updating the Pool's internal accounting).
    //
    // To protect users from front-running or the market changing rapidly, they supply a list of 'limits' for each token
    // involved in the swap, where either the maximum number of tokens to send (by passing a positive value) or the
    // minimum amount of tokens to receive (by passing a negative value) is specified.
    //
    // Additionally, a 'deadline' timestamp can also be provided, forcing the swap to fail if it occurs after
    // this point in time (e.g. if the transaction failed to be included in a block promptly).
    //
    // If interacting with Pools that hold WETH, it is possible to both send and receive ETH directly: the Vault will do
    // the wrapping and unwrapping. To enable this mechanism, the IAsset sentinel value (the zero address) must be
    // passed in the `assets` array instead of the WETH address. Note that it is possible to combine ETH and WETH in the
    // same swap. Any excess ETH will be sent back to the caller (not the sender, which is relevant for relayers).
    //
    // Finally, Internal Balance can be used when either sending or receiving tokens.

    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    /**
     * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    /**
     * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
     * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
     *
     * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
     * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
     * the same index in the `assets` array.
     *
     * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
     * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
     * `amountOut` depending on the swap kind.
     *
     * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
     * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
     * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
     *
     * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
     * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
     * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
     * or unwrapped from WETH by the Vault.
     *
     * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
     * the minimum or maximum amount of each token the vault is allowed to transfer.
     *
     * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
     * equivalent `swap` call.
     *
     * Emits `Swap` events.
     */
    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    /**
     * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
     * `assets` array passed to that function, and ETH assets are converted to WETH.
     *
     * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
     * from the previous swap, depending on the swap kind.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Emitted for each individual swap performed by `swap` or `batchSwap`.
     */
    event Swap(
        bytes32 indexed poolId,
        IERC20 indexed tokenIn,
        IERC20 indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /**
     * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     * `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *
     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
     * revert.
     */
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    /**
     * @dev Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
     * simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.
     *
     * Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
     * the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
     * receives are the same that an equivalent `batchSwap` call would receive.
     *
     * Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
     * This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
     * approve them for the Vault, or even know a user's address.
     *
     * Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
     * eth_call instead of eth_sendTransaction.
     */
    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);

    // Flash Loans

    /**
     * @dev Performs a 'flash loan', sending tokens to `recipient`, executing the `receiveFlashLoan` hook on it,
     * and then reverting unless the tokens plus a proportional protocol fee have been returned.
     *
     * The `tokens` and `amounts` arrays must have the same length, and each entry in these indicates the loan amount
     * for each token contract. `tokens` must be sorted in ascending order.
     *
     * The 'userData' field is ignored by the Vault, and forwarded as-is to `recipient` as part of the
     * `receiveFlashLoan` call.
     *
     * Emits `FlashLoan` events.
     */
    function flashLoan(
        IFlashLoanRecipient recipient,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;

    /**
     * @dev Emitted for each individual flash loan performed by `flashLoan`.
     */
    event FlashLoan(IFlashLoanRecipient indexed recipient, IERC20 indexed token, uint256 amount, uint256 feeAmount);

    // Asset Management
    //
    // Each token registered for a Pool can be assigned an Asset Manager, which is able to freely withdraw the Pool's
    // tokens from the Vault, deposit them, or assign arbitrary values to its `managed` balance (see
    // `getPoolTokenInfo`). This makes them extremely powerful and dangerous. Even if an Asset Manager only directly
    // controls one of the tokens in a Pool, a malicious manager could set that token's balance to manipulate the
    // prices of the other tokens, and then drain the Pool with swaps. The risk of using Asset Managers is therefore
    // not constrained to the tokens they are managing, but extends to the entire Pool's holdings.
    //
    // However, a properly designed Asset Manager smart contract can be safely used for the Pool's benefit,
    // for example by lending unused tokens out for interest, or using them to participate in voting protocols.
    //
    // This concept is unrelated to the IAsset interface.

    /**
     * @dev Performs a set of Pool balance operations, which may be either withdrawals, deposits or updates.
     *
     * Pool Balance management features batching, which means a single contract call can be used to perform multiple
     * operations of different kinds, with different Pools and tokens, at once.
     *
     * For each operation, the caller must be registered as the Asset Manager for `token` in `poolId`.
     */
    function managePoolBalance(PoolBalanceOp[] memory ops) external;

    struct PoolBalanceOp {
        PoolBalanceOpKind kind;
        bytes32 poolId;
        IERC20 token;
        uint256 amount;
    }

    /**
     * Withdrawals decrease the Pool's cash, but increase its managed balance, leaving the total balance unchanged.
     *
     * Deposits increase the Pool's cash, but decrease its managed balance, leaving the total balance unchanged.
     *
     * Updates don't affect the Pool's cash balance, but because the managed balance changes, it does alter the total.
     * The external amount can be either increased or decreased by this call (i.e., reporting a gain or a loss).
     */
    enum PoolBalanceOpKind { WITHDRAW, DEPOSIT, UPDATE }

    /**
     * @dev Emitted when a Pool's token Asset Manager alters its balance via `managePoolBalance`.
     */
    event PoolBalanceManaged(
        bytes32 indexed poolId,
        address indexed assetManager,
        IERC20 indexed token,
        int256 cashDelta,
        int256 managedDelta
    );

    // Protocol Fees
    //
    // Some operations cause the Vault to collect tokens in the form of protocol fees, which can then be withdrawn by
    // permissioned accounts.
    //
    // There are two kinds of protocol fees:
    //
    //  - flash loan fees: charged on all flash loans, as a percentage of the amounts lent.
    //
    //  - swap fees: a percentage of the fees charged by Pools when performing swaps. For a number of reasons, including
    // swap gas costs and interface simplicity, protocol swap fees are not charged on each individual swap. Rather,
    // Pools are expected to keep track of how much they have charged in swap fees, and pay any outstanding debts to the
    // Vault when they are joined or exited. This prevents users from joining a Pool with unpaid debt, as well as
    // exiting a Pool in debt without first paying their share.

    /**
     * @dev Returns the current protocol fee module.
     */
    function getProtocolFeesCollector() external view returns (IProtocolFeesCollector);

    /**
     * @dev Safety mechanism to pause most Vault operations in the event of an emergency - typically detection of an
     * error in some part of the system.
     *
     * The Vault can only be paused during an initial time period, after which pausing is forever disabled.
     *
     * While the contract is paused, the following features are disabled:
     * - depositing and transferring internal balance
     * - transferring external balance (using the Vault's allowance)
     * - swaps
     * - joining Pools
     * - Asset Manager interactions
     *
     * Internal Balance can still be withdrawn, and Pools exited.
     */
    function setPaused(bool paused) external;

    /**
     * @dev Returns the Vault's WETH instance.
     */
    function WETH() external view returns (IWETH);
    // solhint-disable-previous-line func-name-mixedcase
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/openzeppelin/IERC20.sol";
import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";

library InputHelpers {
    function ensureInputLengthMatch(uint256 a, uint256 b) internal pure {
        _require(a == b, Errors.INPUT_LENGTH_MISMATCH);
    }

    function ensureInputLengthMatch(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure {
        _require(a == b && b == c, Errors.INPUT_LENGTH_MISMATCH);
    }

    function ensureArrayIsSorted(IERC20[] memory array) internal pure {
        address[] memory addressArray;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addressArray := array
        }
        ensureArrayIsSorted(addressArray);
    }

    function ensureArrayIsSorted(address[] memory array) internal pure {
        if (array.length < 2) {
            return;
        }

        address previous = array[0];
        for (uint256 i = 1; i < array.length; ++i) {
            address current = array[i];
            _require(previous < current, Errors.UNSORTED_ARRAY);
            previous = current;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

library VaultHelpers {
    /**
     * @dev Returns the address of a Pool's contract.
     *
     * This is the same code the Vault runs in `PoolRegistry._getPoolAddress`.
     */
    function toPoolAddress(bytes32 poolId) internal pure returns (address) {
        // 12 byte logical shift left to remove the nonce and specialization setting. We don't need to mask,
        // since the logical shift already sets the upper bits to zero.
        return address(uint256(poolId) >> (12 * 8));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/IVersion.sol";

/**
 * @notice Retrieves a contract's version set at creation time from storage.
 */
contract Version is IVersion {
    string private _version;

    constructor(string memory version) {
        _setVersion(version);
    }

    function version() external view override returns (string memory) {
        return _version;
    }

    /**
     * @dev Internal setter that allows this contract to be used in proxies.
     */
    function _setVersion(string memory newVersion) internal {
        _version = newVersion;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow checks.
 * Adapted from OpenZeppelin's SafeMath library.
 */
library Math {
    // solhint-disable no-inline-assembly

    /**
     * @dev Returns the absolute value of a signed integer.
     */
    function abs(int256 a) internal pure returns (uint256 result) {
        // Equivalent to:
        // result = a > 0 ? uint256(a) : uint256(-a)
        assembly {
            let s := sar(255, a)
            result := sub(xor(a, s), s)
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers of 256 bits, reverting on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        _require(c >= a, Errors.ADD_OVERFLOW);
        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        _require((b >= 0 && c >= a) || (b < 0 && c < a), Errors.ADD_OVERFLOW);
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers of 256 bits, reverting on overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        _require(b <= a, Errors.SUB_OVERFLOW);
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        _require((b >= 0 && c <= a) || (b < 0 && c > a), Errors.SUB_OVERFLOW);
        return c;
    }

    /**
     * @dev Returns the largest of two numbers of 256 bits.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256 result) {
        // Equivalent to:
        // result = (a < b) ? b : a;
        assembly {
            result := sub(a, mul(sub(a, b), lt(a, b)))
        }
    }

    /**
     * @dev Returns the smallest of two numbers of 256 bits.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256 result) {
        // Equivalent to `result = (a < b) ? a : b`
        assembly {
            result := sub(a, mul(sub(a, b), gt(a, b)))
        }
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        _require(a == 0 || c / a == b, Errors.MUL_OVERFLOW);
        return c;
    }

    function div(
        uint256 a,
        uint256 b,
        bool roundUp
    ) internal pure returns (uint256) {
        return roundUp ? divUp(a, b) : divDown(a, b);
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        _require(b != 0, Errors.ZERO_DIVISION);
        return a / b;
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256 result) {
        _require(b != 0, Errors.ZERO_DIVISION);

        // Equivalent to:
        // result = a == 0 ? 0 : 1 + (a - 1) / b;
        assembly {
            result := mul(iszero(iszero(a)), add(1, div(sub(a, 1), b)))
        }
    }
}

// SPDX-License-Identifier: MIT

// Based on the Address library from OpenZeppelin Contracts, altered by removing the `isContract` checks on
// `functionCall` and `functionDelegateCall` in order to save gas, as the recipients are known to be contracts.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    // solhint-disable max-line-length

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        _require(address(this).balance >= amount, Errors.ADDRESS_INSUFFICIENT_BALANCE);

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        _require(success, Errors.ADDRESS_CANNOT_SEND_VALUE);
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call(data);
        return verifyCallResult(success, returndata);
    }

    // solhint-enable max-line-length

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but passing some native ETH as msg.value to the call.
     *
     * _Available since v3.4._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return verifyCallResult(success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling up the
     * revert reason or using the one provided.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                _revert(Errors.LOW_LEVEL_CALL_FAILED);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

// Based on the ReentrancyGuard library from OpenZeppelin Contracts, altered to reduce bytecode size.
// Modifier code is inlined by the compiler, which causes its code to appear multiple times in the codebase. By using
// private functions, we achieve the same end result with slightly higher runtime gas costs, but reduced bytecode size.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _enterNonReentrant();
        _;
        _exitNonReentrant();
    }

    function _enterNonReentrant() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        _require(_status != _ENTERED, Errors.REENTRANCY);

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _exitNonReentrant() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

// Based on the ReentrancyGuard library from OpenZeppelin Contracts, altered to reduce gas costs.
// The `safeTransfer` and `safeTransferFrom` functions assume that `token` is a contract (an account with code), and
// work differently from the OpenZeppelin version if it is not.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";
import "@balancer-labs/v2-interfaces/contracts/solidity-utils/openzeppelin/IERC20.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {

    function safeApprove(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        // Some contracts need their allowance reduced to 0 before setting it to an arbitrary amount.
        if (value != 0 && token.allowance(address(this), address(to)) != 0) {
            _callOptionalReturn(address(token), abi.encodeWithSelector(token.approve.selector, to, 0));
        }

        _callOptionalReturn(address(token), abi.encodeWithSelector(token.approve.selector, to, value));
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(address(token), abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(address(token), abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     *
     * WARNING: `token` is assumed to be a contract: calls to EOAs will *not* revert.
     */
    function _callOptionalReturn(address token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = token.call(data);

        // If the low-level call didn't succeed we return whatever was returned from it.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            if eq(success, 0) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        // Finally we check the returndata size is either zero or true - note that this check will always pass for EOAs
        _require(returndata.length == 0 || abi.decode(returndata, (bool)), Errors.SAFE_ERC20_CALL_FAILED);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/openzeppelin/IERC20.sol";
import "@balancer-labs/v2-interfaces/contracts/solidity-utils/misc/IWETH.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IAsset.sol";

abstract contract AssetHelpers {
    // solhint-disable-next-line var-name-mixedcase
    IWETH private immutable _weth;

    // Sentinel value used to indicate WETH with wrapping/unwrapping semantics. The zero address is a good choice for
    // multiple reasons: it is cheap to pass as a calldata argument, it is a known invalid token and non-contract, and
    // it is an address Pools cannot register as a token.
    address private constant _ETH = address(0);

    constructor(IWETH weth) {
        _weth = weth;
    }

    // solhint-disable-next-line func-name-mixedcase
    function _WETH() internal view returns (IWETH) {
        return _weth;
    }

    /**
     * @dev Returns true if `asset` is the sentinel value that represents ETH.
     */
    function _isETH(IAsset asset) internal pure returns (bool) {
        return address(asset) == _ETH;
    }

    /**
     * @dev Translates `asset` into an equivalent IERC20 token address. If `asset` represents ETH, it will be translated
     * to the WETH contract.
     */
    function _translateToIERC20(IAsset asset) internal view returns (IERC20) {
        return _isETH(asset) ? _WETH() : _asIERC20(asset);
    }

    /**
     * @dev Same as `_translateToIERC20(IAsset)`, but for an entire array.
     */
    function _translateToIERC20(IAsset[] memory assets) internal view returns (IERC20[] memory) {
        IERC20[] memory tokens = new IERC20[](assets.length);
        for (uint256 i = 0; i < assets.length; ++i) {
            tokens[i] = _translateToIERC20(assets[i]);
        }
        return tokens;
    }

    /**
     * @dev Interprets `asset` as an IERC20 token. This function should only be called on `asset` if `_isETH` previously
     * returned false for it, that is, if `asset` is guaranteed not to be the ETH sentinel value.
     */
    function _asIERC20(IAsset asset) internal pure returns (IERC20) {
        return IERC20(address(asset));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./relayer/BaseRelayerLibrary.sol";

import "./relayer/AaveWrapping.sol";
import "./relayer/ERC4626Wrapping.sol";
import "./relayer/EulerWrapping.sol";
import "./relayer/GaugeActions.sol";
import "./relayer/GearboxWrapping.sol";
import "./relayer/LidoWrapping.sol";
import "./relayer/CompoundV2Wrapping.sol";
import "./relayer/UnbuttonWrapping.sol";
import "./relayer/ReaperWrapping.sol";
import "./relayer/TetuWrapping.sol";
import "./relayer/SiloWrapping.sol";
import "./relayer/VaultActions.sol";
import "./relayer/VaultPermit.sol";
import "./relayer/YearnWrapping.sol";

/**
 * @title Batch Relayer Library
 * @notice This contract is not a relayer by itself and calls into it directly will fail.
 * The associated relayer can be found by calling `getEntrypoint` on this contract.
 */
contract BatchRelayerLibrary is
    AaveWrapping,
    BaseRelayerLibrary,
    ERC4626Wrapping,
    EulerWrapping,
    GaugeActions,
    GearboxWrapping,
    LidoWrapping,
    UnbuttonWrapping,
    CompoundV2Wrapping,
    ReaperWrapping,
    SiloWrapping,
    TetuWrapping,
    VaultActions,
    VaultPermit,
    YearnWrapping
{
    constructor(
        IVault vault,
        IERC20 wstETH,
        IBalancerMinter minter,
        bool canCallUserCheckpoint,
        string memory version
    ) BaseRelayerLibrary(vault, version) LidoWrapping(wstETH) GaugeActions(minter, canCallUserCheckpoint) {
        // solhint-disable-previous-line no-empty-blocks
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-interfaces/contracts/standalone-utils/IStaticATokenLM.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";

import "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/Address.sol";
import "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/SafeERC20.sol";

import "./IBaseRelayerLibrary.sol";

/**
 * @title AaveWrapping
 * @notice Allows users to wrap and unwrap Aave's aTokens into their StaticAToken wrappers
 * @dev All functions must be payable so they can be called from a multicall involving ETH
 */
abstract contract AaveWrapping is IBaseRelayerLibrary {
    using Address for address payable;
    using SafeERC20 for IERC20;

    function wrapAaveDynamicToken(
        IStaticATokenLM staticToken,
        address sender,
        address recipient,
        uint256 amount,
        bool fromUnderlying,
        uint256 outputReference
    ) external payable {
        if (_isChainedReference(amount)) {
            amount = _getChainedReferenceValue(amount);
        }

        // Aave's StaticATokens allow wrapping either an aToken or the underlying asset.
        // We can query which token to pull and approve from the wrapper contract.
        IERC20 dynamicToken = fromUnderlying ? staticToken.ASSET() : staticToken.ATOKEN();

        // The wrap caller is the implicit sender of tokens, so if the goal is for the tokens
        // to be sourced from outside the relayer, we must first pull them here.
        if (sender != address(this)) {
            require(sender == msg.sender, "Incorrect sender");
            _pullToken(sender, dynamicToken, amount);
        }

        dynamicToken.safeApprove(address(staticToken), amount);
        // Use 0 for the referral code
        uint256 result = staticToken.deposit(recipient, amount, 0, fromUnderlying);

        if (_isChainedReference(outputReference)) {
            _setChainedReferenceValue(outputReference, result);
        }
    }

    function unwrapAaveStaticToken(
        IStaticATokenLM staticToken,
        address sender,
        address recipient,
        uint256 amount,
        bool toUnderlying,
        uint256 outputReference
    ) external payable {
        if (_isChainedReference(amount)) {
            amount = _getChainedReferenceValue(amount);
        }

        // The unwrap caller is the implicit sender of tokens, so if the goal is for the tokens
        // to be sourced from outside the relayer, we must first pull them here.
        if (sender != address(this)) {
            require(sender == msg.sender, "Incorrect sender");
            _pullToken(sender, staticToken, amount);
        }

        // No approval is needed here, as the Static Tokens are burned directly from the relayer's account
        (, uint256 result) = staticToken.withdraw(recipient, amount, toUnderlying);

        if (_isChainedReference(outputReference)) {
            _setChainedReferenceValue(outputReference, result);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-interfaces/contracts/standalone-utils/IBalancerRelayer.sol";

import "@balancer-labs/v2-solidity-utils/contracts/helpers/Version.sol";
import "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/ReentrancyGuard.sol";
import "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/Address.sol";

/**
 * @title Balancer Relayer
 * @notice Allows safe multicall execution of a relayer's functions
 * @dev
 * Relayers are composed of two contracts:
 *  - This contract, which acts as a single point of entry into the system through a multicall function.
 *  - A library contract, which defines the allowed behaviour of the relayer.
 *
 * The relayer entrypoint can then repeatedly delegatecall into the library's code to perform actions.
 * We can then run combinations of the library contract's functions in the context of the relayer entrypoint,
 * without having to expose all these functions on the entrypoint contract itself. The multicall function is
 * then a single point of entry for all actions, so we can easily prevent reentrancy.
 *
 * This design gives much stronger reentrancy guarantees, as otherwise a malicious contract could reenter
 * the relayer through another function (which must allow reentrancy for multicall logic), and that would
 * potentially allow them to manipulate global state, resulting in loss of funds in some cases:
 * e.g., sweeping any leftover ETH that should have been refunded to the user.
 *
 * NOTE: Only the entrypoint contract should be allowlisted by Balancer governance as a relayer, so that the
 * Vault will reject calls from outside the context of the entrypoint: e.g., if a user mistakenly called directly
 * into the library contract.
 */
contract BalancerRelayer is IBalancerRelayer, Version, ReentrancyGuard {
    using Address for address payable;
    using Address for address;

    IVault private immutable _vault;
    address private immutable _library;

    /**
     * @dev This contract is not meant to be deployed directly by an EOA, but rather during construction of a contract
     * derived from `BaseRelayerLibrary`, which will provide its own address as the relayer's library.
     */
    constructor(
        IVault vault,
        address libraryAddress,
        string memory version
    ) Version(version) {
        _vault = vault;
        _library = libraryAddress;
    }

    receive() external payable {
        // Only accept ETH transfers from the Vault. This is expected to happen due to a swap/exit/withdrawal
        // with ETH as an output, should the relayer be listed as the recipient. This may also happen when
        // joining a pool, performing a swap, or if managing a user's balance uses less than the full ETH value
        // provided. Any excess ETH will be refunded to this contract, and then forwarded to the original sender.
        _require(msg.sender == address(_vault), Errors.ETH_TRANSFER);
    }

    function getVault() external view override returns (IVault) {
        return _vault;
    }

    function getLibrary() external view override returns (address) {
        return _library;
    }

    function multicall(bytes[] calldata data) external payable override nonReentrant returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = _library.functionDelegateCall(data[i]);
        }

        _refundETH();
    }

    function _refundETH() private {
        uint256 remainingEth = address(this).balance;
        if (remainingEth > 0) {
            msg.sender.sendValue(remainingEth);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-interfaces/contracts/standalone-utils/IBalancerRelayer.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/SafeERC20.sol";

import "./IBaseRelayerLibrary.sol";
import "./BalancerRelayer.sol";

/**
 * @title Base Relayer Library
 * @notice Core functionality of a relayer. Allow users to use a signature to approve this contract
 * to take further actions on their behalf.
 * @dev
 * Relayers are composed of two contracts:
 *  - A `BalancerRelayer` contract, which acts as a single point of entry into the system through a multicall function
 *  - A library contract such as this one, which defines the allowed behaviour of the relayer

 * NOTE: Only the entrypoint contract should be allowlisted by Balancer governance as a relayer, so that the Vault
 * will reject calls from outside the entrypoint context.
 *
 * This contract should neither be allowlisted as a relayer, nor called directly by the user.
 * No guarantees can be made about fund safety when calling this contract in an improper manner.
 *
 * All functions that are meant to be called from the entrypoint via `multicall` must be payable so that they
 * do not revert in a call involving ETH. This also applies to functions that do not alter the state and would be
 * usually labeled as `view`.
 */
contract BaseRelayerLibrary is IBaseRelayerLibrary {
    using Address for address;
    using SafeERC20 for IERC20;

    IVault private immutable _vault;
    IBalancerRelayer private immutable _entrypoint;

    constructor(IVault vault, string memory version) IBaseRelayerLibrary(vault.WETH()) {
        _vault = vault;
        _entrypoint = new BalancerRelayer(vault, address(this), version);
    }

    function getVault() public view override returns (IVault) {
        return _vault;
    }

    function getEntrypoint() external view returns (IBalancerRelayer) {
        return _entrypoint;
    }

    /**
     * @notice Sets whether a particular relayer is authorised to act on behalf of the user
     */
    function setRelayerApproval(
        address relayer,
        bool approved,
        bytes calldata authorisation
    ) external payable {
        require(relayer == address(this) || !approved, "Relayer can only approve itself");
        bytes memory data = abi.encodePacked(
            abi.encodeWithSelector(_vault.setRelayerApproval.selector, msg.sender, relayer, approved),
            authorisation
        );

        address(_vault).functionCall(data);
    }

    /**
     * @notice Approves the Vault to use tokens held in the relayer
     * @dev This is needed to avoid having to send intermediate tokens back to the user
     */
    function approveVault(IERC20 token, uint256 amount) external payable override {
        if (_isChainedReference(amount)) {
            amount = _getChainedReferenceValue(amount);
        }
        // TODO: gas golf this a bit
        token.safeApprove(address(getVault()), amount);
    }

    /**
     * @notice Returns the amount referenced by chained reference `ref`.
     * @dev It does not alter the reference (even if it's marked as temporary).
     *
     * This function does not alter the state in any way. It is not marked as view because it has to be `payable`
     * in order to be used in a batch transaction.
     *
     * Use a static call to read the state off-chain.
     */
    function peekChainedReferenceValue(uint256 ref) external payable override returns (uint256 value) {
        (, value) = _peekChainedReferenceValue(ref);
    }

    function _pullToken(
        address sender,
        IERC20 token,
        uint256 amount
    ) internal override {
        if (amount == 0) return;
        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = token;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        _pullTokens(sender, tokens, amounts);
    }

    function _pullTokens(
        address sender,
        IERC20[] memory tokens,
        uint256[] memory amounts
    ) internal override {
        IVault.UserBalanceOp[] memory ops = new IVault.UserBalanceOp[](tokens.length);
        for (uint256 i; i < tokens.length; i++) {
            ops[i] = IVault.UserBalanceOp({
                asset: IAsset(address(tokens[i])),
                amount: amounts[i],
                sender: sender,
                recipient: payable(address(this)),
                kind: IVault.UserBalanceOpKind.TRANSFER_EXTERNAL
            });
        }

        getVault().manageUserBalance(ops);
    }

    /**
     * @dev Returns true if `amount` is not actually an amount, but rather a chained reference.
     */
    function _isChainedReference(uint256 amount) internal pure override returns (bool) {
        // First 3 nibbles are enough to determine if it's a chained reference.
        return
            (amount & 0xfff0000000000000000000000000000000000000000000000000000000000000) ==
            0xba10000000000000000000000000000000000000000000000000000000000000;
    }

    /**
     * @dev Returns true if `ref` is temporary reference, i.e. to be deleted after reading it.
     */
    function _isTemporaryChainedReference(uint256 amount) internal pure returns (bool) {
        // First 3 nibbles determine if it's a chained reference.
        // If the 4th nibble is 0 it is temporary; otherwise it is considered read-only.
        // In practice, we shall use '0xba11' for read-only references.
        return
            (amount & 0xffff000000000000000000000000000000000000000000000000000000000000) ==
            0xba10000000000000000000000000000000000000000000000000000000000000;
    }

    /**
     * @dev Stores `value` as the amount referenced by chained reference `ref`.
     */
    function _setChainedReferenceValue(uint256 ref, uint256 value) internal override {
        bytes32 slot = _getStorageSlot(ref);

        // Since we do manual calculation of storage slots, it is easier (and cheaper) to rely on internal assembly to
        // access it.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, value)
        }
    }

    /**
     * @dev Returns the amount referenced by chained reference `ref`.
     * If the reference is temporary, it will be cleared after reading it, so they can each only be read once.
     * If the reference is not temporary (i.e. read-only), it will not be cleared after reading it
     * (see `_isTemporaryChainedReference` function).
     */
    function _getChainedReferenceValue(uint256 ref) internal override returns (uint256) {
        (bytes32 slot, uint256 value) = _peekChainedReferenceValue(ref);

        if (_isTemporaryChainedReference(ref)) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                sstore(slot, 0)
            }
        }
        return value;
    }

    /**
     * @dev Returns the storage slot for reference `ref` as well as the amount referenced by it.
     * It does not alter the reference (even if it's marked as temporary).
     */
    function _peekChainedReferenceValue(uint256 ref) private view returns (bytes32 slot, uint256 value) {
        slot = _getStorageSlot(ref);

        // Since we do manual calculation of storage slots, it is easier (and cheaper) to rely on internal assembly to
        // access it.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            value := sload(slot)
        }
    }

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _TEMP_STORAGE_SUFFIX = keccak256("balancer.base-relayer-library");

    function _getStorageSlot(uint256 ref) private view returns (bytes32) {
        // This replicates the mechanism Solidity uses to allocate storage slots for mappings, but using a hash as the
        // mapping's storage slot, and subtracting 1 at the end. This should be more than enough to prevent collisions
        // with other state variables this or derived contracts might use.
        // See https://docs.soliditylang.org/en/v0.8.9/internals/layout_in_storage.html

        return bytes32(uint256(keccak256(abi.encodePacked(_removeReferencePrefix(ref), _TEMP_STORAGE_SUFFIX))) - 1);
    }

    /**
     * @dev Returns a reference without its prefix.
     * Use this function to calculate the storage slot so that it's the same for temporary and read-only references.
     */
    function _removeReferencePrefix(uint256 ref) private pure returns (uint256) {
        return (ref & 0x0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-interfaces/contracts/standalone-utils/ICToken.sol";

import "./IBaseRelayerLibrary.sol";

/**
 * @title CompoundV2Wrapping
 * @notice Allows users to wrap and unwrap Compound v2 cTokens
 * @dev All functions must be payable so they can be called from a multicall involving ETH
 */
abstract contract CompoundV2Wrapping is IBaseRelayerLibrary {
    function wrapCompoundV2(
        ICToken wrappedToken,
        address sender,
        address recipient,
        uint256 amount,
        uint256 outputReference
    ) external payable {
        IERC20 mainToken = IERC20(wrappedToken.underlying());
        amount = _resolveAmountPullTokenAndApproveSpender(mainToken, address(wrappedToken), amount, sender);

        // The `mint` function deposits `amount` underlying tokens and transfers cTokens to the caller.
        // It returns an error code, where zero indicates success. Other error codes can be found here:
        // https://github.com/compound-finance/compound-protocol/blob/a3214f67b73310d547e00fc578e8355911c9d376/contracts/ErrorReporter.sol
        // solhint-disable-previous-line max-line-length
        require(wrappedToken.mint(amount) == 0, "wrapping failed");

        uint256 receivedWrappedAmount = wrappedToken.balanceOf(address(this));

        _transferAndSetChainedReference(wrappedToken, recipient, receivedWrappedAmount, outputReference);
    }

    function unwrapCompoundV2(
        ICToken wrappedToken,
        address sender,
        address recipient,
        uint256 amount,
        uint256 outputReference
    ) external payable {
        amount = _resolveAmountAndPullToken(wrappedToken, amount, sender);

        IERC20 mainToken = IERC20(wrappedToken.underlying());

        // The `redeem` function burns `amount` cTokens and transfers underlying tokens to the caller.
        // It returns an error code, where zero indicates success. Other error codes can be found here:
        // https://github.com/compound-finance/compound-protocol/blob/a3214f67b73310d547e00fc578e8355911c9d376/contracts/ErrorReporter.sol
        // solhint-disable-previous-line max-line-length
        require(wrappedToken.redeem(amount) == 0, "unwrapping failed");

        uint256 withdrawnMainAmount = mainToken.balanceOf(address(this));

        _transferAndSetChainedReference(mainToken, recipient, withdrawnMainAmount, outputReference);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/misc/IERC4626.sol";

import "./IBaseRelayerLibrary.sol";

/**
 * @title ERC4626Wrapping
 * @notice Allows users to wrap and unwrap ERC4626 tokens
 * @dev All functions must be payable so they can be called from a multicall involving ETH
 */
abstract contract ERC4626Wrapping is IBaseRelayerLibrary {
    function wrapERC4626(
        IERC4626 wrappedToken,
        address sender,
        address recipient,
        uint256 amount,
        uint256 outputReference
    ) external payable {
        IERC20 underlying = IERC20(wrappedToken.asset());

        amount = _resolveAmountPullTokenAndApproveSpender(underlying, address(wrappedToken), amount, sender);

        uint256 result = wrappedToken.deposit(amount, recipient);

        _setChainedReference(outputReference, result);
    }

    function unwrapERC4626(
        IERC4626 wrappedToken,
        address sender,
        address recipient,
        uint256 amount,
        uint256 outputReference
    ) external payable {
        amount = _resolveAmountAndPullToken(wrappedToken, amount, sender);

        uint256 result = wrappedToken.redeem(amount, recipient, address(this));

        _setChainedReference(outputReference, result);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-interfaces/contracts/standalone-utils/IEulerToken.sol";

import "./IBaseRelayerLibrary.sol";

/**
 * @title EulerWrapping
 * @notice Allows users to wrap and unwrap Euler tokens
 * @dev All functions must be payable so they can be called from a multicall involving ETH
 */
abstract contract EulerWrapping is IBaseRelayerLibrary {
    //solhint-disable-next-line private-vars-leading-underscore
    uint256 private constant MAX_UINT256 = type(uint256).max;

    function wrapEuler(
        IEulerToken wrappedToken,
        address eulerProtocol,
        address sender,
        address recipient,
        uint256 amount,
        uint256 outputReference
    ) external payable {
        IERC20 underlying = IERC20(wrappedToken.underlyingAsset());

        amount = _resolveAmountPullTokenAndApproveSpender(underlying, eulerProtocol, amount, sender);

        // Deposit MainToken into EulerToken
        // 0 for the Euler primary account
        wrappedToken.deposit(0, amount);

        uint256 receivedWrappedAmount = wrappedToken.balanceOf(address(this));

        _transferAndSetChainedReference(wrappedToken, recipient, receivedWrappedAmount, outputReference);
    }

    function unwrapEuler(
        IEulerToken wrappedToken,
        address sender,
        address recipient,
        uint256 amount,
        uint256 outputReference
    ) external payable {
        amount = _resolveAmountAndPullToken(wrappedToken, amount, sender);

        // Euler offers two ways to withdraw:
        //     1. Calculate mainTokenOut via wrappedToken.convertBalanceToUnderlying(wrappedTokenAmount)
        //     2. Redeem the account's full balance of wrappedToken for mainToken
        // Option 1 may leave wrappedToken dust in the relayer, so we choose option 2
        // The 0 argument is for the Euler primary account
        wrappedToken.withdraw(0, MAX_UINT256); //MAX_UINT256 forces option 2

        IERC20 mainToken = IERC20(wrappedToken.underlyingAsset());
        uint256 withdrawnMainAmount = mainToken.balanceOf(address(this));

        _transferAndSetChainedReference(mainToken, recipient, withdrawnMainAmount, outputReference);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-interfaces/contracts/liquidity-mining/IBalancerMinter.sol";
import "@balancer-labs/v2-interfaces/contracts/liquidity-mining/IStakingLiquidityGauge.sol";

import "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/SafeERC20.sol";

import "./IBaseRelayerLibrary.sol";

/**
 * @title GaugeActions
 * @dev All functions must be payable so they can be called from a multicall involving ETH
 */
abstract contract GaugeActions is IBaseRelayerLibrary {
    using SafeERC20 for IERC20;

    IBalancerMinter private immutable _balancerMinter;
    bool private immutable _canCallUserCheckpoint;

    /**
     * @dev The zero address may be passed as balancerMinter to safely disable features
     *      which only exist on mainnet
     */
    constructor(IBalancerMinter balancerMinter, bool canCallUserCheckpoint) {
        _balancerMinter = balancerMinter;
        _canCallUserCheckpoint = canCallUserCheckpoint;
    }

    /**
     * @notice Returns true if the relayer is configured to checkpoint gauges directly via `user_checkpoint`.
     * @dev This method is not expected to be called inside `multicall` so it is not marked as `payable`.
     */
    function canCallUserCheckpoint() external view returns (bool) {
        return _canCallUserCheckpoint;
    }

    function gaugeDeposit(
        IStakingLiquidityGauge gauge,
        address sender,
        address recipient,
        uint256 amount
    ) external payable {
        // We can query which token to pull and approve from the wrapper contract.
        IERC20 bptToken = gauge.lp_token();

        amount = _resolveAmountPullTokenAndApproveSpender(bptToken, address(gauge), amount, sender);

        gauge.deposit(amount, recipient);
    }

    function gaugeWithdraw(
        IStakingLiquidityGauge gauge,
        address sender,
        address recipient,
        uint256 amount
    ) external payable {
        amount = _resolveAmountAndPullToken(gauge, amount, sender);

        // No approval is needed here, as the gauge Tokens are burned directly from the relayer's account.
        gauge.withdraw(amount);

        // Gauge does not support withdrawing BPT to another address atomically.
        // If intended recipient is not the relayer then forward the withdrawn BPT on to the recipient.
        if (recipient != address(this)) {
            IERC20 bptToken = gauge.lp_token();

            bptToken.safeTransfer(recipient, amount);
        }
    }

    function gaugeMint(address[] calldata gauges, uint256 outputReference) external payable {
        uint256 balMinted = _balancerMinter.mintManyFor(gauges, msg.sender);

        _setChainedReference(outputReference, balMinted);
    }

    function gaugeSetMinterApproval(
        bool approval,
        address user,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        _balancerMinter.setMinterApprovalWithSignature(address(this), approval, user, deadline, v, r, s);
    }

    function gaugeClaimRewards(IStakingLiquidityGauge[] calldata gauges) external payable {
        uint256 numGauges = gauges.length;
        for (uint256 i; i < numGauges; ++i) {
            gauges[i].claim_rewards(msg.sender);
        }
    }

    /**
     * @notice Perform a user checkpoint for the given user on the given set of gauges.
     * @dev Both mainnet and child chain gauges are supported.
     */
    function gaugeCheckpoint(address user, IStakingLiquidityGauge[] calldata gauges) external payable {
        if (_canCallUserCheckpoint) {
            _checkpointGaugesViaUserCheckpoint(user, gauges);
        } else {
            _checkpointGaugesViaUserBalance(user, gauges);
        }
    }

    function _checkpointGaugesViaUserCheckpoint(address user, IStakingLiquidityGauge[] calldata gauges) internal {
        uint256 numGauges = gauges.length;
        // In L2s (child chain gauges), `user_checkpoint` is not permissioned, so we can just call it directly.
        for (uint256 i = 0; i < numGauges; ++i) {
            gauges[i].user_checkpoint(user);
        }
    }

    function _checkpointGaugesViaUserBalance(address user, IStakingLiquidityGauge[] calldata gauges) internal {
        uint256 numGauges = gauges.length;
        IVault.UserBalanceOp[] memory ops = new IVault.UserBalanceOp[](numGauges);

        // In mainnet, `user_checkpoint` is permissioned for liquidity gauges, so we cannot call it directly.
        // However, some non-permissioned actions cause the gauge to checkpoint a user as a side effect,
        // even if the operation itself is a no-op. The simplest of these is a gauge token transfer, which we
        // perform here. Since the Vault has an unlimited allowance for gauge tokens, and user balance
        // operations use the Vault allowance, no approvals are necessary.
        // The amount has to be greater than 0 for the checkpoint to take place, so we use 1 wei.
        // There is no actual value transfer since the sender and the recipient are the same.
        for (uint256 i = 0; i < numGauges; ++i) {
            // We first prepare all the transfer operations for each of the gauges.
            ops[i] = IVault.UserBalanceOp({
                asset: IAsset(address(gauges[i])),
                amount: 1,
                sender: user,
                recipient: payable(address(user)),
                kind: IVault.UserBalanceOpKind.TRANSFER_EXTERNAL
            });
        }
        // And we execute all of them at once.
        getVault().manageUserBalance(ops);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-interfaces/contracts/standalone-utils/IGearboxDieselToken.sol";

import "./IBaseRelayerLibrary.sol";

/**
 * @title GearboxWrapping
 * @notice Allows users to wrap and unwrap Gearbox tokens
 * @dev All functions must be payable so they can be called from a multicall involving ETH
 */
abstract contract GearboxWrapping is IBaseRelayerLibrary {
    function wrapGearbox(
        IGearboxDieselToken wrappedToken,
        address sender,
        address recipient,
        uint256 mainAmount,
        uint256 outputReference
    ) external payable {
        IGearboxVault gearboxVault = IGearboxVault(wrappedToken.owner());
        IERC20 underlying = IERC20(gearboxVault.underlyingToken());

        // Main Tokens are not deposited in the dieselToken address. Instead, they're deposited in a gearbox vault
        mainAmount = _resolveAmountPullTokenAndApproveSpender(underlying, address(gearboxVault), mainAmount, sender);

        // The third argument of addLiquidity is a referral code, which will be always 0 for the relayer (no referee)
        gearboxVault.addLiquidity(mainAmount, recipient, 0);

        _setChainedReference(outputReference, gearboxVault.toDiesel(mainAmount));
    }

    function unwrapGearbox(
        IGearboxDieselToken wrappedToken,
        address sender,
        address recipient,
        uint256 dieselAmount,
        uint256 outputReference
    ) external payable {
        dieselAmount = _resolveAmountAndPullToken(IERC20(address(wrappedToken)), dieselAmount, sender);

        // Main Tokens are not deposited in the dieselToken address. Instead, they're deposited in a gearbox vault.
        // Therefore, to remove liquidity, we withdraw tokens from the vault, and not from the wrapped token.
        IGearboxVault gearboxVault = IGearboxVault(wrappedToken.owner());
        gearboxVault.removeLiquidity(dieselAmount, recipient);

        _setChainedReference(outputReference, gearboxVault.fromDiesel(dieselAmount));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";

import "@balancer-labs/v2-vault/contracts/AssetHelpers.sol";
import "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/SafeERC20.sol";

/**
 * @title IBaseRelayerLibrary
 */
abstract contract IBaseRelayerLibrary is AssetHelpers {
    using SafeERC20 for IERC20;

    constructor(IWETH weth) AssetHelpers(weth) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function getVault() public view virtual returns (IVault);

    function approveVault(IERC20 token, uint256 amount) external payable virtual;

    function peekChainedReferenceValue(uint256 ref) external payable virtual returns (uint256);

    function _pullToken(
        address sender,
        IERC20 token,
        uint256 amount
    ) internal virtual;

    function _pullTokens(
        address sender,
        IERC20[] memory tokens,
        uint256[] memory amounts
    ) internal virtual;

    function _isChainedReference(uint256 amount) internal pure virtual returns (bool);

    function _setChainedReferenceValue(uint256 ref, uint256 value) internal virtual;

    function _getChainedReferenceValue(uint256 ref) internal virtual returns (uint256);

    /**
     * @dev This reuses `_resolveAmountAndPullToken` to adjust the `amount` in case it is a chained reference,
     * then pull that amount of `token` to the relayer. Additionally, it approves the `spender` to enable
     * wrapping operations. The spender is usually a token, but could also be another kind of contract (e.g.,
     * a protocol or gauge).
     */
    function _resolveAmountPullTokenAndApproveSpender(
        IERC20 token,
        address spender,
        uint256 amount,
        address sender
    ) internal returns (uint256 resolvedAmount) {
        resolvedAmount = _resolveAmountAndPullToken(token, amount, sender);

        token.safeApprove(spender, resolvedAmount);
    }

    /**
     * @dev Extract the `amount` (if it is a chained reference), and pull that amount of `token` to
     * this contract.
     */
    function _resolveAmountAndPullToken(
        IERC20 token,
        uint256 amount,
        address sender
    ) internal returns (uint256 resolvedAmount) {
        resolvedAmount = _resolveAmount(amount);

        // The wrap caller is the implicit sender of tokens, so if the goal is for the tokens
        // to be sourced from outside the relayer, we must first pull them here.
        if (sender != address(this)) {
            require(sender == msg.sender, "Incorrect sender");
            _pullToken(sender, token, resolvedAmount);
        }
    }

    /**
     * @dev Resolve an amount from a possible chained reference. This is internal, since some wrappers
     * call it independently.
     */
    function _resolveAmount(uint256 amount) internal returns (uint256) {
        return _isChainedReference(amount) ? _getChainedReferenceValue(amount) : amount;
    }

    /**
     * @dev Transfer the given `amount` of `token` to `recipient`, then call `_setChainedReference`
     * with that amount, in case it needs to be encoded as an output reference.
     */
    function _transferAndSetChainedReference(
        IERC20 token,
        address recipient,
        uint256 amount,
        uint256 outputReference
    ) internal {
        if (recipient != address(this)) {
            token.safeTransfer(recipient, amount);
        }

        _setChainedReference(outputReference, amount);
    }

    /**
     * @dev Check for a chained output reference, and encode the given `amount` if necessary.
     * This is internal, since some wrappers call it independently.
     */
    function _setChainedReference(uint256 outputReference, uint256 amount) internal {
        if (_isChainedReference(outputReference)) {
            _setChainedReferenceValue(outputReference, amount);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-interfaces/contracts/standalone-utils/IstETH.sol";
import "@balancer-labs/v2-interfaces/contracts/standalone-utils/IwstETH.sol";

import "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/Address.sol";

import "./IBaseRelayerLibrary.sol";

/**
 * @title LidoWrapping
 * @notice Allows users to wrap and unwrap stETH
 * @dev All functions must be payable so they can be called from a multicall involving ETH
 */
abstract contract LidoWrapping is IBaseRelayerLibrary {
    using Address for address payable;

    IstETH private immutable _stETH;
    IwstETH private immutable _wstETH;

    /**
     * @dev The zero address may be passed as wstETH to safely disable this module
     * @param wstETH - the address of Lido's wrapped stETH contract
     */
    constructor(IERC20 wstETH) {
        // Safely disable stETH wrapping if no address has been passed for wstETH
        _stETH = wstETH != IERC20(0) ? IwstETH(address(wstETH)).stETH() : IstETH(0);
        _wstETH = IwstETH(address(wstETH));
    }

    function wrapStETH(
        address sender,
        address recipient,
        uint256 amount,
        uint256 outputReference
    ) external payable {
        amount = _resolveAmountPullTokenAndApproveSpender(_stETH, address(_wstETH), amount, sender);

        uint256 result = IwstETH(_wstETH).wrap(amount);

        _transferAndSetChainedReference(_wstETH, recipient, result, outputReference);
    }

    function unwrapWstETH(
        address sender,
        address recipient,
        uint256 amount,
        uint256 outputReference
    ) external payable {
        amount = _resolveAmountAndPullToken(_wstETH, amount, sender);

        // No approval is needed here, as wstETH is burned directly from the relayer's account
        uint256 result = _wstETH.unwrap(amount);

        _transferAndSetChainedReference(_stETH, recipient, result, outputReference);
    }

    function stakeETH(
        address recipient,
        uint256 amount,
        uint256 outputReference
    ) external payable {
        amount = _resolveAmount(amount);

        uint256 result = _stETH.submit{ value: amount }(address(this));

        _transferAndSetChainedReference(_stETH, recipient, result, outputReference);
    }

    function stakeETHAndWrap(
        address recipient,
        uint256 amount,
        uint256 outputReference
    ) external payable {
        amount = _resolveAmount(amount);

        // We must query this separately, since the wstETH contract doesn't return how much wstETH is minted.
        uint256 result = _wstETH.getWstETHByStETH(amount);

        // The fallback function on the wstETH contract automatically stakes and wraps any ETH sent to it.
        // We can then send the ETH safely, and only have to ensure that the call doesn't revert.
        //
        // This would be dangerous if `_wstETH` were set to the zero address. However, in this scenario,
        // this function would have already reverted during the call to `getWstETHByStETH`, preventing loss of funds.
        payable(address(_wstETH)).sendValue(amount);

        _transferAndSetChainedReference(_wstETH, recipient, result, outputReference);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-interfaces/contracts/standalone-utils/IReaperTokenVault.sol";

import "./IBaseRelayerLibrary.sol";

/**
 * @title ReaperWrapping
 * @notice Allows users to wrap and unwrap Reapers's rfTokens into their underlying main tokens
 * @dev All functions must be payable so that it can be called as part of a multicall involving ETH
 */
abstract contract ReaperWrapping is IBaseRelayerLibrary {
    function unwrapReaperVaultToken(
        IReaperTokenVault vaultToken,
        address sender,
        address recipient,
        uint256 amount,
        uint256 outputReference
    ) external payable {
        amount = _resolveAmountAndPullToken(vaultToken, amount, sender);

        // Burn the rf shares and receive the underlying token.
        vaultToken.withdraw(amount);

        IERC20 underlyingToken = IERC20(vaultToken.token());
        // Determine the amount of underlying returned for the shares burned.
        uint256 withdrawnAmount = underlyingToken.balanceOf(address(this));

        _transferAndSetChainedReference(underlyingToken, recipient, withdrawnAmount, outputReference);
    }

    function wrapReaperVaultToken(
        IReaperTokenVault vaultToken,
        address sender,
        address recipient,
        uint256 amount,
        uint256 outputReference
    ) external payable {
        IERC20 underlyingToken = IERC20(vaultToken.token());

        amount = _resolveAmountPullTokenAndApproveSpender(underlyingToken, address(vaultToken), amount, sender);

        // Deposit the tokens into the vault
        vaultToken.deposit(amount);

        // Determine the amount of shares gained from depositing
        uint256 sharesGained = vaultToken.balanceOf(address(this));

        _transferAndSetChainedReference(vaultToken, recipient, sharesGained, outputReference);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-interfaces/contracts/standalone-utils/ISilo.sol";
import "@balancer-labs/v2-interfaces/contracts/standalone-utils/IShareToken.sol";

import "./IBaseRelayerLibrary.sol";

/**
 * @title SiloWrapping
 * @notice Allows users to wrap and unwrap Silo shareTokens
 * @dev All functions must be payable so they can be called from a multicall involving ETH
 */
abstract contract SiloWrapping is IBaseRelayerLibrary {
    function wrapShareToken(
        IShareToken wrappedToken,
        address sender,
        address recipient,
        uint256 amount,
        uint256 outputReference
    ) external payable {
        // Initialize the token we will be wrapping (underlying asset of shareToken)
        IERC20 underlyingToken = IERC20(wrappedToken.asset());
        // Initialize the corresponding Silo (Liquidity Pool)
        ISilo silo = wrappedToken.silo();

        amount = _resolveAmountPullTokenAndApproveSpender(underlyingToken, address(silo), amount, sender);

        // the collateralOnly param is set to false because we want to receive interest bearing shareTokens
        (, uint256 result) = silo.depositFor(address(underlyingToken), recipient, amount, false);

        _setChainedReference(outputReference, result);
    }

    function unwrapShareToken(
        IShareToken wrappedToken,
        address sender,
        address recipient,
        uint256 amount,
        uint256 outputReference
    ) external payable {
        amount = _resolveAmountAndPullToken(wrappedToken, amount, sender);

        // Initialize the corresponding Silo (Liquidity Pool)
        ISilo silo = wrappedToken.silo();
        IERC20 underlyingToken = IERC20(wrappedToken.asset());

        // No approval is needed here, as the shareTokens are burned directly from the relayer's account.
        // Setting the amount to type(uint256).max informs Silo that we'd like to redeem all the relayer's shares.
        // Ignore the return value which cannot be trusted. It does not include any fees assessed.
        silo.withdraw(address(underlyingToken), type(uint256).max, false);

        uint256 result = underlyingToken.balanceOf(address(this));

        _transferAndSetChainedReference(underlyingToken, recipient, result, outputReference);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-interfaces/contracts/standalone-utils/ITetuSmartVault.sol";

import "./IBaseRelayerLibrary.sol";

/**
 * @title TetuWrapping
 * @notice Allows users to wrap and unwrap Tetu tokens
 * @dev All functions must be payable so they can be called from a multicall involving ETH
 */
abstract contract TetuWrapping is IBaseRelayerLibrary {
    function wrapTetu(
        ITetuSmartVault wrappedToken,
        address sender,
        address recipient,
        uint256 amount,
        uint256 outputReference
    ) external payable {
        IERC20 underlying = IERC20(wrappedToken.underlying());

        amount = _resolveAmountPullTokenAndApproveSpender(underlying, address(wrappedToken), amount, sender);

        wrappedToken.deposit(amount);
        uint256 receivedWrappedAmount = wrappedToken.balanceOf(address(this));

        _transferAndSetChainedReference(wrappedToken, recipient, receivedWrappedAmount, outputReference);
    }

    function unwrapTetu(
        ITetuSmartVault wrappedToken,
        address sender,
        address recipient,
        uint256 amount,
        uint256 outputReference
    ) external payable {
        amount = _resolveAmountAndPullToken(wrappedToken, amount, sender);

        IERC20 mainToken = IERC20(wrappedToken.underlying());
        wrappedToken.withdraw(amount);
        uint256 withdrawnMainAmount = mainToken.balanceOf(address(this));

        _transferAndSetChainedReference(mainToken, recipient, withdrawnMainAmount, outputReference);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-interfaces/contracts/standalone-utils/IUnbuttonToken.sol";

import "./IBaseRelayerLibrary.sol";

/**
 * @title UnbuttonWrapping
 * @author @aalavandhan1984 ([email protected])
 * @notice Allows users to wrap and unwrap any rebasing elastic balance token into a
 *         a non-rebasing static balance version using the Unbutton wrapper.
 * @dev All functions must be payable so that it can be called as part of a multicall involving ETH.
 *      The rebasing token to be wrapped is called the "underlying" token.
 *      The wrapped non-rebasing token is called the "wrapped" token.
 *      Learn more: https://github.com/buttonwood-protocol/button-wrappers/blob/main/contracts/UnbuttonToken.sol
 */
abstract contract UnbuttonWrapping is IBaseRelayerLibrary {
    /// @param wrapperToken The address of the wrapper.
    /// @param sender The address of sender.
    /// @param sender The address of recepient.
    /// @param uAmount The underling token amount to be deposited into the wrapper.
    /// @param outputReference Chained output reference.
    function wrapUnbuttonToken(
        IUnbuttonToken wrapperToken,
        address sender,
        address recipient,
        uint256 uAmount,
        uint256 outputReference
    ) external payable {
        IERC20 underlyingToken = IERC20(wrapperToken.underlying());

        uAmount = _resolveAmountPullTokenAndApproveSpender(underlyingToken, address(wrapperToken), uAmount, sender);

        uint256 mintAmount = wrapperToken.depositFor(recipient, uAmount);

        _setChainedReference(outputReference, mintAmount);
    }

    /// @param wrapperToken The address of the wrapper.
    /// @param sender The address of sender.
    /// @param sender The address of recepient.
    /// @param amount The amount of wrapped tokens to be burnt for underlying tokens.
    /// @param outputReference Chained output reference.
    function unwrapUnbuttonToken(
        IUnbuttonToken wrapperToken,
        address sender,
        address recipient,
        uint256 amount,
        uint256 outputReference
    ) external payable {
        amount = _resolveAmountAndPullToken(wrapperToken, amount, sender);

        uint256 withdrawnUAmount = wrapperToken.burnTo(recipient, amount);

        _setChainedReference(outputReference, withdrawnUAmount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import "@balancer-labs/v2-interfaces/contracts/pool-weighted/WeightedPoolUserData.sol";
import "@balancer-labs/v2-interfaces/contracts/pool-stable/StablePoolUserData.sol";

import "@balancer-labs/v2-solidity-utils/contracts/helpers/InputHelpers.sol";
import "@balancer-labs/v2-solidity-utils/contracts/helpers/VaultHelpers.sol";
import "@balancer-labs/v2-solidity-utils/contracts/math/Math.sol";

import "./IBaseRelayerLibrary.sol";

/**
 * @title VaultActions
 * @notice Allows users to call the core functions on the Balancer Vault (swaps/joins/exits/user balance management)
 * @dev Since the relayer is not expected to hold user funds, we expect the user to be the recipient of any token
 * transfers from the Vault.
 *
 * All functions must be payable so they can be called from a multicall involving ETH
 */
abstract contract VaultActions is IBaseRelayerLibrary {
    using Math for uint256;

    /**
     * @dev In a relayer, "chaining" - passing values between otherwise independent operations in a multicall - is
     * achieved by passing reference structures between operations. Each reference has an index, corresponding to
     * an offset into the input or output array (e.g., 0 means the first element of the inputs or results), and
     * a key (computed from a hash of the index and some text), which is interpreted as a storage slot. Note that
     * the actual data of the reference is NOT stored in the reference structure, but rather at the storage slot
     * given by the key.
     *
     * The relayer uses masking on the unused MSB bits of all incoming and outgoing values to identify which are
     * references, and which are simply values that can be used directly. Incoming references are replaced with
     * their values before being forwarded to the underlying function. Likewise, outputs of underlying functions
     * that need to be chained are converted to references before being passed as inputs to the next function.
     * See `BaseRelayerLibrary`.
     */
    struct OutputReference {
        uint256 index;
        uint256 key;
    }

    function swap(
        IVault.SingleSwap memory singleSwap,
        IVault.FundManagement calldata funds,
        uint256 limit,
        uint256 deadline,
        uint256 value,
        uint256 outputReference
    ) external payable {
        require(funds.sender == msg.sender || funds.sender == address(this), "Incorrect sender");

        if (_isChainedReference(singleSwap.amount)) {
            singleSwap.amount = _getChainedReferenceValue(singleSwap.amount);
        }

        uint256 result = getVault().swap{ value: value }(singleSwap, funds, limit, deadline);

        if (_isChainedReference(outputReference)) {
            _setChainedReferenceValue(outputReference, result);
        }
    }

    function batchSwap(
        IVault.SwapKind kind,
        IVault.BatchSwapStep[] memory swaps,
        IAsset[] calldata assets,
        IVault.FundManagement calldata funds,
        int256[] calldata limits,
        uint256 deadline,
        uint256 value,
        OutputReference[] calldata outputReferences
    ) external payable {
        require(funds.sender == msg.sender || funds.sender == address(this), "Incorrect sender");

        for (uint256 i = 0; i < swaps.length; ++i) {
            uint256 amount = swaps[i].amount;
            if (_isChainedReference(amount)) {
                swaps[i].amount = _getChainedReferenceValue(amount);
            }
        }

        int256[] memory results = getVault().batchSwap{ value: value }(kind, swaps, assets, funds, limits, deadline);

        for (uint256 i = 0; i < outputReferences.length; ++i) {
            require(_isChainedReference(outputReferences[i].key), "invalid chained reference");

            // Batch swap return values are signed, as they are Vault deltas (positive values correspond to assets sent
            // to the Vault, and negative values are assets received from the Vault). To simplify the chained reference
            // value model, we simply store the absolute value.
            // This should be fine for most use cases, as the caller can reason about swap results via the `limits`
            // parameter.
            _setChainedReferenceValue(outputReferences[i].key, Math.abs(results[outputReferences[i].index]));
        }
    }

    function manageUserBalance(
        IVault.UserBalanceOp[] memory ops,
        uint256 value,
        OutputReference[] calldata outputReferences
    ) external payable {
        for (uint256 i = 0; i < ops.length; i++) {
            require(ops[i].sender == msg.sender || ops[i].sender == address(this), "Incorrect sender");

            uint256 amount = ops[i].amount;
            if (_isChainedReference(amount)) {
                ops[i].amount = _getChainedReferenceValue(amount);
            }
        }

        getVault().manageUserBalance{ value: value }(ops);

        // `manageUserBalance` does not return results, but there is no calculation of amounts as with swaps.
        // We can just use the original amounts.
        for (uint256 i = 0; i < outputReferences.length; ++i) {
            require(_isChainedReference(outputReferences[i].key), "invalid chained reference");

            _setChainedReferenceValue(outputReferences[i].key, ops[outputReferences[i].index].amount);
        }
    }

    enum PoolKind { WEIGHTED, LEGACY_STABLE, COMPOSABLE_STABLE, COMPOSABLE_STABLE_V2 }

    function joinPool(
        bytes32 poolId,
        PoolKind kind,
        address sender,
        address recipient,
        IVault.JoinPoolRequest memory request,
        uint256 value,
        uint256 outputReference
    ) external payable {
        require(sender == msg.sender || sender == address(this), "Incorrect sender");

        // The output of a join will be the Pool's token contract, typically known as BPT (Balancer Pool Tokens).
        // Since the Vault is unaware of this (BPT tokens are minted directly to the recipient), we manually
        // measure this balance increase: but only if an output reference is provided.
        IERC20 bpt = IERC20(VaultHelpers.toPoolAddress(poolId));
        uint256 maybeInitialRecipientBPT = _isChainedReference(outputReference) ? bpt.balanceOf(recipient) : 0;

        request.userData = _doJoinPoolChainedReferenceReplacements(kind, request.userData);

        getVault().joinPool{ value: value }(poolId, sender, recipient, request);

        if (_isChainedReference(outputReference)) {
            // In this context, `maybeInitialRecipientBPT` is guaranteed to have been initialized, so we can safely read
            // from it. Note that we assume the recipient balance change has a positive sign (i.e. the recipient
            // received BPT).
            uint256 finalRecipientBPT = bpt.balanceOf(recipient);
            _setChainedReferenceValue(outputReference, finalRecipientBPT.sub(maybeInitialRecipientBPT));
        }
    }

    /**
     * @dev Compute the final userData for a join, depending on the PoolKind, performing replacements for chained
     * references as necessary.
     */
    function _doJoinPoolChainedReferenceReplacements(PoolKind kind, bytes memory userData)
        private
        returns (bytes memory)
    {
        if (kind == PoolKind.WEIGHTED) {
            return _doWeightedJoinChainedReferenceReplacements(userData);
        } else if (
            kind == PoolKind.LEGACY_STABLE ||
            kind == PoolKind.COMPOSABLE_STABLE ||
            kind == PoolKind.COMPOSABLE_STABLE_V2
        ) {
            return _doStableJoinChainedReferenceReplacements(userData);
        } else {
            revert("UNHANDLED_POOL_KIND");
        }
    }

    function _doWeightedJoinChainedReferenceReplacements(bytes memory userData) private returns (bytes memory) {
        WeightedPoolUserData.JoinKind kind = WeightedPoolUserData.joinKind(userData);

        if (kind == WeightedPoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT) {
            return _doWeightedExactTokensInForBPTOutReplacements(userData);
        } else {
            // All other join kinds are 'given out' (i.e the parameter is a BPT amount),
            // so we don't do replacements for those.
            return userData;
        }
    }

    function _doWeightedExactTokensInForBPTOutReplacements(bytes memory userData) private returns (bytes memory) {
        (uint256[] memory amountsIn, uint256 minBPTAmountOut) = WeightedPoolUserData.exactTokensInForBptOut(userData);

        // Save gas by only re-encoding the data if we actually performed a replacement
        return
            _replacedAmounts(amountsIn)
                ? abi.encode(WeightedPoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, amountsIn, minBPTAmountOut)
                : userData;
    }

    function _doStableJoinChainedReferenceReplacements(bytes memory userData) private returns (bytes memory) {
        // The only 'given in' join (in which the parameters are the amounts in) is EXACT_TOKENS_IN_FOR_BPT_OUT,
        // so that is the only one where we do replacements. Luckily all versions of Stable Pool share the same
        // enum value for it, so we can treat them all the same, and just use the latest version.

        // Note that ComposableStablePool versions V2 and up support a proportional join kind, which some previous
        // versions did not. While it is not rejected here, if passed to the Pool it will revert.

        StablePoolUserData.JoinKind kind = StablePoolUserData.joinKind(userData);

        if (kind == StablePoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT) {
            return _doStableExactTokensInForBPTOutReplacements(userData);
        } else {
            // All other join kinds are 'given out' (i.e the parameter is a BPT amount),
            // so we don't do replacements for those.
            return userData;
        }
    }

    function _doStableExactTokensInForBPTOutReplacements(bytes memory userData) private returns (bytes memory) {
        (uint256[] memory amountsIn, uint256 minBPTAmountOut) = StablePoolUserData.exactTokensInForBptOut(userData);

        // Save gas by only re-encoding the data if we actually performed a replacement
        return
            _replacedAmounts(amountsIn)
                ? abi.encode(StablePoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, amountsIn, minBPTAmountOut)
                : userData;
    }

    // Mutates amountsIn, and returns true if any replacements were made
    function _replacedAmounts(uint256[] memory amountsIn) private returns (bool) {
        bool madeReplacements = false;

        for (uint256 i = 0; i < amountsIn.length; ++i) {
            uint256 amount = amountsIn[i];
            if (_isChainedReference(amount)) {
                amountsIn[i] = _getChainedReferenceValue(amount);
                madeReplacements = true;
            }
        }

        return madeReplacements;
    }

    function exitPool(
        bytes32 poolId,
        PoolKind kind,
        address sender,
        address payable recipient,
        IVault.ExitPoolRequest memory request,
        OutputReference[] calldata outputReferences
    ) external payable {
        require(sender == msg.sender || sender == address(this), "Incorrect sender");

        // To track the changes of internal balances, we need an array of token addresses.
        // We save this here to avoid having to recalculate after the exit.
        IERC20[] memory trackedTokens = new IERC20[](outputReferences.length);

        // Query initial balances for all tokens, and record them as chained references
        uint256[] memory initialRecipientBalances = new uint256[](outputReferences.length);
        for (uint256 i = 0; i < outputReferences.length; i++) {
            require(_isChainedReference(outputReferences[i].key), "invalid chained reference");

            IAsset asset = request.assets[outputReferences[i].index];
            if (request.toInternalBalance) {
                trackedTokens[i] = _asIERC20(asset);
            } else {
                initialRecipientBalances[i] = _isETH(asset) ? recipient.balance : _asIERC20(asset).balanceOf(recipient);
            }
        }
        if (request.toInternalBalance) {
            initialRecipientBalances = getVault().getInternalBalance(recipient, trackedTokens);
        }

        // Exit the Pool
        request.userData = _doExitPoolChainedReferenceReplacements(kind, request.userData);
        getVault().exitPool(poolId, sender, recipient, request);

        // Query final balances for all tokens of interest
        uint256[] memory finalRecipientTokenBalances = new uint256[](outputReferences.length);
        if (request.toInternalBalance) {
            finalRecipientTokenBalances = getVault().getInternalBalance(recipient, trackedTokens);
        } else {
            for (uint256 i = 0; i < outputReferences.length; i++) {
                IAsset asset = request.assets[outputReferences[i].index];
                finalRecipientTokenBalances[i] = _isETH(asset)
                    ? recipient.balance
                    : _asIERC20(asset).balanceOf(recipient);
            }
        }

        // Calculate deltas and save as chained references
        for (uint256 i = 0; i < outputReferences.length; i++) {
            _setChainedReferenceValue(
                outputReferences[i].key,
                finalRecipientTokenBalances[i].sub(initialRecipientBalances[i])
            );
        }
    }

    /**
     * @dev Compute the final userData for an exit, depending on the PoolKind, performing replacements for chained
     * references as necessary.
     */
    function _doExitPoolChainedReferenceReplacements(PoolKind kind, bytes memory userData)
        private
        returns (bytes memory)
    {
        if (kind == PoolKind.WEIGHTED) {
            return _doWeightedExitChainedReferenceReplacements(userData);
        } else {
            if (kind == PoolKind.LEGACY_STABLE) {
                return _doLegacyStableExitChainedReferenceReplacements(userData);
            } else if (kind == PoolKind.COMPOSABLE_STABLE) {
                return _doComposableStableExitChainedReferenceReplacements(userData);
            } else if (kind == PoolKind.COMPOSABLE_STABLE_V2) {
                return _doComposableStableV2ExitChainedReferenceReplacements(userData);
            } else {
                revert("UNHANDLED_POOL_KIND");
            }
        }
    }

    function _doWeightedExitChainedReferenceReplacements(bytes memory userData) private returns (bytes memory) {
        WeightedPoolUserData.ExitKind kind = WeightedPoolUserData.exitKind(userData);

        if (kind == WeightedPoolUserData.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT) {
            return _doWeightedExactBptInForOneTokenOutReplacements(userData);
        } else if (kind == WeightedPoolUserData.ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT) {
            return _doWeightedExactBptInForTokensOutReplacements(userData);
        } else {
            // All other exit kinds are 'given out' (i.e the parameter is a token amount),
            // so we don't do replacements for those.
            return userData;
        }
    }

    function _doWeightedExactBptInForOneTokenOutReplacements(bytes memory userData) private returns (bytes memory) {
        (uint256 bptAmountIn, uint256 tokenIndex) = WeightedPoolUserData.exactBptInForTokenOut(userData);

        if (_isChainedReference(bptAmountIn)) {
            bptAmountIn = _getChainedReferenceValue(bptAmountIn);
            return abi.encode(WeightedPoolUserData.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, bptAmountIn, tokenIndex);
        } else {
            // Save gas by only re-encoding the data if we actually performed a replacement
            return userData;
        }
    }

    function _doWeightedExactBptInForTokensOutReplacements(bytes memory userData) private returns (bytes memory) {
        uint256 bptAmountIn = WeightedPoolUserData.exactBptInForTokensOut(userData);

        if (_isChainedReference(bptAmountIn)) {
            bptAmountIn = _getChainedReferenceValue(bptAmountIn);
            return abi.encode(WeightedPoolUserData.ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT, bptAmountIn);
        } else {
            // Save gas by only re-encoding the data if we actually performed a replacement
            return userData;
        }
    }

    // Stable Pool version-dependent recoding dispatch functions

    /*
     * While all Stable Pool versions fortuitously support the same join kinds (V2 and higher support one extra),
     * they do NOT all support the same exit kinds. Also, though the encoding of the data associated with the exit
     * is uniform across pool kinds for the same exit method, the ExitKind ID itself may have a different value.
     *
     * For instance, BPT_IN_FOR_EXACT_TOKENS_OUT is 2 in legacy Stable Pools, but 1 in Composable Stable Pools.
     * (See the reference comment and libraries below.)
     *
     * Accordingly, the three do[PoolKind]ExitChainedReferenceReplacements functions below (for LegacyStable,
     * ComposableStable, and CopmosableStableV2) extract the exitKind and pass it through to the shared
     * recoding functions.
     */

    function _doLegacyStableExitChainedReferenceReplacements(bytes memory userData) private returns (bytes memory) {
        uint8 exitKind = uint8(StablePoolUserData.exitKind(userData));

        if (exitKind == uint8(LegacyStablePoolUserData.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT)) {
            return _doStableExactBptInForOneTokenOutReplacements(userData, exitKind);
        } else if (exitKind == uint8(LegacyStablePoolUserData.ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT)) {
            return _doStableExactBptInForTokensOutReplacements(userData, exitKind);
        } else {
            // All other exit kinds are 'given out' (i.e the parameter is a token amount),
            // so we don't do replacements for those.
            return userData;
        }
    }

    // For the first deployment of ComposableStablePool
    function _doComposableStableExitChainedReferenceReplacements(bytes memory userData) private returns (bytes memory) {
        uint8 exitKind = uint8(StablePoolUserData.exitKind(userData));

        if (exitKind == uint8(ComposableStablePoolUserData.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT)) {
            return _doStableExactBptInForOneTokenOutReplacements(userData, exitKind);
        } else {
            // All other exit kinds are 'given out' (i.e the parameter is a token amount),
            // so we don't do replacements for those.
            return userData;
        }
    }

    // For ComposableStablePool V2 and V3
    function _doComposableStableV2ExitChainedReferenceReplacements(bytes memory userData)
        private
        returns (bytes memory)
    {
        uint8 exitKind = uint8(StablePoolUserData.exitKind(userData));

        if (exitKind == uint8(StablePoolUserData.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT)) {
            return _doStableExactBptInForOneTokenOutReplacements(userData, exitKind);
        } else if (exitKind == uint8(StablePoolUserData.ExitKind.EXACT_BPT_IN_FOR_ALL_TOKENS_OUT)) {
            return _doStableExactBptInForTokensOutReplacements(userData, exitKind);
        } else {
            // All other exit kinds are 'given out' (i.e the parameter is a token amount),
            // so we don't do replacements for those.
            return userData;
        }
    }

    // Shared Stable Exit recoding functions

    // The following two functions perform the actual recoding, which involves parsing and re-encoding the userData.
    // The encoding of the actual arguments is uniform across pool kinds, which allows these recoding functions to be
    // shared. However, the ExitKind ID itself can vary, so it must be passed in from each specific pool kind handler.

    function _doStableExactBptInForOneTokenOutReplacements(bytes memory userData, uint8 exitKind)
        private
        returns (bytes memory)
    {
        (uint256 bptAmountIn, uint256 tokenIndex) = StablePoolUserData.exactBptInForTokenOut(userData);

        if (_isChainedReference(bptAmountIn)) {
            bptAmountIn = _getChainedReferenceValue(bptAmountIn);
            return abi.encode(exitKind, bptAmountIn, tokenIndex);
        } else {
            // Save gas by only re-encoding the data if we actually performed a replacement
            return userData;
        }
    }

    function _doStableExactBptInForTokensOutReplacements(bytes memory userData, uint8 exitKind)
        private
        returns (bytes memory)
    {
        uint256 bptAmountIn = StablePoolUserData.exactBptInForTokensOut(userData);

        if (_isChainedReference(bptAmountIn)) {
            bptAmountIn = _getChainedReferenceValue(bptAmountIn);
            return abi.encode(exitKind, bptAmountIn);
        } else {
            // Save gas by only re-encoding the data if we actually performed a replacement
            return userData;
        }
    }
}

/*
    For reference:

    StablePoolUserData (applies to ComposableStablePool V2+):

    enum JoinKind { INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT, ALL_TOKENS_IN_FOR_EXACT_BPT_OUT }
    enum ExitKind { EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT, EXACT_BPT_IN_FOR_ALL_TOKENS_OUT }

    WeightedPoolUserData:

    enum JoinKind { INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT, ALL_TOKENS_IN_FOR_EXACT_BPT_OUT }
    enum ExitKind { EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, EXACT_BPT_IN_FOR_TOKENS_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT }

    StablePhantomPools can only be exited proportionally when the pool is paused: and the pause window has expired.
    They have their own enum:

    enum ExitKindPhantom { EXACT_BPT_IN_FOR_TOKENS_OUT }
*/

// Applies to StablePool, MetaStablePool, StablePool V2
library LegacyStablePoolUserData {
    enum JoinKind { INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT }
    enum ExitKind { EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, EXACT_BPT_IN_FOR_TOKENS_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT }
}

// Applies to the first deployment of ComposableStablePool (pre-Versioning)
library ComposableStablePoolUserData {
    enum JoinKind { INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT }
    enum ExitKind { EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/openzeppelin/IERC20Permit.sol";
import "@balancer-labs/v2-interfaces/contracts/solidity-utils/openzeppelin/IERC20PermitDAI.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";

import "./IBaseRelayerLibrary.sol";

/**
 * @title VaultPermit
 * @notice Allows users to use permit (where supported) to approve the Balancer Vault to use their tokens
 * @dev All functions must be payable so they can be called from a multicall involving ETH
 */
abstract contract VaultPermit is IBaseRelayerLibrary {
    function vaultPermit(
        IERC20Permit token,
        address owner,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        token.permit(owner, address(getVault()), value, deadline, v, r, s);
    }

    function vaultPermitDAI(
        IERC20PermitDAI token,
        address holder,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        token.permit(holder, address(getVault()), nonce, expiry, allowed, v, r, s);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-interfaces/contracts/standalone-utils/IYearnTokenVault.sol";

import "./IBaseRelayerLibrary.sol";

/**
 * @title YearnWrapping
 * @notice Allows users to wrap and unwrap Yearn tokens
 * @dev All functions must be payable so they can be called from a multicall involving ETH
 */
abstract contract YearnWrapping is IBaseRelayerLibrary {
    function wrapYearn(
        IYearnTokenVault wrappedToken,
        address sender,
        address recipient,
        uint256 amount,
        uint256 outputReference
    ) external payable {
        IERC20 underlying = IERC20(wrappedToken.token());

        amount = _resolveAmountPullTokenAndApproveSpender(underlying, address(wrappedToken), amount, sender);

        uint256 receivedWrappedAmount = wrappedToken.deposit(amount, recipient);

        _setChainedReference(outputReference, receivedWrappedAmount);
    }

    function unwrapYearn(
        IYearnTokenVault wrappedToken,
        address sender,
        address recipient,
        uint256 amount,
        uint256 outputReference
    ) external payable {
        amount = _resolveAmountAndPullToken(IERC20(address(wrappedToken)), amount, sender);

        uint256 mainAmount = wrappedToken.withdraw(amount, recipient);

        _setChainedReference(outputReference, mainAmount);
    }
}