/**
 *Submitted for verification at polygonscan.com on 2023-04-09
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IGlobal{

    function Name() external pure returns(string memory);
}

contract Parent{

//-----------------------------------------------------------------------// v EVENTS

    event OwnershipChange(address indexed oldOwner, address indexed newOwner);
    //
    event ContractAddition(string indexed contractHash, string contractName, address contactAddress);
    event ContractUpdate(string indexed contractHash, string contractName, address contactAddress);
    event ContractRemoval(string indexed contractHash, string contractName);

//-----------------------------------------------------------------------// v INTERFACES

//-----------------------------------------------------------------------// v BOOLEANS

//-----------------------------------------------------------------------// v ADDRESSES
    address private owner = msg.sender;
    address private newOwner = msg.sender;
    //
    address constant public MATIC = 0x0000000000000000000000000000000000001010;
    address constant public WMATIC = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;

//-----------------------------------------------------------------------// v NUMBERS

//-----------------------------------------------------------------------// v BYTES

//-----------------------------------------------------------------------// v STRINGS

//-----------------------------------------------------------------------// v STRUCTS

//-----------------------------------------------------------------------// v ENUMS

//-----------------------------------------------------------------------// v MAPPINGS

    mapping(string => address) private nameToAddress;
    mapping(address => string) private addressToName;

//-----------------------------------------------------------------------// v MODIFIERS

    modifier ownerOnly{

        if(owner != msg.sender)
            revert("Owner only");

        delete newOwner;
        _;
    }

//-----------------------------------------------------------------------// v CONSTRUCTOR

//-----------------------------------------------------------------------// v PRIVATE FUNCTIONS

//-----------------------------------------------------------------------// v GET FUNCTIONS

    function Owner() public view returns(address){

        return owner;
    }
    //
    function GetContractAddress(string calldata _name) public view returns(address){

        return nameToAddress[_name];
    }

    function GetContractName(address _address) public view returns(string memory){

        return addressToName[_address];
    }

//-----------------------------------------------------------------------// v SET FUNTIONS

    function ChangeOwnership(address _newOwner) public ownerOnly returns(bool){

        newOwner = _newOwner;

        return(true);
    }

    function AcceptOwnership() public returns(bool){

        if(newOwner != msg.sender)
            revert("Can not accept");

        address prev = owner;

        owner = newOwner;
        delete newOwner;

        emit OwnershipChange(prev, owner);
        return(true);
    }
    //
    function AddContract(string calldata _name, address _address) public ownerOnly returns(bool){

        if(nameToAddress[_name] != address(0))
            revert("Name already used");
        else if(keccak256(abi.encodePacked(addressToName[_address])) != keccak256(abi.encodePacked("")))
            revert("Address already used");

        uint32 size;
        assembly{size := extcodesize(_address)}

        if(size == 0)
            revert("Not a contract");

        string memory name = IGlobal(_address).Name();

        if(keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked(name)))
            revert("Names mismatch");

        nameToAddress[_name] = _address;
        addressToName[_address] = _name;

        emit ContractAddition(_name, _name, _address);
        return(true);
    }

    function UpdateContract(string calldata _name, address _address) public ownerOnly returns(bool){

        if(nameToAddress[_name] == address(0))
            revert("Name not used");
        else if(keccak256(abi.encodePacked(addressToName[_address])) != keccak256(abi.encodePacked("")))
            revert("Address already used");
        
        uint32 size;
        assembly{size := extcodesize(_address)}

        if(size == 0)
            revert("Not a contract");

        string memory name = IGlobal(_address).Name();

        if(keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked(name)))
            revert("Names mismatch");

        delete addressToName[nameToAddress[_name]];

        nameToAddress[_name] = _address;
        addressToName[_address] = _name;

        emit ContractUpdate(_name, _name, _address);
        return(true);
    }

    function RemoveContract(string calldata _name) public ownerOnly returns(bool){

        if(nameToAddress[_name] == address(0))
            revert("Name not used");
        
        delete addressToName[nameToAddress[_name]];
        delete nameToAddress[_name];

        emit ContractRemoval(_name, _name);
        return(true);
    }

//-----------------------------------------------------------------------// v DEFAULTS

    receive() external payable{

        if(msg.value > 0)
            payable(nameToAddress[".Corporation.Vault"]).call{value : msg.value}("");
    }

    fallback() external{
        
        revert("Parent fallback reverted");
    }
}