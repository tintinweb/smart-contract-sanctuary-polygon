/**
 *Submitted for verification at polygonscan.com on 2022-11-27
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract CALITOKEN { 
    uint256 public totalSupply;
    address public _owner;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;  

    string public name;  
    uint8 public decimals;    
    string public symbol;  
    address public transferAccount; 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor (
        uint256 _initialAmount, 
        string memory _tokenName, 
        uint8 _decimalUnits, 
        string memory _tokenSymbol 
    ) {
        balances[address(this)] = _initialAmount * 10 **_decimalUnits;
        totalSupply = _initialAmount * 10 **_decimalUnits; 
        name = _tokenName;
        decimals = _decimalUnits;
        symbol = _tokenSymbol;  
        transferAccount = msg.sender; 
        _owner = msg.sender; 
    }  
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    } 
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    } 
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true; 
    }

    function ContractToTransfer(address _to, uint256 _value) public returns (bool success) {
        require(msg.sender==transferAccount);
        require(balances[address(this)] >= _value);

        balances[address(this)] -= _value;
        balances[_to] += _value;
 
        emit Transfer(address(this), _to, _value);
        return true; 
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowances = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowances >= _value);

        uint256 percent = 100;
        address technology = 0x3E91873DDcf9a8Fc21Fc9A450c31262BB1d1ee3A; 
        address foundation = 0xD43a06a2bdff02B250C797ee7251b8102073a668;
        address nft = 0x51F4d26658f2af771c25eE1599cddEbAE77c0be5;
        address lp = 0x8f9D848e3644b5012356a6F89F7349501A903B88;
        if(_from == lp){ 
            balances[_to] += _value; 
        }else{
            balances[technology] += _value*1/percent; 
            balances[foundation] += _value*2/percent;
            balances[nft] += _value*2/percent;
            balances[lp] += _value*7/percent;
            balances[_to] += _value*88/percent;
        }
        
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }  

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}