/**
 *Submitted for verification at polygonscan.com on 2023-06-04
*/

pragma solidity ^0.8.0;

contract MyToken {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _lastMintingTime;
    
    address private _owner;
    uint256 private _maxSupply;
    uint256 private _mintingStartTime;
    uint256 private _mintingEndTime;
    uint256 private _mintingPerDay;
    uint256 private _creatorShare;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the owner can call this function");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_,
        uint256 maxSupply_,
        uint256 mintingStartTime_,
        uint256 mintingEndTime_,
        uint256 mintingPerDay_,
        uint256 creatorShare_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * 10**uint256(decimals_);
        _maxSupply = maxSupply_ * 10**uint256(decimals_);
        _mintingStartTime = mintingStartTime_;
        _mintingEndTime = mintingEndTime_;
        _mintingPerDay = mintingPerDay_ * 10**uint256(decimals_);
        _creatorShare = creatorShare_ * 10**uint256(decimals_);
        _owner = msg.sender;

        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
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

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function mintTokens() public {
        require(block.timestamp >= _mintingStartTime, "Minting has not started yet");
        require(block.timestamp <= _mintingEndTime, "Minting has ended");
        require(_balances[_owner] >= _mintingPerDay, "Insufficient balance");
        require(block.timestamp >= _lastMintingTime[msg.sender] + 1 days, "You can only mint once per day");

        _balances[_owner] -= _mintingPerDay;
        _balances[msg.sender] += _mintingPerDay;
        _lastMintingTime[msg.sender] = block.timestamp;
        emit Transfer(_owner, msg.sender, _mintingPerDay);
    }

    function isMintingActive() public view returns (bool) {
        return block.timestamp >= _mintingStartTime && block.timestamp <= _mintingEndTime;
    }

    function remainingSupply() public view returns (uint256) {
        if (block.timestamp >= _mintingEndTime) {
            return 0;
        } else {
            uint256 elapsedTime = block.timestamp - _mintingStartTime;
            uint256 remainingTime = _mintingEndTime - block.timestamp;
            uint256 remainingSupply = _maxSupply - _totalSupply;
            return elapsedTime * _mintingPerDay + remainingTime * _mintingPerDay <= remainingSupply ? elapsedTime * _mintingPerDay + remainingTime * _mintingPerDay : remainingSupply;
        }
    }

    function creatorShare() public view returns (uint256) {
        return _creatorShare;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= _balances[sender], "ERC20: transfer amount exceeds balance");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}