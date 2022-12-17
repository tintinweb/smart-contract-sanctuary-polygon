/**
 *Submitted for verification at polygonscan.com on 2022-12-17
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/[email protected]/token/ERC20/IERC20.sol


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

// File: Vesting.sol


pragma solidity ^0.8.9;


contract Vesting {
    IERC20 public token;
    address public receiver;
    uint256 public amount;
    uint256 public expiry;
    uint256 public expiry2;
    uint256 public expiry3;
    uint256 public expiry4;
    uint256 public expiry5;
    uint256 public expiry6;
    uint256 public expiry7;
    uint256 public expiry8;
    uint256 public expiry9;
    uint256 public expiry10;
    bool public locked = false;
    bool public locked2 = false;
    bool public locked3 = false;
    bool public locked4 = false;
    bool public locked5 = false;
    bool public locked6 = false;
    bool public locked7 = false;
    bool public locked8 = false;
    bool public locked9 = false;
    bool public locked10 = false;
    bool public claimed = false;
    bool public claimed2 = false;
    bool public claimed3 = false;
    bool public claimed4 = false;
    bool public claimed5 = false;
    bool public claimed6 = false;
    bool public claimed7 = false;
    bool public claimed8 = false;
    bool public claimed9 = false;
    bool public claimed10 = false;

    constructor (address _token) {
        token = IERC20(_token);
    }

    function lock(address _from, address _receiver, uint256 _amount, uint256 _expiry) external {
        require(!locked, "We have already locked tokens.");
        token.transferFrom(_from, address(this), _amount);
        receiver = _receiver;
        amount = _amount;
        expiry = _expiry;
        locked = true;
    }
    function lock2(address _from, address _receiver, uint256 _amount, uint256 _expiry2) external {
        require(!locked2, "We have already locked tokens.");
        token.transferFrom(_from, address(this), _amount);
        receiver = _receiver;
        amount = _amount;
        expiry2 = _expiry2;
        locked2 = true;
    }
    function lock3(address _from, address _receiver, uint256 _amount, uint256 _expiry3) external {
        require(!locked3, "We have already locked tokens.");
        token.transferFrom(_from, address(this), _amount);
        receiver = _receiver;
        amount = _amount;
        expiry3 = _expiry3;
        locked3 = true;
    }   
    function lock4(address _from, address _receiver, uint256 _amount, uint256 _expiry4) external {
        require(!locked4, "We have already locked tokens.");
        token.transferFrom(_from, address(this), _amount);
        receiver = _receiver;
        amount = _amount;
        expiry4 = _expiry4;
        locked4 = true;
    }    
    function lock5(address _from, address _receiver, uint256 _amount, uint256 _expiry5) external {
        require(!locked5, "We have already locked tokens.");
        token.transferFrom(_from, address(this), _amount);
        receiver = _receiver;
        amount = _amount;
        expiry5 = _expiry5;
        locked5 = true;
    }    
    function lock6(address _from, address _receiver, uint256 _amount, uint256 _expiry6) external {
        require(!locked6, "We have already locked tokens.");
        token.transferFrom(_from, address(this), _amount);
        receiver = _receiver;
        amount = _amount;
        expiry6 = _expiry6;
        locked6 = true;
    }    
    function lock7(address _from, address _receiver, uint256 _amount, uint256 _expiry7) external {
        require(!locked7, "We have already locked tokens.");
        token.transferFrom(_from, address(this), _amount);
        receiver = _receiver;
        amount = _amount;
        expiry7 = _expiry7;
        locked7 = true;
    }    
    function lock8(address _from, address _receiver, uint256 _amount, uint256 _expiry8) external {
        require(!locked8, "We have already locked tokens.");
        token.transferFrom(_from, address(this), _amount);
        receiver = _receiver;
        amount = _amount;
        expiry8 = _expiry8;
        locked8 = true;
    }    
    function lock9(address _from, address _receiver, uint256 _amount, uint256 _expiry9) external {
        require(!locked9, "We have already locked tokens.");
        token.transferFrom(_from, address(this), _amount);
        receiver = _receiver;
        amount = _amount;
        expiry9 = _expiry9;
        locked9 = true;
    }    
    function lock10(address _from, address _receiver, uint256 _amount, uint256 _expiry10) external {
        require(!locked10, "We have already locked tokens.");
        token.transferFrom(_from, address(this), _amount);
        receiver = _receiver;
        amount = _amount;
        expiry10 = _expiry10;
        locked10 = true;
    }

    function withdraw() external {
        require(locked, "Funds have not been locked");
        require(block.timestamp > expiry, "Tokens have not been unlocked");
        require(!claimed, "Tokens have already been claimed");
        claimed = true;
        token.transfer(receiver, amount);
    }
    function withdraw2() external {
        require(locked2, "Funds have not been locked");
        require(block.timestamp > expiry2, "Tokens have not been unlocked");
        require(!claimed2, "Tokens have already been claimed");
        claimed2 = true;
        token.transfer(receiver, amount);
    }
    function withdraw3() external {
        require(locked3, "Funds have not been locked");
        require(block.timestamp > expiry3, "Tokens have not been unlocked");
        require(!claimed3, "Tokens have already been claimed");
        claimed3 = true;
        token.transfer(receiver, amount);
    }
    function withdraw4() external {
        require(locked4, "Funds have not been locked");
        require(block.timestamp > expiry4, "Tokens have not been unlocked");
        require(!claimed4, "Tokens have already been claimed");
        claimed4 = true;
        token.transfer(receiver, amount);
    }
    function withdraw5() external {
        require(locked5, "Funds have not been locked");
        require(block.timestamp > expiry5, "Tokens have not been unlocked");
        require(!claimed5, "Tokens have already been claimed");
        claimed5 = true;
        token.transfer(receiver, amount);
    }
    function withdraw6() external {
        require(locked6, "Funds have not been locked");
        require(block.timestamp > expiry6, "Tokens have not been unlocked");
        require(!claimed6, "Tokens have already been claimed");
        claimed6 = true;
        token.transfer(receiver, amount);
    }
    function withdraw7() external {
        require(locked7, "Funds have not been locked");
        require(block.timestamp > expiry7, "Tokens have not been unlocked");
        require(!claimed7, "Tokens have already been claimed");
        claimed7 = true;
        token.transfer(receiver, amount);
    }
    function withdraw8() external {
        require(locked8, "Funds have not been locked");
        require(block.timestamp > expiry8, "Tokens have not been unlocked");
        require(!claimed8, "Tokens have already been claimed");
        claimed8 = true;
        token.transfer(receiver, amount);
    }
    function withdraw9() external {
        require(locked9, "Funds have not been locked");
        require(block.timestamp > expiry9, "Tokens have not been unlocked");
        require(!claimed9, "Tokens have already been claimed");
        claimed9 = true;
        token.transfer(receiver, amount);
    }
    function withdraw10() external {
        require(locked10, "Funds have not been locked");
        require(block.timestamp > expiry10, "Tokens have not been unlocked");
        require(!claimed10, "Tokens have already been claimed");
        claimed10 = true;
        token.transfer(receiver, amount);
    }
    

    function getTime() external view returns (uint256) {
        return block.timestamp;
    }
}