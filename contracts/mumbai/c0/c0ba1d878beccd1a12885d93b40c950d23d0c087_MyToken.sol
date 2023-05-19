/**
 *Submitted for verification at polygonscan.com on 2023-05-18
*/

pragma solidity ^0.8.0;

contract MyToken {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
    uint256 public tokenValue;
    uint256 public ownerFee;
    address public owner;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    constructor() {
        name = "Peaker PKR";
        symbol = "PKR";
        decimals = 18;
        totalSupply = 100000000000000000000;  // Total supply of 100 tokens with 18 decimals
        balanceOf[msg.sender] = totalSupply;
        tokenValue = 0.0001 ether;  // Value of each token in ETH (0.0001 ETH)
        ownerFee = 1;  // 1% fee to be sent to the contract owner on each token purchase
        owner = 0x2C1719A77EabCe1E44C553402ee2B749426316D6;  // Set the contract owner address
    }

    function transfer(address to, uint256 value) public {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        uint256 feeAmount = (value * ownerFee) / 100;  // Calculate the fee amount
        uint256 transferAmount = value - feeAmount;  // Calculate the transfer amount
        
        balanceOf[msg.sender] -= value;
        balanceOf[to] += transferAmount;
        balanceOf[owner] += feeAmount;  // Send the fee to the contract owner
        
        emit Transfer(msg.sender, to, transferAmount);
        emit Transfer(msg.sender, owner, feeAmount);
        emit Burn(msg.sender, feeAmount);
    }

    function buyTokens(uint256 amount) public payable {
        require(amount > 0, "Insufficient amount");  // Ensure at least one token is bought

        uint256 purchaseValue = amount * tokenValue;  // Calculate the ETH value to be paid
        
        uint256 feeAmount = (amount * ownerFee) / 100;  // Calculate the fee amount
        uint256 purchaseAmount = amount - feeAmount;  // Calculate the amount of tokens to be purchased
        
        require(balanceOf[address(this)] >= amount, "Contract does not have enough tokens");
        require(msg.value >= purchaseValue, "Insufficient ETH amount");

        balanceOf[address(this)] -= amount;
        balanceOf[msg.sender] += purchaseAmount;
        balanceOf[owner] += feeAmount;  // Send the fee to the contract owner
        
        emit Transfer(address(this), msg.sender, purchaseAmount);
        emit Transfer(address(this), owner, feeAmount);
        emit Burn(address(this), feeAmount);
        
        if (msg.value > purchaseValue) {
            uint256 refund = msg.value - purchaseValue;
            (bool success, ) = msg.sender.call{value: refund}("");
            require(success, "ETH refund failed");
        }
    }

    function multiSender(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Mismatched input lengths");

        uint256 totalAmount = 0;

        for (uint256 i = 0; i < recipients.length; i++) {
            totalAmount += amounts[i];
        }

        require(totalAmount <= balanceOf[address(this)], "Contract does not have enough tokens");

        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 amount = amounts[i];

            balanceOf[address(this)] -= amount;
            balanceOf[recipient] += amount;
            emit Transfer(address(this), recipient, amount);
        }
    }

    function withdrawEther() public {
        uint256 tokenBalance = balanceOf[msg.sender];
        require(tokenBalance > 0, "No tokens to withdraw");  // Ensure the sender has some tokens
        
        uint256 amount = tokenBalance * tokenValue;  // Calculate the ETH amount to withdraw
        
        balanceOf[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "ETH transfer failed");
    }

    function getChainId() public view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
    
    function mint(address to, uint256 value) public onlyOwner {
        totalSupply += value;
        balanceOf[to] += value;
        emit Mint(to, value);
        emit Transfer(address(0), to, value);
    }
    
    function burn(uint256 value) public onlyOwner {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        totalSupply -= value;
        balanceOf[msg.sender] -= value;
        emit Burn(msg.sender, value);
        emit Transfer(msg.sender, address(0), value);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }
}