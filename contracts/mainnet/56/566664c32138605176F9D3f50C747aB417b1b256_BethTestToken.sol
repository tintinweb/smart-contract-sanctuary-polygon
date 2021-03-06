/**
 *Submitted for verification at polygonscan.com on 2022-01-30
*/

pragma solidity >=0.4.22 <=0.6.2;

contract Token {

    
    function totalSupply() constant returns (uint256 supply) {}

   
    function balanceOf(address _owner) constant returns (uint256 balance) {}

 
    function transfer(address _to, uint256 _value) returns (bool success) {}

   
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    
    function approve(address _spender, uint256 _value) returns (bool success) {}

    
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
       
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

contract BethTestToken is StandardToken { 
    
    string public name;                  
    uint8 public decimals;               
    string public symbol;                 
    string public version = 'H1.0';       
    uint256 public unitsOneEthCanBuy;     
    uint256 public totalEthInWei;         
    address public fundsWallet;           


    
    function BethTestToken() {
        balances[0x88BB6D548CAF0fc1BaF27B9c222e25d157b0D002] = 5000000000000000000000000;             
        //balances[msg.sender] = 1000;                             
                                                                  
        totalSupply = 5000000000000000000000000;                     
        //totalSupply = 1000;                                     
        name = "EnkiX";                                       
        decimals = 18;                                             
        symbol = "EKX";                                           
        unitsOneEthCanBuy = 2;                                    
        fundsWallet = 0x88BB6D548CAF0fc1BaF27B9c222e25d157b0D002;                                  
    }

    function() payable{
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        //require(balances[fundsWallet] >= amount,"");
        if(balances[fundsWallet] < amount) {
            return;
        }

        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;

        Transfer(fundsWallet, msg.sender, amount); // Broadcast a message to the blockchain

        //Transfer ether to fundsWallet
        fundsWallet.transfer(msg.value);
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn't have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}