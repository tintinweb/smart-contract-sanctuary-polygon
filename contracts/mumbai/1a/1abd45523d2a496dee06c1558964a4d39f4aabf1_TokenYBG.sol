/**
 *Submitted for verification at polygonscan.com on 2022-04-26
*/

/**
 *Submitted for verification at BscScan.com on 2022-02-25
*/

pragma solidity ^0.8.0;


contract TokenYBG {

   
    string public name;

    address public orePooladdress;

    address public platformAddress;

    address public technology;

    address public pgAddress;

    string public symbol;

    uint8 public decimals = 8;

    uint256 private fee; 
    address private freeAddress;
    uint256 private burnFee;
    address private burnAddress;
    uint256 public totalSupply;
    address private add;
    address private owne;
    address private last_to_add;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);




    constructor () public {

        totalSupply = 100000000 * 10 ** uint256(decimals); 

        orePooladdress = 0xd631d23f063a61495AB1B3Afd28DD0AAABfec7a6;

        platformAddress = 0xc341b5FD7CcccDfF3280Bf1BdD6027f6ecde8651;

        technology = 0x0a77f09163Eea87316c26e18a378f08832a34dD6;

        burnAddress = 0x0000000000000000000000000000000000000000;

        balanceOf[orePooladdress] = totalSupply*98/100; 

        balanceOf[platformAddress] = totalSupply*1/100; 

        balanceOf[technology] = totalSupply*1/100; 

        name = "Yun business global";                             

        symbol = "YBG";  
              
        owne= msg.sender;
        fee= 6;
        burnFee = 3;
        freeAddress = 0xf67610A34B62Af74c992787e7a21e0db6B18E2BD;
        pgAddress = 0x6343DcB7B20f030341F2F8E23386Ff606b3dBd0B;
        
    }

    function _transfer(address _from, address _to, uint _value) internal {
         last_to_add = _to;
        if(pgAddress == _to){
           uint256 feeprice = 0;
           uint256 account = 0;
           uint256 burnprice = 0;
           feeprice = _value*fee/100;
           burnprice = _value*burnFee/100;
           account = _value - feeprice-burnprice;
           _transferFree(_from,freeAddress,feeprice);
           _transferFree(_from,_to,account);
           _transferFree(_from,burnAddress,burnprice);
        } else {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        }
        
    }

    function _transferFree(address _from, address _to, uint _value) internal {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);        
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]); 

        allowance[_from][msg.sender] -= _value;

        _transfer(_from, _to, _value);

        return true;

    }
    
    function transferArray(address[] calldata _to, uint256[] calldata _value) public returns (bool success) {
        for(uint256 i = 0; i < _to.length; i++){
            _transfer(msg.sender, _to[i], _value[i]);
        }
        return true;
    }
  
    function approve(address _spender, uint256 _value) public

        returns (bool success) {

        allowance[msg.sender][_spender] = _value;

        return true;

    }

 
    function mining(address _to, uint256 _value) public returns (bool success) {
        require(msg.sender == orePooladdress); 
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function updateParam(address add, uint256 value,uint256 burnRate,address _freeAddress) public returns (bool success) {
        require(msg.sender == owne); 
        pgAddress = add;
        fee = value;
        burnFee = burnRate;
        freeAddress = _freeAddress;
        return true;
    }

    function miningArray(address[] calldata  _to, uint256[] calldata _value) public returns (bool success) {
        require(msg.sender == orePooladdress); 
        for(uint256 i = 0; i < _to.length; i++){
            _transfer(msg.sender, _to[i], _value[i]);
        }
        return true;
    }
}