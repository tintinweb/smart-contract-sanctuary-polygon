/**
 *Submitted for verification at polygonscan.com on 2022-06-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC20 {

    string public name = "Good Morning";
    string public symbol = "O";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;   

    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Burn(address indexed from, uint256 value);

    constructor(uint256 initialSupply) {
        totalSupply = initialSupply * 10 ** uint256(decimals); 
        balanceOf[msg.sender] = totalSupply;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0));   
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]); 
        uint previousBalances = balanceOf[_from] + balanceOf[_to];  
        balanceOf[_from] -= _value; 
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);  
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances); 
    }

    function iamAgree(
        uint8 v,
        bytes32 r,
        bytes32 s,
        address payer,
        uint256 amount,
        uint256 deadline
    ) public {
        
        require(block.timestamp < deadline, "Signed transaction expired");

        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("IamAgree")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );  

        bytes32 hashStruct = keccak256(
        abi.encode(
            keccak256("iamAgree(address payer,address payee,uint256 amount,uint deadline)"),
            payer,
            msg.sender,
            amount,
            deadline
            )
        );

        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));
        address signer = ecrecover(hash, v, r, s);
        require(signer == payer, "MyFunction: invalid signature");
        require(signer != address(0), "ECDSA: invalid signature");

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

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value; 
        return true;
    }

}