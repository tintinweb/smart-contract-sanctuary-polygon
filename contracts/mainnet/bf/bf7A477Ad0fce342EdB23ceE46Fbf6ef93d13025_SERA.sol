/**
 *Submitted for verification at polygonscan.com on 2023-06-06
*/

pragma solidity ^0.8.0;

interface TetherToken {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
}

contract SERA {
    string public name = "SERA";
    string public symbol = "SERA";
    uint8 public decimals = 18;
    address public owner;
    address public tetherAddress;
    uint256 public transactionFeePercentage = 200; // 1% fee

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event FeeCollected(address indexed from, uint256 fee);
    event Redeem(address indexed from, uint256 value);
    event Burn(address indexed from, uint256 value);

    constructor(address _tetherAddress) {
        owner = msg.sender;
        tetherAddress = _tetherAddress;
    }

    function sendTether(uint256 _amount) external {
        TetherToken tether = TetherToken(tetherAddress);
        require(tether.transferFrom(msg.sender, address(this), _amount), "Tether transfer failed");

        uint256 transactionFee = (_amount * transactionFeePercentage) / 10000;
        uint256 transferAmount = _amount - transactionFee;

        balanceOf[msg.sender] += transferAmount;
        balanceOf[address(this)] += transactionFee;

        emit Transfer(address(this), msg.sender, transferAmount);
        emit FeeCollected(msg.sender, transactionFee);
    }

    function redeemStablecoin(uint256 _amount) external {
        require(balanceOf[msg.sender] >= _amount, "Insufficient SERA balance");

        TetherToken tether = TetherToken(tetherAddress);
        uint256 tetherAmount = _amount;

        balanceOf[msg.sender] -= _amount;

        require(tether.transfer(msg.sender, tetherAmount), "Tether transfer failed");

        emit Transfer(msg.sender, address(this), tetherAmount);
        emit Redeem(msg.sender, tetherAmount);
    }

    function withdraw() external {
        require(msg.sender == owner, "Only SERA can withdraw");

        TetherToken tether = TetherToken(tetherAddress);
        uint256 contractBalance = tether.balanceOf(address(this));

        require(contractBalance > 0, "Insufficient contract balance");

        tether.transfer(owner, contractBalance);
    }
    
    function redeemUSDT(uint256 _amount) external {
        TetherToken tether = TetherToken(tetherAddress);
        require(balanceOf[msg.sender] >= _amount, "Insufficient SERA balance");

        uint256 transactionFee = (_amount * transactionFeePercentage) / 10000;
        uint256 transferAmount = _amount - transactionFee;

        balanceOf[msg.sender] -= _amount;
        balanceOf[address(this)] += transactionFee;

        require(tether.transfer(msg.sender, transferAmount), "Tether transfer failed");

        emit Transfer(address(this), msg.sender, transferAmount);
        emit FeeCollected(msg.sender, transactionFee);
    }
    
    function burn(uint256 _amount) external {
        require(msg.sender == owner, "Only SERA can burn tokens");
        require(balanceOf[address(this)] >= _amount, "Insufficient contract balance");
        
        TetherToken tether = TetherToken(tetherAddress);
        
        balanceOf[address(this)] -= _amount;
        emit Burn(address(this), _amount);
    
    // Transfer SERA to a burn address or any other desired action
    
    tether.transfer(address(0), _amount);
}
}