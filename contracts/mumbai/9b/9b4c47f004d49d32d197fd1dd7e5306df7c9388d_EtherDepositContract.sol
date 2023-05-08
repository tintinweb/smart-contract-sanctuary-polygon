/**
 *Submitted for verification at polygonscan.com on 2023-05-08
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract EtherDepositContract {
    IERC20 private _token;
    uint256 private _tokenPrice;
    address private _owner;
    address payable public FundAcc;
    mapping(address => uint256) private _balances;

    event Deposit(address indexed user, uint256 amount, uint256 tokens);
    event Withdraw(address indexed user, uint256 amount);

    constructor(address token, uint256 tokenPrice,address payable _fundacc) {
        _token = IERC20(token);
        _tokenPrice = tokenPrice;
        _owner = msg.sender;
        FundAcc= _fundacc;
    }

    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");

        uint256 tokensToTransfer = msg.value / _tokenPrice;

        require(_token.balanceOf(address(this)) >= tokensToTransfer, "Contract does not have enough tokens to transfer");

        _balances[msg.sender] += msg.value;

        require(_token.transfer(msg.sender, tokensToTransfer), "Token transfer failed");

        emit Deposit(msg.sender, msg.value, tokensToTransfer);
    }

    // function withdraw(uint256 amount, address payable _payer) external {
    //     require(amount > 0, "Withdrawal amount must be greater than zero");
    //     require(_balances[msg.sender] >= amount, "Insufficient balance");

    //     _balances[msg.sender] -= amount;
    //     _payer.transfer(amount);

    //     emit Withdraw(msg.sender, amount);
    // }

    function balanceOf(address user) external view returns (uint256) {
        return _balances[user];
    }

    function setTokenPrice(uint256 price) external {
        require(msg.sender == _owner, "Only contract owner can set token price");
        _tokenPrice = price;
    }

    function getTokenPrice() external view returns (uint256) {
        return _tokenPrice;
    }

    function getTotalTokenBalance() external view returns (uint256) {
        return _token.balanceOf(address(this));
    }

    function withdrawAllEther() external {
        require(msg.sender == FundAcc, "Only contract owner can withdraw Ether");
        uint256 balance = address(this).balance;
        FundAcc.transfer(balance);

        emit Withdraw(FundAcc, balance);
    }
}