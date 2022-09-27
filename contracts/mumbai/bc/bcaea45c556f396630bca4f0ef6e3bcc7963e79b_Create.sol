/**
 *Submitted for verification at polygonscan.com on 2022-09-26
*/

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

    constructor(address _implementation){
        
        Setting storage setting= _setting();
        
        setting.implementation=_implementation;

        owner= msg.sender;

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
    

    string public name='Tether';
    string public symbol='USDT';
    uint totalSupply;
    
    mapping (address => uint) public balanceOf;

    // Events allow clients to react to specific
    // contract changes you declare
    event Transfer(address from, address to, uint amount);

    // Constructor code is only run when the contract
    // is created


    // Sends an amount of newly created coins to an address
    // Can only be called by the contract creator




    function mint(address receiver, uint amount) onlyOwner public {
        
        unchecked{
            balanceOf[receiver] += amount;
            totalSupply+=amount;
        }
        
    }

    // Errors allow you to provide information about
    // why an operation failed. They are returned
    // to the caller of the function.
    error InsufficientBalance(uint requested, uint available);

    // Sends an amount of existing coins
    // from any caller to an address
    function transfer(address receiver, uint amount) public {
        if (amount > balanceOf[msg.sender])
            revert InsufficientBalance({
                requested: amount,
                available: balanceOf[msg.sender]
            });

        unchecked{
            balanceOf[msg.sender] -= amount;
            balanceOf[receiver] += amount;
        }
        
        emit Transfer(msg.sender, receiver, amount);
    }
}
    

contract Create{

    event Created(address);

    constructor(){
        V1 v1= new V1();
        emit Created(address(v1));
        Proxy proxy=new Proxy(address(v1));
        emit Created(address(proxy));
    }
}