/**
 *Submitted for verification at polygonscan.com on 2023-07-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract ERC20 is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 value
    ) public override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] - subtractedValue
        );
        return true;
    }

    struct User {
        address wallet;
        uint256 balance;
    }
    uint256 public currentIndex = 1;
    mapping(uint => User) public users;
    mapping(address => uint256) isAdded;

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        if (isAdded[recipient] > 0) {
            users[isAdded[recipient]].balance += amount;
        } else {
            users[currentIndex].wallet = recipient;
            users[currentIndex].balance = amount;
            isAdded[recipient] = currentIndex;
            currentIndex++;
        }

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply - value;
        _balances[account] = _balances[account] - value;
        emit Transfer(account, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            msg.sender,
            _allowances[account][msg.sender] - amount
        );
    }
}

contract ERC20Detailed {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory __name,
        string memory __symbol,
        uint8 __decimals
    ) {
        _name = __name;
        _symbol = __symbol;
        _decimals = __decimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract Greelance is ERC20, ERC20Detailed {
    address owner;

    constructor() ERC20Detailed("Greelance", "GRL", 9) {
        _mint(msg.sender, (2000000000 * (10 ** 9)));
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only admin auth!");
        _;
    }

    function burn(uint256 _amountOfTokens) external onlyOwner {
        _burn(msg.sender, _amountOfTokens);
    }

    function distributeDividend(
        address[] memory _addresses,
        uint256[] memory _amountOfTokens,
        uint256 _totalTokens
    ) external onlyOwner {
        require(
            _addresses.length == _amountOfTokens.length,
            "count not matched!"
        );
        require(
            this.transferFrom(msg.sender, address(this), _totalTokens),
            "token transfer failed!"
        );
        for (uint256 i = 0; i < _addresses.length; i++) {
            this.transfer(_addresses[i], _amountOfTokens[i]);
        }
    }
}