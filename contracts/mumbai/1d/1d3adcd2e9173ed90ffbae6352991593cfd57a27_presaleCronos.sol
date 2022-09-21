/**
 *Submitted for verification at polygonscan.com on 2022-09-20
*/

/**
 *Submitted for verification at polygonscan.com on 2022-09-08
*/

pragma solidity 0.8.17;

//SPDX-License-Identifier: MIT Licensed

interface IToken {
    function totalSupply() external view returns (uint256);
     function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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


contract presaleCronos {
    IToken public token;
    address payable public owner;

    uint256 public tokenPerCronos;
    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public preSaleTime;
    uint256 public soldToken;

    mapping(address => uint256) public Cronosbalances;
    mapping(address => uint256) public tokenBalance;
    mapping(address => bool) public claimed;

    modifier onlyOwner() {
        require(msg.sender == owner, "preSale: Not an owner");
        _;
    }

    constructor(
        IToken _token
    ) {
        owner = payable(msg.sender);
        token = _token;
        tokenPerCronos = 100;
        minAmount = 0.01 ether;
        maxAmount = 10 ether;
        preSaleTime = block.timestamp + 180 days;
    }

    receive() external payable {}


    // to buy billz token during preSale time => for web3 use
    function buyToken() public payable {
        uint256 numberOfTokens = CronosToToken(msg.value);
        uint256 maxToken = CronosToToken(maxAmount);

        require(
            msg.value >= minAmount && msg.value <= maxAmount,
            "preSale: Amount not correct"
        );
        require(
            numberOfTokens + (tokenBalance[msg.sender]) <= maxToken,
            "preSale: Amount exceeded max limit"
        );
        require(block.timestamp < preSaleTime, "preSale: PreSale over");
        Cronosbalances[msg.sender] += msg.value;
        tokenBalance[msg.sender] += numberOfTokens;
        token.transferFrom(owner, msg.sender, numberOfTokens);
        soldToken = soldToken + (numberOfTokens);
    }

    // to check number of token for given Cronos
    function CronosToToken(uint256 _amount) public view returns (uint256) {
        return  (_amount * 10**token.decimals() * (tokenPerCronos)) / 1e18;
    }

    // to change Price of the token
    function changePrice(uint256 _tokenPerCronos) external onlyOwner {
        tokenPerCronos = _tokenPerCronos;
    }

    function setPreSaleAmount(uint256 _minAmount, uint256 _maxAmount)
        external
        onlyOwner
    {
        require(
            _minAmount <= _maxAmount,
            "preSale: Min amount should be less than max amount"
        );
        minAmount = _minAmount;
        maxAmount = _maxAmount;
    }

    function setpreSaleTime(uint256 _time) external onlyOwner {
        preSaleTime = _time;
    }

    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner {
        require(_newOwner != address(0), "preSale: New owner cannot be 0x0");
        owner = _newOwner;
    }

    // to draw funds for liquidity
    function transferFunds(uint256 _value) external onlyOwner returns (bool) {
        owner.transfer(_value);
        return true;
    }

    function withdrawStuckFunds(IToken _token, uint256 amount)
        external
        onlyOwner
    {
        require(
            _token.balanceOf(address(this)) >= amount,
            "preSale: Insufficient funds"
        );
        _token.transfer(msg.sender, amount);
    }

    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    function contractBalanceCronos() external view returns (uint256) {
        return address(this).balance;
    }

    function getContractTokenBalance() external view returns (uint256) {
        return token.allowance(owner, address(this));
    }
}