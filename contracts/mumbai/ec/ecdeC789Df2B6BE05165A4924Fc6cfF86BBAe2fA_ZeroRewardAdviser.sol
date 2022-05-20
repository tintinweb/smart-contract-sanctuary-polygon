// SPDX-License-Identifier: UNLICENSED
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

import "./interfaces/IRewardAdviser.sol";

/**
 * @dev The "adviser" for the `RewardMaster` that always returns the "zero reward advice"
 * (i.e. rewards with zero `sharesToCreate` and `sharesToRedeem`).
 * On "zero" advices, the RewardMaster skips creating/redeeming "treasure shares" for/to stakers.
 */
contract ZeroRewardAdviser is IRewardAdviser {
    // solhint-disable var-name-mixedcase
    // `stakeType` for "Advance Staking"
    // bytes4(keccak256("advanced"))
    // bytes4 private constant STAKE_TYPE = 0x7ec13a06;
    // `action` for the "staked" and message

    // bytes4(keccak256(abi.encodePacked(bytes4(keccak256("stake"), STAKE_TYPE)))
    bytes4 private constant STAKE = 0x1e4d02b5;
    // `action` for the "unstaked" message
    // bytes4(keccak256(abi.encodePacked(bytes4(keccak256("unstake"), STAKE_TYPE)))
    bytes4 private constant UNSTAKE = 0x493bdf45;

    /// @dev Assumed to be called by the RewardMaster contract.
    /// Always returns the "zero" reward advises, no matter who calls it.
    function getRewardAdvice(bytes4 action, bytes memory)
        external
        pure
        override
        returns (Advice memory)
    {
        require(
            action == UNSTAKE || action == UNSTAKE,
            "SRC: unsupported action"
        );

        // Return "zero" advice
        return
            Advice(
                address(0), // createSharesFor
                0, // sharesToCreate
                address(0), // redeemSharesFrom
                0, // sharesToRedeem
                address(0) // sendRewardTo
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRewardAdviser {
    struct Advice {
        // advice on new "shares" (in the reward pool) to create
        address createSharesFor;
        uint96 sharesToCreate;
        // advice on "shares" to redeem
        address redeemSharesFrom;
        uint96 sharesToRedeem;
        // advice on address the reward against redeemed shares to send to
        address sendRewardTo;
    }

    function getRewardAdvice(bytes4 action, bytes memory message)
        external
        returns (Advice memory);
}