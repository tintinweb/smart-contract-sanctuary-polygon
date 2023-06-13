// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

/*
GysrUtils

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "./MathUtils.sol";

/**
 * @title GYSR utilities
 *
 * @notice this library implements utility methods for the GYSR multiplier
 * and spending mechanics
 */
library GysrUtils {
    using MathUtils for int128;

    // constants
    uint256 public constant GYSR_PROPORTION = 1e16; // 1%

    /**
     * @notice compute GYSR bonus as a function of usage ratio, stake amount,
     * and GYSR spent
     * @param gysr number of GYSR token applied to bonus
     * @param amount number of tokens or shares to unstake
     * @param total number of tokens or shares in overall pool
     * @param ratio usage ratio from 0 to 1
     * @return multiplier value
     */
    function gysrBonus(
        uint256 gysr,
        uint256 amount,
        uint256 total,
        uint256 ratio
    ) internal pure returns (uint256) {
        if (amount == 0) {
            return 0;
        }
        if (total == 0) {
            return 0;
        }
        if (gysr == 0) {
            return 1e18;
        }

        // scale GYSR amount with respect to proportion
        uint256 portion = (GYSR_PROPORTION * total) / 1e18;
        if (amount > portion) {
            gysr = (gysr * portion) / amount;
        }

        // 1 + gysr / (0.01 + ratio)
        uint256 x = 2 ** 64 + (2 ** 64 * gysr) / (1e16 + ratio);

        return
            1e18 +
            (uint256(int256(int128(uint128(x)).logbase10())) * 1e18) /
            2 ** 64;
    }
}

/*
ERC20FriendlyRewardModuleInfo

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../interfaces/IRewardModule.sol";
import "./IERC20FriendlyRewardModuleV2.sol";
import "../GysrUtils.sol";
import "./TokenUtilsInfo.sol";

/**
 * @title ERC20 friendly reward module info library
 *
 * @notice this library provides read-only convenience functions to query
 * additional information about the ERC20FriendlyRewardModule contract.
 */
library ERC20FriendlyRewardModuleInfo {
    using GysrUtils for uint256;
    using TokenUtilsInfo for IERC20;

    /**
     * @notice get all token metadata
     * @param module address of reward module
     * @return addresses_
     * @return names_
     * @return symbols_
     * @return decimals_
     */
    function tokens(
        address module
    )
        external
        view
        returns (
            address[] memory addresses_,
            string[] memory names_,
            string[] memory symbols_,
            uint8[] memory decimals_
        )
    {
        addresses_ = new address[](1);
        names_ = new string[](1);
        symbols_ = new string[](1);
        decimals_ = new uint8[](1);
        (addresses_[0], names_[0], symbols_[0], decimals_[0]) = token(module);
    }

    /**
     * @notice convenience function to get token metadata in a single call
     * @param module address of reward module
     * @return address
     * @return name
     * @return symbol
     * @return decimals
     */
    function token(
        address module
    ) public view returns (address, string memory, string memory, uint8) {
        IRewardModule m = IRewardModule(module);
        IERC20Metadata tkn = IERC20Metadata(m.tokens()[0]);
        return (address(tkn), tkn.name(), tkn.symbol(), tkn.decimals());
    }

    /**
     * @notice generic function to get pending reward balances
     * @param module address of reward module
     * @param account bytes32 account of interest for preview
     * @param shares number of shares that would be used
     * @return rewards_ estimated reward balances
     */
    function rewards(
        address module,
        bytes32 account,
        uint256 shares,
        bytes calldata
    ) public view returns (uint256[] memory rewards_) {
        rewards_ = new uint256[](1);
        (rewards_[0], , ) = preview(module, account, shares);
    }

    /**
     * @notice preview estimated rewards
     * @param module address of reward module
     * @param account bytes32 account of interest for preview
     * @param shares number of shares that would be unstaked
     * @return estimated reward
     * @return estimated time multiplier weighted by rewards
     * @return estimated gysr multiplier weighted by rewards
     */
    function preview(
        address module,
        bytes32 account,
        uint256 shares
    ) public view returns (uint256, uint256, uint256) {
        require(shares > 0, "frmi1");
        IERC20FriendlyRewardModuleV2 m = IERC20FriendlyRewardModuleV2(module);
        address user = address(uint160(uint256(account)));

        uint256 reward;
        uint256 rawSum;
        uint256 bonusSum;

        uint256 i = m.stakeCount(user);

        // redeem first-in-last-out
        while (shares > 0) {
            require(i > 0, "frmi2");
            i -= 1;

            (uint256 s, , , , ) = m.stakes(user, i);

            // only redeem partial stake if more shares left than needed to burn
            s = s <= shares ? s : shares;

            uint256 r;
            {
                r = rewardsPerStakedShare(module);
            }

            {
                (, , , uint256 tally, ) = m.stakes(user, i);
                r = ((r - tally) * s) / 1e18;
                rawSum += r;
            }

            {
                (, , uint256 bonus, , ) = m.stakes(user, i);
                r = (r * bonus) / 1e18;
                bonusSum += r;
            }

            {
                (, , , , uint256 time) = m.stakes(user, i);
                r = (r * m.timeVestingCoefficient(time)) / 1e18;
            }
            reward += r;
            shares -= s;
        }

        address tkn = m.tokens()[0];
        return (
            IERC20(tkn).getAmount(module, m.totalShares(tkn), reward),
            reward > 0 ? (reward * 1e18) / bonusSum : 0,
            reward > 0 ? (bonusSum * 1e18) / rawSum : 0
        );
    }

    /**
     * @notice compute reward shares to be unlocked on the next update
     * @param module address of reward module
     * @return estimated unlockable rewards
     */
    function unlockable(address module) public view returns (uint256) {
        IERC20FriendlyRewardModuleV2 m = IERC20FriendlyRewardModuleV2(module);
        address tkn = m.tokens()[0];
        if (m.lockedShares(tkn) == 0) {
            return 0;
        }
        uint256 sharesToUnlock = 0;
        for (uint256 i = 0; i < m.fundingCount(tkn); i++) {
            sharesToUnlock = sharesToUnlock + m.unlockable(tkn, i);
        }
        return sharesToUnlock;
    }

    /**
     * @notice compute effective unlocked rewards
     * @param module address of reward module
     * @return estimated current unlocked rewards
     */
    function unlocked(address module) public view returns (uint256) {
        IERC20FriendlyRewardModuleV2 m = IERC20FriendlyRewardModuleV2(module);
        IERC20 tkn = IERC20(m.tokens()[0]);
        uint256 totalShares = m.totalShares(address(tkn));
        if (totalShares == 0) {
            return 0;
        }
        uint256 shares = unlockable(module);
        uint256 amount = tkn.getAmount(module, totalShares, shares);
        return m.totalUnlocked() + amount;
    }

    /**
     * @notice compute effective rewards per staked share
     * @param module module contract address
     * @return estimated rewards per staked share
     */
    function rewardsPerStakedShare(
        address module
    ) public view returns (uint256) {
        IERC20FriendlyRewardModuleV2 m = IERC20FriendlyRewardModuleV2(module);
        if (m.totalStakingShares() == 0) {
            return m.rewardsPerStakedShare();
        }
        uint256 rewardsToUnlock = unlockable(module) + m.rewardDust();
        return
            m.rewardsPerStakedShare() +
            (rewardsToUnlock * 1e18) /
            m.totalStakingShares();
    }

    /**
     * @notice compute estimated GYSR bonus for stake
     * @param module module contract address
     * @param shares number of shares that would be staked
     * @param gysr number of GYSR tokens that would be applied to stake
     * @return estimated GYSR multiplier
     */
    function gysrBonus(
        address module,
        uint256 shares,
        uint256 gysr
    ) public view returns (uint256) {
        IERC20FriendlyRewardModuleV2 m = IERC20FriendlyRewardModuleV2(module);
        return
            gysr.gysrBonus(
                shares,
                m.totalRawStakingShares() + shares,
                m.usage()
            );
    }
}

/*
IERC20FriendlyRewardModuleV2

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

/**
 * @title Friendly reward module interface
 *
 * @notice this declares the interface for the v2 friendly reward module
 * to provide backwards compatibility in the pool info system
 */
interface IERC20FriendlyRewardModuleV2 {
    // -- IRewardModule -------------------------------------------------------
    function tokens() external view returns (address[] memory);

    function balances() external view returns (uint256[] memory);

    function usage() external view returns (uint256);

    function factory() external view returns (address);

    // -- IERC20FriendlyRewardModuleV2 ----------------------------------------

    function totalStakingShares() external view returns (uint256);

    function totalRawStakingShares() external view returns (uint256);

    function rewardsPerStakedShare() external view returns (uint256);

    function rewardDust() external view returns (uint256);

    function totalShares(address) external view returns (uint256);

    function lockedShares(address) external view returns (uint256);

    function fundingCount(address) external view returns (uint256);

    function unlockable(address, uint256) external view returns (uint256);

    function totalUnlocked() external view returns (uint256);

    function stakeCount(address) external view returns (uint256);

    function stakes(
        address,
        uint256
    ) external view returns (uint256, uint256, uint256, uint256, uint256);

    function timeVestingCoefficient(uint256) external view returns (uint256);
}

/*
TokenUtilsInfo

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Token utilities info
 *
 * @notice this library implements utility methods for token handling,
 * dynamic balance accounting, and fee processing.
 *
 * this is a modified version to be used by info libraries.
 */
library TokenUtilsInfo {
    uint256 constant INITIAL_SHARES_PER_TOKEN = 1e6;
    uint256 constant FLOOR_SHARES_PER_TOKEN = 1e3;

    /**
     * @notice get token shares from amount
     * @param token erc20 token interface
     * @param module address of module
     * @param total current total shares
     * @param amount balance of tokens
     */
    function getShares(
        IERC20 token,
        address module,
        uint256 total,
        uint256 amount
    ) internal view returns (uint256) {
        if (total == 0) return 0;
        uint256 balance = token.balanceOf(module);
        if (total < balance * FLOOR_SHARES_PER_TOKEN)
            return amount * FLOOR_SHARES_PER_TOKEN;
        return (total * amount) / balance;
    }

    /**
     * @notice get token amount from shares
     * @param token erc20 token interface
     * @param module address of module
     * @param total current total shares
     * @param shares balance of shares
     */
    function getAmount(
        IERC20 token,
        address module,
        uint256 total,
        uint256 shares
    ) internal view returns (uint256) {
        if (total == 0) return 0;
        uint256 balance = token.balanceOf(module);
        if (total < balance * FLOOR_SHARES_PER_TOKEN)
            return shares / FLOOR_SHARES_PER_TOKEN;
        return (balance * shares) / total;
    }
}

/*
IEvents

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
 */

pragma solidity 0.8.18;

/**
 * @title GYSR event system
 *
 * @notice common interface to define GYSR event system
 */
interface IEvents {
    // staking
    event Staked(
        bytes32 indexed account,
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event Unstaked(
        bytes32 indexed account,
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event Claimed(
        bytes32 indexed account,
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event Updated(bytes32 indexed account, address indexed user);

    // rewards
    event RewardsDistributed(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event RewardsFunded(
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );
    event RewardsExpired(
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );
    event RewardsWithdrawn(
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );
    event RewardsUpdated(bytes32 indexed account);

    // gysr
    event GysrSpent(address indexed user, uint256 amount);
    event GysrVested(address indexed user, uint256 amount);
    event GysrWithdrawn(uint256 amount);
    event Fee(address indexed receiver, address indexed token, uint256 amount);
}

/*
IOwnerController

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

/**
 * @title Owner controller interface
 *
 * @notice this defines the interface for any contracts that use the
 * owner controller access pattern
 */
interface IOwnerController {
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);

    /**
     * @dev Returns the address of the current controller.
     */
    function controller() external view returns (address);

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`). This can
     * include renouncing ownership by transferring to the zero address.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external;

    /**
     * @dev Transfers control of the contract to a new account (`newController`).
     * Can only be called by the owner.
     */
    function transferControl(address newController) external;
}

/*
IRewardModule

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IEvents.sol";
import "./IOwnerController.sol";

/**
 * @title Reward module interface
 *
 * @notice this contract defines the common interface that any reward module
 * must implement to be compatible with the modular Pool architecture.
 */
interface IRewardModule is IOwnerController, IEvents {
    /**
     * @return array of reward tokens
     */
    function tokens() external view returns (address[] memory);

    /**
     * @return array of reward token balances
     */
    function balances() external view returns (uint256[] memory);

    /**
     * @return GYSR usage ratio for reward module
     */
    function usage() external view returns (uint256);

    /**
     * @return address of module factory
     */
    function factory() external view returns (address);

    /**
     * @notice perform any necessary accounting for new stake
     * @param account bytes32 id of staking account
     * @param sender address of sender
     * @param shares number of new shares minted
     * @param data addtional data
     * @return amount of gysr spent
     * @return amount of gysr vested
     */
    function stake(
        bytes32 account,
        address sender,
        uint256 shares,
        bytes calldata data
    ) external returns (uint256, uint256);

    /**
     * @notice reward user and perform any necessary accounting for unstake
     * @param account bytes32 id of staking account
     * @param sender address of sender
     * @param receiver address of reward receiver
     * @param shares number of shares burned
     * @param data additional data
     * @return amount of gysr spent
     * @return amount of gysr vested
     */
    function unstake(
        bytes32 account,
        address sender,
        address receiver,
        uint256 shares,
        bytes calldata data
    ) external returns (uint256, uint256);

    /**
     * @notice reward user and perform and necessary accounting for existing stake
     * @param account bytes32 id of staking account
     * @param sender address of sender
     * @param receiver address of reward receiver
     * @param shares number of shares being claimed against
     * @param data additional data
     * @return amount of gysr spent
     * @return amount of gysr vested
     */
    function claim(
        bytes32 account,
        address sender,
        address receiver,
        uint256 shares,
        bytes calldata data
    ) external returns (uint256, uint256);

    /**
     * @notice method called by anyone to update accounting
     * @dev will only be called ad hoc and should not contain essential logic
     * @param account bytes32 id of staking account for update
     * @param sender address of sender
     * @param data additional data
     */
    function update(
        bytes32 account,
        address sender,
        bytes calldata data
    ) external;

    /**
     * @notice method called by owner to clean up and perform additional accounting
     * @dev will only be called ad hoc and should not contain any essential logic
     * @param data additional data
     */
    function clean(bytes calldata data) external;
}

/*
MathUtils

https://github.com/gysr-io/core

SPDX-License-Identifier: BSD-4-Clause
*/

pragma solidity 0.8.18;

/**
 * @title Math utilities
 *
 * @notice this library implements various logarithmic math utilies which support
 * other contracts and specifically the GYSR multiplier calculation
 *
 * @dev h/t https://github.com/abdk-consulting/abdk-libraries-solidity
 */
library MathUtils {
    /**
     * @notice calculate binary logarithm of x
     *
     * @param x signed 64.64-bit fixed point number, require x > 0
     * @return signed 64.64-bit fixed point number
     */
    function logbase2(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0);

            int256 msb = 0;
            int256 xc = x;
            if (xc >= 0x10000000000000000) {
                xc >>= 64;
                msb += 64;
            }
            if (xc >= 0x100000000) {
                xc >>= 32;
                msb += 32;
            }
            if (xc >= 0x10000) {
                xc >>= 16;
                msb += 16;
            }
            if (xc >= 0x100) {
                xc >>= 8;
                msb += 8;
            }
            if (xc >= 0x10) {
                xc >>= 4;
                msb += 4;
            }
            if (xc >= 0x4) {
                xc >>= 2;
                msb += 2;
            }
            if (xc >= 0x2) msb += 1; // No need to shift xc anymore

            int256 result = (msb - 64) << 64;
            uint256 ux = uint256(int256(x)) << uint256(127 - msb);
            for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
                ux *= ux;
                uint256 b = ux >> 255;
                ux >>= 127 + b;
                result += bit * int256(b);
            }

            return int128(result);
        }
    }

    /**
     * @notice calculate natural logarithm of x
     * @dev magic constant comes from ln(2) * 2^128 -> hex
     * @param x signed 64.64-bit fixed point number, require x > 0
     * @return signed 64.64-bit fixed point number
     */
    function ln(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0);

            return
                int128(
                    int256(
                        (uint256(int256(logbase2(x))) *
                            0xB17217F7D1CF79ABC9E3B39803F2F6AF) >> 128
                    )
                );
        }
    }

    /**
     * @notice calculate logarithm base 10 of x
     * @dev magic constant comes from log10(2) * 2^128 -> hex
     * @param x signed 64.64-bit fixed point number, require x > 0
     * @return signed 64.64-bit fixed point number
     */
    function logbase10(int128 x) internal pure returns (int128) {
        require(x > 0);

        return
            int128(
                int256(
                    (uint256(int256(logbase2(x))) *
                        0x4d104d427de7fce20a6e420e02236748) >> 128
                )
            );
    }

    // wrapper functions to allow testing
    function testlogbase2(int128 x) public pure returns (int128) {
        return logbase2(x);
    }

    function testlogbase10(int128 x) public pure returns (int128) {
        return logbase10(x);
    }
}