// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Plan} from "./Plan.sol";

library Mapping {
    struct Map {
        bytes32[] keys;
        mapping(bytes32 => Plan) values;
        mapping(bytes32 => uint256) indexOf;
        mapping(bytes32 => bool) inserted;
    }

    function set(Map storage map, bytes32 key, Plan calldata value) external {
        require(!map.inserted[key], "Mapping.set: duplicate");

        map.values[key] = value;
        map.indexOf[key] = map.keys.length;
        map.inserted[key] = true;
        map.keys.push(key);
    }

    function remove(Map storage map, bytes32 key) external {
        require(map.inserted[key], "Mapping.remove: non-existant");

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        bytes32 lastKey = map.keys[map.keys.length - 1];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }

    function exists(Map storage map, bytes32 key) external view returns (bool) {
        return map.inserted[key];
    }

    function get(
        Map storage map,
        bytes32 key
    ) external view returns (Plan storage) {
        return map.values[key];
    }

    function all(Map storage map) external view returns (Plan[] memory) {
        Plan[] memory plans = new Plan[](map.keys.length);

        for (uint256 i = 0; i < map.keys.length; i++)
            plans[i] = map.values[map.keys[i]];

        return plans;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {IBribe} from "../interfaces/IBribe.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

enum PlanStyle {
    ALL,
    FIXED,
    PERCENT
}

struct Plan {
    PlanStyle style;
    IBribe hhBriber;
    address gauge;
    IERC20 token;
    uint256 amount;
    uint256 interval;
    uint256 nextExec;
    uint256 createdAt;
    uint256 remainingEpochs;
    bool canSkip;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBribe {
    function depositBribeERC20(
        bytes32 proposal,
        IERC20 token,
        uint256 amount
    ) external;
}