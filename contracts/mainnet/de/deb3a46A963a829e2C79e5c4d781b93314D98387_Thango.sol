pragma solidity ^0.8.0;

contract Thango {
    string public name = "Thango";
    string public symbol = "THGO";
    uint256 public totalSupply = 500000000000 * 10**18; // 500 billion with 18 decimal places
    uint8 public decimals = 18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public nullAddress = address(0);
    address constant  public devTeamAddress = 0xE7Dcd230B5A1647F1F68C0D48Bacf0FA8f184f90;
    uint256 public devTeamAllocation = totalSupply * 5 / 100;
    uint256 public devTeamLockEndTime;

    uint256 public maxTransactionAmount = totalSupply * 1 / 100;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        balanceOf[msg.sender] = totalSupply - devTeamAllocation;
        balanceOf[address(this)] = devTeamAllocation;

    
        devTeamLockEndTime = block.timestamp + 365 days; // 365 days lock time
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(_to != nullAddress, "Cannot transfer to null address");
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        require(_value <= maxTransactionAmount, "Exceeds maximum transaction amount");

        uint256 fee = _value * 5 / 100;
        uint256 transferAmount = _value - fee;

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += transferAmount;
        balanceOf[address(this)] += fee;

        emit Transfer(msg.sender, _to, transferAmount);
        emit Transfer(msg.sender, nullAddress, fee); // send 5% of transaction to null address

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        require(_to != nullAddress, "Cannot transfer to null address");
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance");
        require(_value <= maxTransactionAmount, "Exceeds maximum transaction amount");

        uint256 fee = _value * 5 / 100;
        uint256 transferAmount = _value - fee;

        balanceOf[_from] -= _value;
        balanceOf[_to] += transferAmount;
        balanceOf[address(this)] += fee;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, transferAmount);
        emit Transfer(_from, nullAddress, fee); // send 5% of transaction to null address

        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool success) {
        allowance[msg.sender][_spender] = _value;

        return true;
    }

    function lockDevTeamAllocation() external {
        require(msg.sender == devTeamAddress, "Only dev team can call this function");
        require(block.timestamp >= devTeamLockEndTime, "Dev team allocation is still locked");

        balanceOf[address(this)] -= devTeamAllocation;
        balanceOf[devTeamAddress] += devTeamAllocation;
    }
}