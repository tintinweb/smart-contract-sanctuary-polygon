/**
 *Submitted for verification at polygonscan.com on 2022-12-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
contract LiterDex {
    // address onwer;
    uint256[] num;
    uint256[] total;
    string[] logo;
    // mapping (address payable => uint256) public balances;
    IERC20[] public token;
    address[] public onwer;
    address public owner;
    uint256 constlogo;
    uint256 const;

    constructor() {
        constlogo = 10 ether;
        const = 0;
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    function buy(address _address) public payable {
        uint256 _indextoken = getIndex(_address);
        require(msg.value > 0, "saldo tidak boleh kosong");
        uint256 amount = msg.value * token[_indextoken].balanceOf(address(this)) / (num[_indextoken]+msg.value);
        require(amount <= token[_indextoken].balanceOf(address(this)), "Balance token tidak cukup");
        uint256 fee = amount * 1 / 100;
        token[_indextoken].transfer(msg.sender, amount - fee);
        token[_indextoken].transfer(onwer[_indextoken], fee);
        total[_indextoken] += msg.value;
    }
    function sell(address _address,uint256 amount) public {
        uint256 _indextoken = getIndex(_address);
        require(amount > 0, "You need to sell at least some tokens");

        uint256 tokensuplay = token[_indextoken].balanceOf(address(this))  + amount;

        uint256 allowance = token[_indextoken].allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");

        uint256 coinamount = amount * num[_indextoken] / tokensuplay; 
        uint256 fee = coinamount * 1 /100;
        
        token[_indextoken].transferFrom(msg.sender, address(this), amount);
        require(total[_indextoken] >= coinamount , "transaksi gagal");
        require(coinamount > 0, "transaksi gagal (harga)");
        payable(msg.sender).transfer(coinamount - fee);
        payable(onwer[_indextoken]).transfer(fee);
        total[_indextoken] -= coinamount;
    }
    
    function setlogo(address _address,string memory url) public{
        uint256 _indextoken = getIndex(_address);
        
        if (msg.sender != owner){
            uint256 allowance = token[0].allowance(msg.sender, owner);
            require(allowance >= constlogo, "Check the token allowance");
            token[0].transferFrom(msg.sender, owner, constlogo);
        }

        logo[_indextoken] = url;
    }

    function setconstlogo(uint256 _constlogo ) public isOwner{
        constlogo = _constlogo;
    }
    function setconst(uint256 _const ) public isOwner{
        const = _const;
    }
    function getconstlogo() public view returns(uint256){
        return constlogo;
    }
    function getconst() public view returns(uint256){
        return const;
    }

    function getlogo(address _address) public view returns(string memory){
        uint256 _indextoken = getIndex(_address);
        return logo[_indextoken];
    }

    function getharga(address _address,uint256 amount) public view returns(uint256){
        uint256 _indextoken = getIndex(_address);
        uint256 tokensuplay = token[_indextoken].balanceOf(address(this)) + amount;
        uint256 harga = amount * num[_indextoken] / tokensuplay;
        uint256 fee = harga * 1 /100;
        return  harga - fee;
    }

    function getMatic(address _address) public view returns(uint256){
        uint256 _indextoken = getIndex(_address);
        return  total[_indextoken];
    }
    function getall() public view returns(uint256){
        return  token.length;
    }


    function addToken(address _token,uint256 amount,uint256 _num) public{
        for (uint256 i = 0; i < token.length; i++) {
        if (token[i] == IERC20(_token)) {
            require(false, "token sudah ada");
           }
        }

        if (msg.sender != owner){
         if(const != 0){
                uint256 allowance1 = token[0].allowance(msg.sender, owner);
                require(allowance1 >= const, "Check the token allowance");
                token[0].transferFrom(msg.sender, owner, const);
         }
        }
        
        require(amount > 0, "You need to sell at least some tokens");
        uint256 allowance = IERC20(_token).allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        IERC20(_token).transferFrom(msg.sender, address(this), amount);
        uint256 dexBalance = IERC20(_token).balanceOf(address(this));
        onwer.push(msg.sender);
        total.push(0);
        token.push(IERC20(_token));
        require(dexBalance / _num <= amount, "harga tidak falid");
        num.push(dexBalance / _num);
        logo.push("https://litertoken.com/img/logo/logo1.png");
    }
    
    function getIndex(address _address) public view returns (uint256) {
    for (uint256 i = 0; i < token.length; i++) {
        if (token[i] == IERC20(_address)) {
            return i;
        }
    }
        require(false, "data tidak di temukan");
        return 0;
    }

    function withdraw(address _address) public payable{
        uint256 _indextoken = getIndex(_address);


        require(total[_indextoken] > 0, "tidak ada saldo");
        require(msg.sender == onwer[_indextoken], "bukan pemilik");

        if (msg.sender != owner){
                uint256 harga = constlogo / 2 ;
                uint256 allowance1 = token[0].allowance(msg.sender, owner);
                require(allowance1 >= harga, "Check the token allowance");
                token[0].transferFrom(msg.sender, owner, harga);
         }
        
        (bool os, ) = payable(onwer[_indextoken]).call{value: total[_indextoken]}("");
        total[_indextoken] = 0;
        uint256 amount = token[_indextoken].balanceOf(address(this));
        token[_indextoken].transfer(onwer[_indextoken], amount);
        require(os);

    }

}