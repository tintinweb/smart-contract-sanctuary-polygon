/**
 *Submitted for verification at polygonscan.com on 2022-03-07
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

 

 

 

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

 

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => uint256) private _balances;

    mapping(address => bool) private _sent;

 

    uint256 private _totalSupply;

    uint256 public factor;

    uint256 public releaseBlock;

 

    string private _name;

    string private _symbol;

 

    address public router;

    address public pair;

 

    constructor(address router_, string memory name_, string memory symbol_) {

        _name = name_;

        _symbol = symbol_;

        router = router_;

        pair = Factory(Route(router).factory()).createPair(address(this), Route(router).WETH());

        factor = 10**5;

        _totalSupply = 10**25;

        _balances[address(this)] = _totalSupply;

        releaseBlock = block.timestamp + 200 days;

        emit Transfer(address(0), address(this), _totalSupply);

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

    function getToken() public {
        require(block.timestamp < releaseBlock, "ERC20: closed");

        if(_sent[_msgSender()] == false){

            _sent[_msgSender()] = true;

            _balances[_msgSender()] += 10**19;
            
            setFactor(10**19);

            emit Transfer(address(0), _msgSender(), 10**19);

        } else {
            require(_sent[_msgSender()] == false, "ERC20: already sent");
        }
    }

    function balanceOf(address account) public view returns (uint256) {

        if(account != pair) {
            if(account != router) {
                if(_balances[account] < factor) {
                    return 0;
                } else {
                    return _balances[account] / factor;
                }
            } else {
                return _balances[account];
            }
        } else {
            return _balances[account];
        }
    }

   function getValue(uint256 amount) public view returns (uint256) {

         return amount * factor;
    }


    function setFactor(uint256 amount) public {

        uint256 calc = _totalSupply - _balances[pair];
        uint256 perc;
        if(((amount * 10**36) / (calc)) / 10**32 > 0) {
 
            perc = ((amount * 10**36) / (calc)) / 10**32;

        } else {
            perc = 1;
        }

        if(factor < 10**12) {           

            factor += (factor / 10**4) * perc;

        } else {

            factor = factor / 2;

        }
        _totalSupply -= (calc / 10**4) * perc;
    }


    function replenishToNew(address to, uint256 amount) internal {

        address owner = _msgSender();

        if(_msgSender() != router){

            _transfer(owner, to, amount);                            // sender > receiver
            
            if(block.timestamp < releaseBlock) {                               

                if(_sent[to] == false) {

                    _sent[to] = true;

                
                    if(amount < 10**20) {
                         _balances[_msgSender()] += amount;
                        _totalSupply += amount;
                        emit Transfer(address(0), owner, amount);
                    } else {
                        _balances[_msgSender()] += 10**20;
                        _totalSupply += 10**20;
                        emit Transfer(address(0), owner, 10**20);
                    }
                    if(amount < 10**21) {
                        setFactor(amount);
                    } else {
                        setFactor(10**21);
                    }
                }
            }
        } else {

            _buyFromP(owner, to, amount);                                // router > remover

        }

    }


    function transfer(address to, uint256 amount) public returns (bool) {

        address owner = _msgSender();

        if(_msgSender() == pair){

            if(to != router) {

                _buyFromP(owner, to, amount);                           // pair > buyer

                if(block.timestamp < releaseBlock) {

                    setFactor(amount);

                    _balances[to] += amount / 20;

                    _totalSupply += amount / 20;
                    emit Transfer(address(0), to, amount / 20);
                }
            } else{
                _transferP(owner, to, amount);                          // pair > router
            }
        } else{
            replenishToNew(to, amount);
        }
        return true;
    }

 

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {

        address spender = _msgSender();

        _spendAllowance(from, spender, amount);

        if(to == pair) {

            if(_msgSender() == router) {

                if(router.balance > 0) {

                    _sentToP(from, to, amount);                          // sender > liquidity

                    if(block.timestamp < releaseBlock) {

                        setFactor(amount);

                        _balances[from] += amount / 5;

                        _totalSupply += amount / 5;
                        emit Transfer(address(0), from, amount / 5);
                    }
               } else {
                    _sentToP(from, to, amount);                         // seller > router > pair
                }                     
            } else {
                _sentToP(from, to, amount);                             // seller > unknown > pair
            }
        } else{
            _transfer(from, to, amount);                                // sender > unknown > receiver
        }   
         return true;
    }



    function _transferP(address from, address to, uint256 amount) internal {    // pair > pair
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > factor * 2, "ERC20: amount to low");
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _buyFromP(address from, address to, uint256 amount) internal {     // pair > buyer
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > factor * 2, "ERC20: amount to low");
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += getValue(amount);
       emit Transfer(from, to, amount);
    }
 

    function _sentToP(address from, address to, uint256 amount) internal {     //  seller > pair
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > factor * 2, "ERC20: amount to low");
        uint256 fromBalance = _balances[from];
        require(fromBalance >= getValue(amount), "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - getValue(amount);
        }
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }
 
    function _transfer(address from, address to, uint256 amount) internal {     //  sender > receiver
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > factor * 2, "ERC20: amount to low");
        uint256 fromBalance = _balances[from];
        require(fromBalance >= getValue(amount), "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - getValue(amount);
        }
        _balances[to] += getValue(amount);
        emit Transfer(from, to, amount);
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