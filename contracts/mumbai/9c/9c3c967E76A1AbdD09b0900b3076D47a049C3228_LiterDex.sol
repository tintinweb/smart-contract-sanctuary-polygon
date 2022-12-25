/**
 *Submitted for verification at polygonscan.com on 2022-12-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

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
contract LiterDex {
    address private owner;
    uint256 harga;
    bool fee;
    address mytoken;
    mapping (address => IERC20) public tokens;
    mapping (address => uint256) public matic;
    mapping (address => uint256) public totalM;
    mapping (address => uint256) public totalT;
    mapping (address => address) public owners;
    mapping (address => string) public logo;
    mapping (address => bool) public tokensList;
    address[] public tokensArray;

    // event Bought(uint256 amount);
    // event Sold(uint256 amount);
    event Buy(IERC20 token ,address to, uint256 amount);
    event Sell(IERC20 token ,address to, uint256 amount);

    constructor() {
        harga = 5 ether;
        owner = msg.sender;
        fee = false;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    function feetrue() public isOwner(){
        fee = true;
    }
    function feefalse() public isOwner(){
        fee = false;
    }
    function setharga(uint256 _harga) public isOwner(){
        harga = _harga;
    }
    function setMytoken(address token) public isOwner(){
        mytoken = token;
    }

    function addLiquidity(address token,uint256 amount,uint8 price_) public{
        require(price_ > 0, "price tidak boleh 0");
        require(!tokensList[token], "Token has already been added to the contract");

        if(msg.sender != owner ){
            if(fee  == true){
                uint256 allowance1 = tokens[mytoken].allowance(msg.sender, address(this));
                require(allowance1 >= amount, "Check the token allowance");
                tokens[mytoken].transferFrom(msg.sender, owner, harga / 2);
            }
        }

        tokens[token] = IERC20(token);
        owners[token] = msg.sender;
        logo[token] = "https://litertoken.com/img/logo/logo.png";
        uint256 allowance = tokens[token].allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        tokens[token].transferFrom(msg.sender, address(this), amount);
        matic[token] = amount / price_;
        totalM[token] = amount / price_;
        totalT[token] = amount;
        tokensList[token] = true;
        if(cek(token) == false){
        tokensArray.push(token);
        }
    }

    function getfee()public view returns(bool){
        return fee;
    }
    
    function list()public view returns(uint256){
        return tokensArray.length;
    }
   
    function price(uint256 iA,uint256 iR,uint256 oR)public view returns(uint256){
        uint256 fees = iA * 997;
        uint256 N = fees * oR;
        uint256 D = iR * 1000 + fees;
        return N/D;
    }

    function buy(address _addr) public payable{
        require(msg.value > 0, "saldo tidak boleh kosong");
        uint256 amount = price(msg.value,matic[_addr],tokens[_addr].balanceOf(address(this)));
        require(amount > 0, "hasil amount kosong");
        tokens[_addr].transfer(msg.sender, amount);
        matic[_addr] += msg.value;

        emit Buy(tokens[_addr] ,msg.sender,amount);
    }

    function sell(address _addr,uint256 amount) public{

        uint256 allowance = tokens[_addr].allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");

        tokens[_addr].transferFrom(msg.sender, address(this), amount);
        uint256 coin = price(amount,tokens[_addr].balanceOf(address(this)),matic[_addr]);
        require(coin > 0, "hasil coin kosong");
        require(coin <= address(this).balance, "balance kurang");
        payable(msg.sender).transfer(coin);
        matic[_addr]-= coin;

        emit Sell(tokens[_addr],msg.sender,amount);
    }

    
    function setlogo(address _addr,string memory url) public{
        if (msg.sender != owner){
            uint256 allowance = tokens[mytoken].allowance(msg.sender, address(this));
            require(allowance >= harga, "Check the token allowance");
            tokens[mytoken].transferFrom(msg.sender, owner, harga);
        }

        logo[_addr] = url;
    }

    function endLiqudity(address _address) public payable{
        require(tokensList[_address], "Token tidak ada");
        require(msg.sender == owners[_address], "bukan pemilik");

        if (msg.sender != owner){
                uint256 harga1 = harga * 2;
                uint256 allowance1 = tokens[mytoken].allowance(msg.sender, address(this));
                require(allowance1 >= harga1, "Check the token allowance");
                tokens[mytoken].transferFrom(msg.sender, owner, harga1);
         }
        
        (bool os, ) = payable(owners[_address]).call{value:  matic[_address] - totalM[_address] }("");
        uint256 amount = tokens[_address].balanceOf(address(this));
        tokens[_address].transfer(owners[_address], amount);
        require(os);
        delete matic[_address];
        delete tokens[_address];
        delete totalM[_address];
        delete totalT[_address];
        delete owners[_address];
        delete logo[_address];
        delete tokensList[_address];
    }

    function cek(address _address) public view returns (bool) {
    for (uint256 i = 0; i < tokensArray.length ; i++) {
        if (tokensArray[i] == _address) {
            return true;
        }
    }
        return false;
    }

    function MtoT(uint256 MATIC,address _addr)public view returns(uint256){
        uint256 amount = price(MATIC,matic[_addr],tokens[_addr].balanceOf(address(this)));
        return amount;
    }
    
    function TtoM(uint256 token,address _addr)public view returns(uint256){
        uint256 amount = price(token,tokens[_addr].balanceOf(address(this)),matic[_addr]);
        return amount;
    }

   
}