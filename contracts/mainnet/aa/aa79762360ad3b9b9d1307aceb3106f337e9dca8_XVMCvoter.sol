/**
 *Submitted for verification at polygonscan.com on 2023-03-04
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.1;

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

interface IacPool {
    function deposit(uint256 _amount) external;
    function withdrawAll(uint256 _stakeID) external;
}

interface IProxy {
    function proxyVote(uint256 _forID) external;
}

interface IXVMC {
    function governor() external view returns (address);
}

interface IConsensus {
    function isGovInvalidated(address) external view returns (bool);
}

contract XVMCvoter {
    IacPool public immutable stakingContract = IacPool(0x605c5AA14BdBf0d50a99836e7909C631cf3C8d46);
    IERC20 public immutable xvmc = IERC20(0x970ccEe657Dd831e9C37511Aa3eb5302C1Eb5EEe);
    IProxy public immutable votingProxy = IProxy(0xaB69d8Ce8b5A1b79a0BBc465764c52e5e2edC677);
    IConsensus public immutable consensus = IConsensus(0xDDd4982e3E9e5C5C489321D2143b8a027f535112);
    address public immutable newGovernor = 0xa1740dAeC7C0C1a682A57dD74027C3E7984930D6;

    function deposit() external {
        stakingContract.deposit(xvmc.balanceOf(address(this)));
    }

    function vote() external {
        votingProxy.proxyVote(7);
    }

    function stopVote(uint256 stakeId) external {
        require(getGovernor() == newGovernor || consensus.isGovInvalidated(newGovernor) == true);
        stakingContract.withdrawAll(stakeId);
        xvmc.transfer(getGovernor(), xvmc.balanceOf(address(this)));
    }

    function getGovernor() public view returns (address) {
        return IXVMC(0x970ccEe657Dd831e9C37511Aa3eb5302C1Eb5EEe).governor();
    }
}