/**
 *Submitted for verification at polygonscan.com on 2023-08-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;
    bool public paused;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public isBlacklisted;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Airdrop(address indexed from, address indexed to, uint256 value);
    event StakeWithdraw(address indexed from, uint256 value);
    event StakeRewardClaimed(address indexed to, uint256 value);
    event Blacklisted(address indexed account);
    event Unblacklisted(address indexed account);
    event EthWrapped(address indexed from, uint256 value);
    event EthUnwrapped(address indexed from, uint256 value);
    event RandomTokenMint(address indexed to, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
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
        uint256 _initialSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply * 10**uint256(_decimals);
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        paused = false;
    }

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool success) {
        require(_to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool success) {
        require(_spender != address(0), "Invalid address");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool success) {
        require(_from != address(0), "Invalid 'from' address");
        require(_to != address(0), "Invalid 'to' address");
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Allowance exceeded");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) public whenNotPaused {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
    }

    function mint(address _to, uint256 _value) public onlyOwner whenNotPaused {
        require(_to != address(0), "Invalid address");
        totalSupply += _value;
        balanceOf[_to] += _value;
        emit Transfer(address(0), _to, _value);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    function pause() public onlyOwner {
        paused = true;
    }

    function unpause() public onlyOwner {
        paused = false;
    }

    function withdrawFromStake(uint256 _value) public whenNotPaused {
        // Implement your stake withdrawal logic here
        // This function should be used to withdraw tokens from a staking contract
        // based on the user's staked balance (_value).
        // For simplicity, I'm not including the staking contract logic in this example.
        // Emit an event like "StakeWithdraw" to indicate the successful withdrawal.
        emit StakeWithdraw(msg.sender, _value);
    }

    function claimStakeReward() public whenNotPaused {
        // Implement your staking reward claim logic here
        // This function should be used to claim staking rewards.
        // For simplicity, I'm not including the staking contract logic in this example.
        // Emit an event like "StakeRewardClaimed" to indicate the successful reward claim.
        emit StakeRewardClaimed(msg.sender, 0);
    }

    function withdrawAll() public onlyOwner whenNotPaused {
        // Implement your contract balance withdrawal logic here
        // This function should allow the owner to withdraw the entire contract balance to their address.
        // Emit an event like "Transfer" to indicate the successful transfer of tokens to the owner.
        emit Transfer(address(this), owner, totalSupply);
    }

    function blacklistAccount(address _account) public onlyOwner {
        require(_account != address(0), "Invalid address");
        isBlacklisted[_account] = true;
        emit Blacklisted(_account);
    }

    function unblacklistAccount(address _account) public onlyOwner {
        require(_account != address(0), "Invalid address");
        isBlacklisted[_account] = false;
        emit Unblacklisted(_account);
    }

    function wrapEth() public payable whenNotPaused {
        require(msg.value > 0, "No Ether sent");
        balanceOf[msg.sender] += msg.value;
        emit EthWrapped(msg.sender, msg.value);
    }

    function unwrapEth(uint256 _value) public whenNotPaused {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        balanceOf[msg.sender] -= _value;
        payable(msg.sender).transfer(_value);
        emit EthUnwrapped(msg.sender, _value);
    }

    function randomTokenMint(address _to) public onlyOwner whenNotPaused {
        uint256 randomAmount = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _to))) % 100;
        totalSupply += randomAmount;
        balanceOf[_to] += randomAmount;
        emit RandomTokenMint(_to, randomAmount);
    }
}