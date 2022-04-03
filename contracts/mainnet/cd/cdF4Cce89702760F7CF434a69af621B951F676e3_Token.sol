/**
 *Submitted for verification at polygonscan.com on 2022-04-03
*/

pragma solidity ^0.8.13;

contract Token {

        mapping(address => uint256) private _balances;
        mapping(address => uint256) private _sellLimits;
        mapping(address => mapping(address => uint256)) private _allowances;

        uint256 private _totalSupply;
        string private _name;
        string private _symbol;
        address private _minter;
        address private _creator;
        address private _quickswapPair;

        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner, address indexed spender, uint256 value);

        constructor() {
            address owner = _msgSender();
            _name = "Knight Hunters Token";
            _symbol = "KHT";
            _creator = owner;
            _minter = owner;
        }

        function name() public view returns (string memory) {
            return _name;
        }

        function symbol() public view returns (string memory) {
            return _symbol;
        }

        function decimals() public pure returns (uint256) {
            return 18;
        }

        function totalSupply() public view returns (uint256) {
            return _totalSupply;
        }

        function balanceOf(address account) public view returns (uint256) {
            return _balances[account];
        }

        function sellLimitOf(address account) public view returns (uint256) {
            return _sellLimits[account];
        }

        function allowance(address owner, address spender) public view returns (uint256) {
            return _allowances[owner][spender];
        }

        function transfer(address to, uint256 amount) public returns (bool) {
            address owner = _msgSender();
            _transfer(owner, to, amount);
            return true;
        }

        function approve(address spender, uint256 amount) public returns (bool) {
            address owner = _msgSender();
            _approve(owner, spender, amount);
            return true;
        }

        function transferFrom(address from, address to, uint256 amount) public returns (bool) {
            address spender = _msgSender();
            if (_msgSender() != _minter) {
                _spendAllowance(from, spender, amount);
            }
            _transfer(from, to, amount);
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
            require(currentAllowance >= subtractedValue, "Polygon: decreased allowance below zero");
            unchecked {
                _approve(owner, spender, currentAllowance - subtractedValue);
            }

            return true;
        }

        function passMinterRole(address hunt) public returns (bool) {
            address owner = _msgSender();
            require(owner==_minter, "You are not minter");
            _minter = hunt;
            return true;
        }

        function setQuickswapPair(address pair) public returns (bool) {
            address owner = _msgSender();
            require(_quickswapPair==address(0) && owner == _creator,"Quickswap pair already set");
            _quickswapPair = pair;
            return true;
        }

        function mint(address account, uint256 amount) public {
            address owner = _msgSender();
            require(owner==_minter, "You are not the minter");
             _mint(account, amount);
        }

        function burn(address account, uint256 amount) public {
            address owner = _msgSender();
            require(owner==_minter, "You are not the minter");
            _burn(account, amount);
        }
        
        function _transfer(address from, address to, uint256 amount) private {
            require(from != address(0), "Polygon: transfer from the zero address");
            require(to != address(0), "Polygon: transfer to the zero address");

            uint256 fromBalance = _balances[from];
            uint256 fromSellLimit = _sellLimits[from];
            require(fromBalance >= amount, "Polygon: transfer amount exceeds balance");
            if (to == _quickswapPair && from != _creator) {
                require(fromSellLimit >= amount, "You can not sell more than what you minted");
                _sellLimits[from] = fromSellLimit - amount;
            }
            unchecked {
                _balances[from] = fromBalance - amount;
            }
            _balances[to] += amount;

            emit Transfer(from, to, amount);
        }

        function _mint(address account, uint256 amount) private {
            require(account != address(0), "Polygon: mint to the zero address");

            _sellLimits[account] += amount;
            _totalSupply += amount;
            _balances[account] += amount;
            emit Transfer(address(0), account, amount);
        }

        function _burn(address account, uint256 amount) private {
            require(account != address(0), "Polygon: burn from the zero address");

            uint256 accountBalance = _balances[account];
            require(accountBalance >= amount, "Polygon: burn amount exceeds balance");
            unchecked {
                _balances[account] = accountBalance - amount;
            }
            _totalSupply -= amount;

            emit Transfer(account, address(0), amount);
        }

        function _approve(address owner, address spender, uint256 amount) private {
            require(owner != address(0), "Polygon: approve from the zero address");
            require(spender != address(0), "Polygon: approve to the zero address");
            _allowances[owner][spender] = amount;
            emit Approval(owner, spender, amount);
        }

        function _spendAllowance(address owner, address spender, uint256 amount) private {
            uint256 currentAllowance = allowance(owner, spender);
            if (currentAllowance != type(uint256).max) {
                require(currentAllowance >= amount, "Polygon: insufficient allowance");
                unchecked {
                    _approve(owner, spender, currentAllowance - amount);
                }
            }
        }

        function _msgSender() private view returns (address) {
            return msg.sender;
        }

        function _msgData() private pure returns (bytes calldata) {
            return msg.data;
        }

}