/**
 *Submitted for verification at polygonscan.com on 2023-04-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract MyToken is IERC20 {
    address public owner;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 private totalSupply_;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    mapping(address => bool) private whiteList;
    uint256 private transactionFeeRate;
    uint256 private burnFeeRate;
    address private transactionFeeWallet;
    address private burnFeeWallet;

    event Mint(address indexed _to, uint256 _value);
    event Burn(address indexed _from, uint256 _value);
    event AddedToWhiteList(address indexed _addr);
    event RemovedFromWhiteList(address indexed _addr);
    event TransactionFeeRateUpdated(uint256 _rate);
    event BurnFeeRateUpdated(uint256 _rate);
    event TransactionFeeWalletUpdated(address indexed _wallet);
    event BurnFeeWalletUpdated(address indexed _wallet);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) {
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply_ = _initialSupply * 10**uint256(_decimals);
        balances[msg.sender] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
    }

    function totalSupply() public view override returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address _owner) public view override returns (uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return allowed[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) public override returns (bool) {
        require(_to != address(0), "Invalid recipient");
        require(_value <= balances[msg.sender], "Insufficient balance");

        uint256 transactionFee = (_value * transactionFeeRate) / 1e18;
        uint256 transferAmount = _value - transactionFee;

        balances[msg.sender] -= _value;
        balances[_to] += transferAmount;
        balances[transactionFeeWallet] += transactionFee;

        emit Transfer(msg.sender, _to, transferAmount);

        if (transactionFee > 0) {
            emit Transfer(msg.sender, transactionFeeWallet, transactionFee);
        }

        return true;
    }

    function approve(address _spender, uint256 _value) public override returns (bool) {
        require(_spender != address(0), "Invalid spender");

        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from,
    address _to, uint256 _value) public override returns (bool) {
    require(_to != address(0), "Invalid recipient");
    require(_value <= balances[_from], "Insufficient balance");
    require(_value <= allowed[_from][msg.sender], "Insufficient allowance");
    
    uint256 transactionFee = (_value * transactionFeeRate) / 1e18;
    uint256 transferAmount = _value - transactionFee;

    balances[_from] -= _value;
    balances[_to] += transferAmount;
    balances[transactionFeeWallet] += transactionFee;
    allowed[_from][msg.sender] -= _value;

    emit Transfer(_from, _to, transferAmount);

    if (transactionFee > 0) {
        emit Transfer(_from, transactionFeeWallet, transactionFee);
    }

    return true;
    }

function mint(address _to, uint256 _value) public onlyOwner {
    require(_to != address(0), "Invalid recipient");
    require(_value > 0, "Invalid amount");

    uint256 mintAmount = _value * 10**uint256(decimals);

    totalSupply_ += mintAmount;
    balances[_to] += mintAmount;

    emit Mint(_to, mintAmount);
    emit Transfer(address(0), _to, mintAmount);
}

function burn(uint256 _value) public {
    require(_value <= balances[msg.sender], "Insufficient balance");
    require(burnFeeRate > 0, "Burn fee rate not set");

    uint256 burnAmount = (_value * burnFeeRate) / 1e18;
    uint256 transferAmount = _value - burnAmount;

    balances[msg.sender] -= _value;
    totalSupply_ -= burnAmount;

    emit Burn(msg.sender, burnAmount);
    emit Transfer(msg.sender, address(0), burnAmount);

    balances[transactionFeeWallet] += burnAmount;
    balances[msg.sender] += transferAmount;

    emit Transfer(msg.sender, transactionFeeWallet, burnAmount);
    emit Transfer(msg.sender, msg.sender, transferAmount);
    }

function addToWhiteList(address _addr) public onlyOwner {
    require(!whiteList[_addr], "Address already in white list");

    whiteList[_addr] = true;
    emit AddedToWhiteList(_addr);
}

function removeFromWhiteList(address _addr) public onlyOwner {
    require(whiteList[_addr], "Address not found in white list");

    whiteList[_addr] = false;
    emit RemovedFromWhiteList(_addr);
}

function updateTransactionFeeRate(uint256 _rate) public onlyOwner {
    require(_rate <= 1e18, "Invalid rate");

    transactionFeeRate = _rate;
    emit TransactionFeeRateUpdated(_rate);
}

function updateBurnFeeRate(uint256 _rate) public onlyOwner {
    require(_rate <= 1e18, "Invalid rate");

    burnFeeRate = _rate;
    emit BurnFeeRateUpdated(_rate);
}

function updateTransactionFeeWallet(address _wallet) public onlyOwner {
    require(_wallet != address(0), "Invalid wallet");

    transactionFeeWallet = _wallet;
    emit TransactionFeeWalletUpdated(_wallet);
}

function updateBurnFeeWallet(address _wallet) public onlyOwner {
    require(_wallet != address(0), "Invalid wallet");

    burnFeeWallet = _wallet;
    emit BurnFeeWalletUpdated(_wallet);
}

modifier onlyOwner() {
    require(msg.sender == owner, "Caller is not the owner");
    _;
}
}