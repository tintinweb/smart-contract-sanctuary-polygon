/**
 *Submitted for verification at polygonscan.com on 2023-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract USDCToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address owner;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor(
        uint256 _initialSupply
    ) {
        name = "USDCToken";
        symbol = "USDC";
        decimals = 18;
        totalSupply = _initialSupply * 10 ** decimals;
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    modifier onlyOwner() {
        require(msg.sender == owner,"owner can call");
        _;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, allowances[sender][msg.sender] - amount);
        return true;
    }

    function allowance(
        address _owner,
        address spender
    ) public view returns (uint256) {
        return allowances[_owner][spender];
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");
        require(balances[sender] >= amount, "ERC20: insufficient balance");
        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address _owner, address spender, uint256 amount) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        amount = amount * 10 ** decimals;
        allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }
    function mint(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "ERC20: mint to the zero address");
        _update(address(0), account, amount);
    }
    function burn(address account, uint256 amount) public {
        require(account != address(0), "ERC20: burn from the zero address");
        _update(account, address(0), amount);
    }
    function _update(address from, address to, uint256 amount) internal virtual {
        if (from == address(0)) {
            totalSupply += amount;
        } else {
            uint256 fromBalance = balances[from];
            require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
            unchecked {
                // Overflow not possible: amount <= fromBalance <= totalSupply.
                balances[from] = fromBalance - amount;
            }
        }
        if (to == address(0)) {
            unchecked {
                // Overflow not possible: amount <= totalSupply or amount <= fromBalance <= totalSupply.
                totalSupply -= amount;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + amount is at most totalSupply, which we know fits into a uint256.
                balances[to] += amount;
            }
        }
        emit Transfer(from, to, amount);
    }
}