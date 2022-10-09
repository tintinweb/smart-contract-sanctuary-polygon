// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

interface IVesting {
    function endVesting() external returns (uint256);

    function updateVesting(
        address[] calldata contributors,
        uint256[] calldata vestingFlows
    ) external;
}

// Autonomy registration
interface IRegistry {
    function newReq(
        address target,
        address payable referer,
        bytes calldata callData,
        uint112 ethForCall,
        bool verifyUser,
        bool insertFeeAmount,
        bool isAlive
    ) external payable returns (uint256 id);
}

contract VestingConditions {
    IVesting internal _vestingSF;

    error VestingEndingTimeNotReached();
    error VestingFlowNotZero();

    constructor(address vestingSF) {
        _vestingSF = IVesting(vestingSF);
    }

    // AUTONOMY CONDITIONS

    // TODO add mapping ending time per contributor
    function checkVestingEndingTime(address contributor) external {
        uint256 endVesting = _vestingSF.endVesting();
        if (block.timestamp < endVesting) revert VestingEndingTimeNotReached();
    }

    // AUTONOMY REGISTRY
    function createNewRequest(
        address autonomyTarget,
        address vesting,
        address[] calldata contributors,
        uint256[] calldata vestingFlows
    ) internal returns (uint256) {
        bytes memory callDataCondition = abi.encodeWithSelector(
            VestingConditions.checkVestingEndingTime.selector,
            vesting
        );

        bytes memory callDataTrigger = abi.encodeWithSelector(
            VestingConditions.closeVestingFlow.selector,
            contributors,
            vestingFlows
        );

        IRegistry registry = IRegistry(autonomyTarget);
        uint256 reqId = registry.newReq(
            autonomyTarget,
            payable(address(0)),
            abi.encode(callDataCondition, callDataTrigger),
            0,
            true,
            true,
            true
        );
        return reqId;
    }

    // AUTONOMY ACTIONS

    function closeVestingFlow(
        address[] calldata contributors,
        uint256[] calldata vestingFlows
    ) external {
        require(contributors.length == vestingFlows.length, "Length mismatch");
        // Check vestingFlows are set to 0
        for (uint256 i; i < contributors.length; i++) {
            if (vestingFlows[i] != 0) revert VestingFlowNotZero();
        }
        _vestingSF.updateVesting(contributors, vestingFlows);
    }

    function setVesting(address vesting) external {
        _vestingSF = IVesting(vesting);
    }
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