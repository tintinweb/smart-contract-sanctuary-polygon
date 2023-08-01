/**
 *Submitted for verification at polygonscan.com on 2023-07-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract YourToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;
    address public admin;
    uint256 public taxFee;
    bool public paused;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public isBlacklisted;
    mapping(address => uint256) public stakedBalance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Mint(address indexed to, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused();
    event Unpaused();
    event Blacklisted(address indexed account);
    event Unblacklisted(address indexed account);
    event EthWrapped(address indexed account, uint256 amount);
    event EthUnwrapped(address indexed account, uint256 amount);
    event RandomTokenMinted(address indexed account, uint256 amount);
    event TaxFeeSet(uint256 taxFee);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply,
        address _admin,
        uint256 _taxFee
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply * 10**uint256(_decimals);
        owner = msg.sender;
        admin = _admin;
        taxFee = _taxFee;
        paused = false;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) external whenNotPaused returns (bool) {
        require(_to != address(0), "Invalid address");
        require(_value <= balanceOf[msg.sender], "Insufficient balance");
        uint256 fee = (_value * taxFee) / 100;
        uint256 valueAfterFee = _value - fee;

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += valueAfterFee;
        balanceOf[admin] += fee;

        emit Transfer(msg.sender, _to, valueAfterFee);
        emit Transfer(msg.sender, admin, fee);

        return true;
    }

    function approve(address _spender, uint256 _value) external whenNotPaused returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external whenNotPaused returns (bool) {
        require(_from != address(0), "Invalid address");
        require(_to != address(0), "Invalid address");
        require(_value <= balanceOf[_from], "Insufficient balance");
        require(_value <= allowance[_from][msg.sender], "Allowance exceeded");
        uint256 fee = (_value * taxFee) / 100;
        uint256 valueAfterFee = _value - fee;

        balanceOf[_from] -= _value;
        balanceOf[_to] += valueAfterFee;
        balanceOf[admin] += fee;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, valueAfterFee);
        emit Transfer(_from, admin, fee);

        return true;
    }

    function burn(uint256 _value) external whenNotPaused returns (bool) {
        require(_value <= balanceOf[msg.sender], "Insufficient balance");

        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;

        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);

        return true;
    }

    function mint(address _to, uint256 _value) external onlyOwner whenNotPaused returns (bool) {
        require(_to != address(0), "Invalid address");
        totalSupply += _value;
        balanceOf[_to] += _value;

        emit Mint(_to, _value);
        emit Transfer(address(0), _to, _value);

        return true;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    function pause() external onlyOwner {
        paused = true;
        emit Paused();
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused();
    }

    function stake(uint256 _amount) external whenNotPaused returns (bool) {
        require(_amount > 0, "Invalid amount");
        require(_amount <= balanceOf[msg.sender], "Insufficient balance");

        balanceOf[msg.sender] -= _amount;
        stakedBalance[msg.sender] += _amount;

        emit Transfer(msg.sender, address(this), _amount);

        return true;
    }

    function stakeWithPercentage(uint256 _percentage) external whenNotPaused returns (bool) {
        require(_percentage >= 0 && _percentage <= 100, "Invalid percentage");
        uint256 amountToStake = (balanceOf[msg.sender] * _percentage) / 100;

        require(amountToStake > 0, "Stake amount must be greater than zero");
        require(amountToStake <= balanceOf[msg.sender], "Insufficient balance");

        balanceOf[msg.sender] -= amountToStake;
        stakedBalance[msg.sender] += amountToStake;

        emit Transfer(msg.sender, address(this), amountToStake);

        return true;
    }

    function withdrawFromStake(uint256 _amount) external whenNotPaused returns (bool) {
        require(_amount > 0, "Invalid amount");
        require(_amount <= stakedBalance[msg.sender], "Insufficient staked balance");

        balanceOf[msg.sender] += _amount;
        stakedBalance[msg.sender] -= _amount;

        emit Transfer(address(this), msg.sender, _amount);

        return true;
    }

    function claimStakeReward() external whenNotPaused returns (bool) {
        // Implementation of claiming stake rewards goes here
        return true;
    }

    function withdrawAll() external whenNotPaused returns (bool) {
        require(stakedBalance[msg.sender] > 0, "No staked balance to withdraw");

        uint256 amountToWithdraw = stakedBalance[msg.sender];
        balanceOf[msg.sender] += amountToWithdraw;
        stakedBalance[msg.sender] = 0;

        emit Transfer(address(this), msg.sender, amountToWithdraw);

        return true;
    }

    function blacklistAccount(address _account) external onlyOwner {
        require(_account != address(0), "Invalid address");
        isBlacklisted[_account] = true;
        emit Blacklisted(_account);
    }

    function unblacklistAccount(address _account) external onlyOwner {
        require(_account != address(0), "Invalid address");
        isBlacklisted[_account] = false;
        emit Unblacklisted(_account);
    }

    function wrapEth() external payable whenNotPaused {
        // Implementation of wrapping ETH into tokens goes here
        emit EthWrapped(msg.sender, msg.value);
    }

    function unwrapEth(uint256 _amount) external whenNotPaused {
        // Implementation of unwrapping tokens to ETH goes here
        emit EthUnwrapped(msg.sender, _amount);
    }

    function randomTokenMint(address _account, uint256 _minAmount, uint256 _maxAmount) external onlyOwner whenNotPaused returns (bool) {
        require(_account != address(0), "Invalid address");
        require(_minAmount > 0, "Minimum amount must be greater than zero");
        require(_maxAmount >= _minAmount, "Max amount must be greater than or equal to the min amount");

        uint256 amountToMint = _minAmount + (uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _account))) % (_maxAmount - _minAmount + 1));

        totalSupply += amountToMint;
        balanceOf[_account] += amountToMint;

        emit Mint(_account, amountToMint);
        emit Transfer(address(0), _account, amountToMint);

        return true;
    }

    function setTaxFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Invalid fee percentage");
        taxFee = _feePercentage;
        emit TaxFeeSet(_feePercentage);
    }
}