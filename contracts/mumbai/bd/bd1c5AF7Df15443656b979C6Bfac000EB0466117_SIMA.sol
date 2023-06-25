/**
 *Submitted for verification at polygonscan.com on 2023-06-24
*/

// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.0;

interface IERC20 {
  
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
  
    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);
 
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
  
}

contract SIMA is IERC20 {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _decimals;
    string private _name;
    string private _symbol;
     
    constructor () {
        _name = "SIMA";
        _symbol ="FEE";
        _totalSupply=8000000000;
        _balances[msg.sender]=_totalSupply;
        _decimals=18;
    }
   
    function name() public view virtual  returns (string memory) {
        return _name;
    }

    function symbol() public view virtual  returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view virtual override  returns (uint256) {
        return _totalSupply;
    }

   
    function balanceOf(address account) public view virtual override  returns (uint256) {
        return _balances[account];
    }

   
    function transfer(address to, uint256 amount) public virtual override  returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

  
    function allowance(address owner, address spender) public view override  returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override  returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override  returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

  
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "BEP20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance.sub(amount);
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to]=_balances[to].add(amount);
        }

        emit Transfer(from, to, amount);

    }

  
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "Insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance.sub(amount));
            }
        }
    }

      
}
library SafeMath {
  

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c=a + b;
        assert(c>=a);
        return c;
    }

   
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert (b<=a);
        return a - b;
    }
   
}