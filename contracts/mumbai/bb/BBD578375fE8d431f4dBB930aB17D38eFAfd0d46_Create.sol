// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;



contract Owner{
    address public owner;

    event OwnerTransfered(address);

    modifier onlyOwner(){
        require(msg.sender==owner,'no permission');
        _;
    }

    function changeOwner(address newOwner) onlyOwner external {
        owner=newOwner;
        emit OwnerTransfered(newOwner);
    }
}


contract Proxy is Owner{
    
    struct Setting{
        address implementation;
    }


    event Modified(address implementation);

    constructor(address _implementation,address _owner){
        
        Setting storage setting= _setting();
        
        setting.implementation=_implementation;

        owner= _owner;

    }

    function _setting() internal pure returns(Setting storage setting){
        bytes32 position= bytes32('implementation');

        assembly {
            setting.slot:=position
        }
    }

    function modify(address _implementation) onlyOwner external {
        Setting storage setting=_setting();
        setting.implementation=_implementation;
        emit Modified(_implementation);
    }




    function _delegate(address _imp) internal virtual {
        assembly {
            // calldatacopy(t, f, s)
            // copy s bytes from calldata at position f to mem at position t
            calldatacopy(0, 0, calldatasize())

            // delegatecall(g, a, in, insize, out, outsize)
            // - call contract at address a
            // - with input mem[in…(in+insize))
            // - providing g gas
            // - and output area mem[out…(out+outsize))
            // - returning 0 on error and 1 on success
            let result := delegatecall(gas(), _imp, 0, calldatasize(), 0, 0)

            // returndatacopy(t, f, s)
            // copy s bytes from returndata at position f to mem at position t
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                // revert(p, s)
                // end execution, revert state changes, return data mem[p…(p+s))
                revert(0, returndatasize())
            }
            default {
                // return(p, s)
                // end execution, return data mem[p…(p+s))
                return(0, returndatasize())
            }
        }
    }

    fallback() external {
        Setting storage setting=_setting();
        address implementation =setting.implementation;
        _delegate(implementation);
    }
    
}



contract V1 is Owner{
    

    string public symbol;
    string public name;
    uint totalSupply;
    
    mapping (address => uint) public balanceOf;
    mapping (address=> mapping(address => uint)) private _allowance;

    
    event Transfer(address indexed _from, address indexed _to, uint amount);
    event Approval(address indexed _owner,address indexed _spender, uint amount);


    error InsufficientBalance(uint requested, uint available);


    constructor(
        string memory _name,
        string memory _symbol,
        address _owner
    ){
        name=_name;
        symbol=_symbol;
        owner=_owner;
    }





    function mint(address receiver, uint amount) onlyOwner public {
        
        
        balanceOf[receiver] += amount;
        totalSupply+=amount;
        
        
    }



    function transfer(address receiver, uint amount) public {
        if (amount > balanceOf[msg.sender])
            revert InsufficientBalance({
                requested: amount,
                available: balanceOf[msg.sender]
            });

        
        balanceOf[msg.sender] -= amount;
        balanceOf[receiver] += amount;
        
        
        emit Transfer(msg.sender, receiver, amount);
    }


    function approve(address _spender,uint _value) external returns(bool sucess){
        _allowance[msg.sender][_spender]=_value;
        return true;
    }

    function transferFrom(address _spender,uint _value) external returns(bool){
        require(_value<_allowance[_spender][msg.sender]);
        _allowance[_spender][msg.sender]-=_value;
        balanceOf[_spender] -= _value;
        balanceOf[msg.sender] += _value;
        emit Transfer(_spender, msg.sender, _value);
        return true;      
    }

    function allowance(address _owner, address _spender) external view returns(uint){
        return _allowance[_owner][_spender];
    }


}
    

contract Create{

    event Created(address);

    constructor(){
        V1 v1= new V1('Tether','USDT',msg.sender);
        emit Created(address(v1));
        Proxy proxy=new Proxy(address(v1),msg.sender);
        emit Created(address(proxy));
    }
}