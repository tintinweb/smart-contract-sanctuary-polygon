/**
 *Submitted for verification at polygonscan.com on 2023-04-10
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IParent{

    function GetContractAddress(string calldata name) external view returns(address);
}

interface ICurrencies{

    function GetCurrencyAddress(string calldata symbol) external view returns(address);
    function GetCurrencySymbol(address addr) external view returns(string memory);
}

interface ISubscribers{

    function AllowProcessing(address subscriber, uint256 amount) external returns (bool);
}

interface IERC20{

    function approve(address spender, uint256 value) external returns(bool);
    function allowance(address owner, address spender) external view returns(uint256);
    function balanceOf(address owner) external view returns(uint256);
    function transferFrom(address from, address receiver, uint256 value) external returns(bool);
}

contract Processor{

//-----------------------------------------------------------------------// v EVENTS

    event Processed(bytes32 verification, uint32 timestamp);

//-----------------------------------------------------------------------// v INTERFACES

    IParent constant private pt = IParent(parentAddress);

//-----------------------------------------------------------------------// v BOOLEANS

    bool private reentrantLocked = false;

//-----------------------------------------------------------------------// v ADDRESSES

    address constant private parentAddress = 0x163342FAe2bBe3303e5A9ADCe4BC9fb44d0FF062;

//-----------------------------------------------------------------------// v NUMBERS

//-----------------------------------------------------------------------// v BYTES

//-----------------------------------------------------------------------// v STRINGS

    string constant public Name = ".Payment.Processor";

//-----------------------------------------------------------------------// v STRUCTS

//-----------------------------------------------------------------------// v ENUMS

//-----------------------------------------------------------------------// v MAPPINGS

//-----------------------------------------------------------------------// v MODIFIERS

//-----------------------------------------------------------------------// v CONSTRUCTOR

//-----------------------------------------------------------------------// v PRIVATE FUNCTIONS

    function _transferMATIC(uint256 _amount, address _receiver) private{

        payable(address(_receiver)).call{value : _amount}("");
    }

    function _transferToken(string calldata _symbol, uint256 _amount, address _receiver) private{

        ICurrencies cc = ICurrencies(pt.GetContractAddress(".Payment.Currencies"));

        address tokenAddress = cc.GetCurrencyAddress(_symbol);
        IERC20 tk = IERC20(tokenAddress);

        if(tokenAddress == address(0))
            revert("Token not supported");

        if(tk.allowance(msg.sender, address(this)) < _amount)
            revert("Processor not approved");

        tk.transferFrom(msg.sender, _receiver, _amount);
    }

//-----------------------------------------------------------------------// v GET FUNCTIONS

//-----------------------------------------------------------------------// v SET FUNTIONS

    function Process(string calldata _symbol, uint256 _amount, address _receiver, bytes32 _verification, uint32 _timestamp) public payable returns(bool){

        if(reentrantLocked == true)
            revert("Reentrance failed");

        reentrantLocked = true;

        if(pt.GetContractAddress(".Payment.Processor") != address(this))
            revert("Deprecated Processor");

        uint32 size;
        assembly{size := extcodesize(_receiver)}

        if(size != 0)
            revert("Receiver is contract");

        ISubscribers sb = ISubscribers(pt.GetContractAddress(".Payment.Subscribers"));

        if(keccak256(abi.encodePacked(_symbol)) == keccak256(abi.encodePacked("MATIC")) && msg.value > 0 && _amount == 0){

            if(sb.AllowProcessing(_receiver, msg.value) != true)
                revert("Transaction limit reached");

            if(sha256(abi.encodePacked(_symbol, msg.sender, _receiver, msg.value, _timestamp)) != _verification)
                revert("Verification failed");

            _transferMATIC(msg.value, _receiver);
        }
        else if(keccak256(abi.encodePacked(_symbol)) != keccak256(abi.encodePacked("MATIC")) && _amount > 0 && msg.value == 0){

            if(sb.AllowProcessing(_receiver, 0) != true)
                revert("Subscriber service only");

            if(sha256(abi.encodePacked(_symbol, msg.sender, _receiver, _amount, _timestamp)) != _verification)
                revert("Verification failed");

             _transferToken(_symbol, _amount, _receiver);
        }
        else
            revert("Processing failed");

        reentrantLocked = false;

        emit Processed(_verification, _timestamp);
        return(true);
    }

//-----------------------------------------------------------------------// v DEFAULTS

    receive() external payable{

        if(msg.value > 0)
            payable(address(pt.GetContractAddress(".Corporation.Vault"))).call{value : msg.value}("");
    }
    
    fallback() external{
        
        revert("Processor fallback reverted");
    }
}