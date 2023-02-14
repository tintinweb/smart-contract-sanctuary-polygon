/**
 *Submitted for verification at polygonscan.com on 2023-02-13
*/

pragma solidity ^0.8.0;

interface Token {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract DarkxFlip {

    address payable public owner;
    address payable public feeWallet;
    mapping (address => bool) public whitelist;
    uint256 public feePercentage;
    Token public token;

    event DarkxFlipResult(bool result);

    mapping (address => uint256) public userFlips;
    mapping (address => uint256) public userWins;
    mapping (address => uint256) public userAmount;
    mapping (address => uint256) public balances;

    constructor() public {
        owner = payable(msg.sender);
    }

    function setFeeWallet(address payable _feeWallet, uint256 _feePercentage) public {
        require(msg.sender == owner, "Only the owner can set the fee wallet.");
        require(_feePercentage <= 5, "The fee percentage must be less than or equal to 5.");
        feeWallet = _feeWallet;
        feePercentage = _feePercentage;
    }

    function addToWhitelist(address _tokenAddress) public {
        require(msg.sender == owner, "Only the owner can add tokens to the whitelist.");
        whitelist[_tokenAddress] = true;
    }

    function removeFromWhitelist(address _tokenAddress) public {
        require(msg.sender == owner, "Only the owner can remove tokens from the whitelist.");
        whitelist[_tokenAddress] = false;
    }

    function balance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function flip(address _tokenAddress, uint256 _value, uint256 _choice) public payable {
        require(whitelist[_tokenAddress], "The specified token is not in the whitelist.");
        require(_value > 0, "You must send a positive amount of tokens to flip the coin.");
        require(_choice <= 1, "Choice must be either 0 or 1.");

        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)));

        Token t = Token(_tokenAddress);
        require(t.transferFrom(msg.sender, address(this), _value), "Transfer of tokens failed.");

        uint256 fee = (_value * feePercentage) / 100;
        uint256 amount = _value - fee;
        userFlips[msg.sender]++;

        if (random % 2 == _choice) 
        {
            require(t.balanceOf(address(this)) >= amount * 2, "The contract does not have enough tokens to send back.");
            require(t.transfer(msg.sender, amount * 2), "Transfer of tokens failed.");
            emit DarkxFlipResult(true);
            userWins[msg.sender]++;
            userAmount[msg.sender] += amount * 2;
        } 
        else 
        {
            emit DarkxFlipResult(false);
        }
        require(t.transfer(feeWallet, fee), "Transfer of fee failed.");
    }

    function withdraw(address tokenAddress, uint256 amount) public {
        Token b = Token(tokenAddress);
        require(b.balanceOf(address(this)) >= amount, "Insufficient balance");
        b.transfer(msg.sender, amount);
        // balances[msg.sender] = balances[msg.sender].sub(amount);
    }
}