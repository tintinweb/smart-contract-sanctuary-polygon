/**
 *Submitted for verification at polygonscan.com on 2023-03-09
*/

// Sources flattened with hardhat v2.12.3 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File contracts/pools/Pool.sol

// 
pragma solidity ^0.8.0;

abstract contract Pool {
    // 读取其他合约的相关信息，并完成第二次记账和分账
    function distributeFT(address ft, uint64 mainType, uint64 subType, address player, uint256 amount) external virtual;
}


// File contracts/pools/lottery/AgentPool.sol

// 
pragma solidity ^0.8.0;

/*
节点地址本身来玩，直接把6%给他的SuperNode. 节点一定有SuperNode，否则不会成为Node
成为节点的条件，是 Level3 + 8孙子 + 自己申请操作。
*/

interface IRelationOf {
    function relationOf(address player) external returns (address superNode, address node, address agent, uint64 agentLevel);
}

contract AgentPool is Pool {
    address platform;

    modifier onlyPlatform() {
        require(platform == address(0) || msg.sender == platform, "Not granted");
        _;
    }

    constructor(address _platform) {
        platform = _platform;
    }

    function distributeFT(
        address FT,
        uint64 mainType,
        uint64 subType,
        address player,
        uint256 amount
    ) external onlyPlatform() override {
        mainType; subType; // to avoid warnings of compiler
        (address superNode, address node, address agent, uint64 agentLevel) = IRelationOf(platform).relationOf(player);
        uint256 remain = amount;
        uint256 toSend;
        // the total is 6%
        if (agent != address(0)) {
            if (agentLevel == 1) { // 1.5%
                toSend = amount / 4;
            } else if (agentLevel == 2) { // 2%
                toSend = amount / 3;
            } else if (agentLevel == 3) { // 3%
                toSend = amount / 2;
            }
            remain -= toSend;
            IERC20(FT).transfer(agent, toSend); // TODO 记账，让用户自己来领取
        }

        if (node != address(0)) { // 2%
            toSend = amount / 3;
            remain -= toSend;
            IERC20(FT).transfer(node, toSend); // TODO 记账，让用户自己来领取
        }

        IERC20(FT).transfer(superNode, remain); // TODO 记账，让用户自己来领取
    }

}