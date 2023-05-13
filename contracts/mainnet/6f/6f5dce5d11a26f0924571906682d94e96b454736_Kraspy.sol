/**
 *Submitted for verification at polygonscan.com on 2023-05-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

/**
 * @title Kraspy
 * @dev Very ERC20 Token, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 * USE IT ONLY FOR LEARNING PURPOSES. SHOULD BE MODIFIED FOR PRODUCTION
 */

contract Kraspy {
    string public name = "Kraspy Token";
    string public symbol = "Kraspy";
    uint256 public totalSupply = 20000000000000000000000000000000000;
    uint8 public decimals = 18;
    uint256 public constant STAKING_DAYS = 365;
    uint256 public constant STAKING_MULTIPLIER = 2;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /**
     * @dev Emitted when tokens are burned.
     */
    event Burn(address indexed _burner, uint256 _value);

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

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
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Allowance exceeded");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Stake `amount` tokens for `STAKING_DAYS` days to receive `STAKING_MULTIPLIER` times the amount as dividend.
     *
     * Emits a {Transfer} event.
     */
    function stake(uint256 _amount) public returns (bool success) {
        require(balanceOf[msg.sender] >= _amount, "Insufficient balance");
        balanceOf[msg.sender] -= _amount;

        uint256 dividend = (_amount * STAKING_MULTIPLIER) / 100;
        uint256 stakingEndTime = block.timestamp + (STAKING_DAYS * 1 days);
        // Create a new staking contract and transfer the staked amount to it
        StakingContract newStakingContract = new StakingContract(msg.sender, _amount, dividend, stakingEndTime);
        balanceOf[address(newStakingContract)] = _amount;
        emit Transfer(msg.sender, address(newStakingContract), _amount);
        return true;
    }

    /**
     * @dev Burns `amount` tokens from the caller's account.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Burn} event.
     */
    function burn(uint256 _amount) public returns (bool success) {
        require(balanceOf[msg.sender] >= _amount, "Insufficient balance");
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        emit Burn(msg.sender, _amount);
        return true;
    }
}

/**
 * @title StakingContract
 * @dev A staking contract that holds staked tokens and returns the staker's dividend after the staking period.
 */
contract StakingContract {
    address public staker;
    uint256 public stakedAmount;
    uint256 public dividend;
    uint256 public stakingEndTime;
    bool public claimed;

    constructor(address _staker, uint256 _stakedAmount, uint256 _dividend, uint256 _stakingEndTime) {
        staker = _staker;
        stakedAmount = _stakedAmount;
        dividend = _dividend;
        stakingEndTime = _stakingEndTime;
        claimed = false;
    }

    /**
     * @dev Claim the staker's dividend if the staking period has ended.
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function claimDividend() public returns (bool success) {
        require(block.timestamp >= stakingEndTime, "Staking period not over yet");
        require(msg.sender == staker, "Only the staker can claim the dividend");
        require(!claimed, "Dividend already claimed");

        claimed = true;
        Kraspy kraspy = Kraspy(msg.sender);
        kraspy.transfer(staker, dividend);
        return true;
    }
}