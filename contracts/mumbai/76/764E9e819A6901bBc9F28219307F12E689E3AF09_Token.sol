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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IERC20.sol";

/**
 *  Exercise: [1] Write a smart contract that implements the ERC-20 standard.
 *            [2] Create a file `src/test/Token.t.sol` and write test cases for your ERC-20 smart contract.
 *                Look at the test case for exercise-1 as reference.
 *                
**/

contract Token is IERC20 {
    
    string public _name;
    string public _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    uint256 private _availableSupply;
    address public _supplyAddress;
    mapping (address => uint256) private _balances ;
    mapping (address => mapping(address => uint256)) private _allowances;
    
    constructor() {
        _name = "MyToken";
        _symbol = "MTT";
        _decimals = 18;
        _totalSupply = 1000 ether;
        _availableSupply = _totalSupply;
        _supplyAddress = msg.sender;
        _balances[_supplyAddress] = _availableSupply;
    }

    function fund(address to, uint256 amount) external returns (bool){
        require(_totalSupply >= amount, "Not enough Token supply");
        _availableSupply -= amount;
        _balances[_supplyAddress] -= amount;
        
        assert(_balances[_supplyAddress] == _availableSupply);
        

        _balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function availableSupply() external view returns(uint256) {
        return _availableSupply;
    }

    function totalSupply() external view returns (uint256){
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256){
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external returns (bool){
        // require(to != address(0), "Invalid recipient address");
        require(_balances[msg.sender] >= amount, "Insufficient funds");
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256){
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool){
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        address spender = msg.sender;

        if(from != spender) {
            require(_allowances[from][spender] >= amount, "Not enough allowance");
            _allowances[from][spender] -= amount;
        }
        _transfer(from, to, amount);    
        return true;
    }

    function _transfer(address _from, address _to, uint256 _amount) internal {
        require(_balances[_from] >= _amount, "Not enough balance");

        _balances[_from] -= _amount;
        _balances[_to] += _amount;

        emit Transfer(_from, _to, _amount); 
    }



    // function transferFrom(address from, address to, uint256 amount) external returns (bool){
    //     address spender = msg.sender;
    //     require(_allowances[from][spender] >= amount, "Not enough allowance");
    //     require(_balances[from] >= amount, "Not enough balance");
    //     _balances[from] -= amount;
    //     _balances[to] += amount;
    //     _allowances[from][spender] -= amount;
    //     emit Transfer(from, to, amount);       
    //     return true;
    // }
}