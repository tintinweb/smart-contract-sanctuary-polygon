//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface MemberToken {
    function balanceOf(address owner) external view returns (uint256);
}

contract TokenBank {
    MemberToken public memberToken;

    string private _name;
    string private _symbol;
    uint256 constant _totalSupply = 1000; // Token発行上限
    uint256 private _bankTotalDeposit; // 銀行残高トータル
    address public owner;

    // アドレスとToken残高の辞書型配列
    mapping(address => uint256) private _balances;
    // アドレスと銀行残高の辞書型配列
    mapping(address => uint256) private _tokenBankBalances;

    // Tokenのユーザー→ユーザー移転ログ
    event TokenTransfar(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    // Tokenのユーザー→Bank移転ログ
    event TokenDeposit(
        address indexed from,
        uint256 amount
    );

    // TokenのBank→ユーザー移転ログ
    event TokenWithdraw(
        address indexed from,
        uint256 amount
    );

    constructor(string memory name_, string memory symbol_, address nftContract_) {
        _name = name_;
        _symbol = symbol_;
        owner = msg.sender;
        _balances[owner] = _totalSupply;
        memberToken = MemberToken(nftContract_);
    }

    // NFTメンバーであることの審査
    modifier onlyMember() {
        require(memberToken.balanceOf(msg.sender) > 0, "You are not a member");
        _;
    }

    // owner以外であることの審査
    modifier notOwner() {
        require(owner != msg.sender, "Owner cannot excecute");
        _;
    }

    // nameを返すfunction
    function name() public view returns (string memory) {
        return _name;
    }

    // symbolを返すfunction
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    // totalSupplyを返すfunction
    function totalSupply() public pure returns (uint256) {
        return _totalSupply;
    }

    // アドレスの残高を返すfunction
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    // Token移転function
    function transfar(address to, uint256 amount) public onlyMember {
        if (owner == msg.sender) {
            require(_balances[owner] - _bankTotalDeposit >= amount, "amount over");
        }
        address from = msg.sender;
        _transfar(from, to, amount);
    }

    // Token移転の内部関数
    function _transfar(address from, address to, uint256 amount) internal {
        require(to != address(0), "Zero address cannot transfar.");
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "Your money is running low.");
        _balances[from] = fromBalance - amount;
        _balances[to] += amount;
        emit TokenTransfar(from, to, amount);
    }

    // 銀行残高トータルを返す
    function bankTotalDeposit() public view returns (uint256) {
        return _bankTotalDeposit;
    }

    // アドレス別の銀行残高を返す
    function bankBalanceOf(address account) public view returns (uint256) {
        return _tokenBankBalances[account];
    }

    // トークンを銀行に預ける
    function deposit(uint256 amount) public onlyMember notOwner {
        address from = msg.sender;
        address to = owner;

        _transfar(from, to, amount);
        _tokenBankBalances[from] += amount;
        _bankTotalDeposit += amount;
        emit TokenDeposit(from, amount);
    }

    // トークンを銀行から引き出す
    function withdraw(uint256 amount) public onlyMember notOwner {
        address to = msg.sender;
        address from = owner;
        uint256 toTokenBankBlance = _tokenBankBalances[to];
        require(toTokenBankBlance >= amount, "Money is not enough.");

        _transfar(from, to, amount);
        _tokenBankBalances[to] -= amount;
        _bankTotalDeposit -= amount;
        emit TokenWithdraw(to, amount);
    }
}