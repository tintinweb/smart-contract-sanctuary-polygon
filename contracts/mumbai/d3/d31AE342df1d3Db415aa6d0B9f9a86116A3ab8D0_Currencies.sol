/**
 *Submitted for verification at polygonscan.com on 2023-04-09
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IParent{

    function GetContractAddress(string calldata name) external view returns(address);
    function Owner() external view returns(address);
    function MATIC() external view returns(address);
}

interface IERC20{

    function symbol() external view returns (string memory);
}

contract Currencies{

//-----------------------------------------------------------------------// v EVENTS

    event CurrencyAddition(address indexed _currency);
    event CurrencyRemoval(address indexed _currency);

//-----------------------------------------------------------------------// v INTERFACES

    IParent constant private pt = IParent(parentAddress);

//-----------------------------------------------------------------------// v BOOLEANS

//-----------------------------------------------------------------------// v ADDRESSES

    address constant private parentAddress = 0xfc82AD7B08bC6AF0b0046ee8aE6b12df3457DE23;
    //
    address immutable private MATIC;

//-----------------------------------------------------------------------// v NUMBERS

//-----------------------------------------------------------------------// v BYTES

//-----------------------------------------------------------------------// v STRINGS

    string constant public Name = ".Payment.Currencies";
    //
    string[] private currencies;

//-----------------------------------------------------------------------// v STRUCTS

//-----------------------------------------------------------------------// v ENUMS

//-----------------------------------------------------------------------// v MAPPINGS

    mapping(string => address) private symbolToAddress;
    mapping(address => string) private addressToSymbol;

//-----------------------------------------------------------------------// v MODIFIERS

    modifier ownerOnly{

        if(pt.Owner() != msg.sender)
            revert("Owner only");

        _;
    }

//-----------------------------------------------------------------------// v CONSTRUCTOR

    constructor(){
    
        MATIC = pt.MATIC();
    }

//-----------------------------------------------------------------------// v PRIVATE FUNCTIONS

//-----------------------------------------------------------------------// v GET FUNCTIONS

    function GetCurrencyAddress(string calldata _symbol) public view returns(address){

        return symbolToAddress[_symbol];
    }

    function GetCurrencySymbol(address _addr) public view returns(string memory){

        return addressToSymbol[_addr];
    }
    //
    function GetCurrencyList() public view returns(string[] memory){

        return(currencies);
    }

//-----------------------------------------------------------------------// v SET FUNTIONS

    function AddCurrency(string calldata _symbol, address _addr) public ownerOnly returns(bool){

        address tokenAddress = symbolToAddress[_symbol];

        if(tokenAddress != address(0))
            revert("Symbol already used");
        else if(keccak256(abi.encodePacked(addressToSymbol[_addr])) != keccak256(abi.encodePacked("")))
            revert("Address already used");

        uint32 size;
        assembly{size := extcodesize(_addr)}

        if(size == 0)
            revert("Not a contract");

        string memory sb = IERC20(_addr).symbol();

        if(keccak256(abi.encodePacked(_symbol)) != keccak256(abi.encodePacked(sb)))
            revert("Symbol mismatch");

        symbolToAddress[_symbol] = _addr;
        addressToSymbol[_addr] = _symbol;

        currencies.push(_symbol);

        emit CurrencyAddition(_addr);
        return(true);
    }

    function RemoveCurrency(string calldata _symbol) public ownerOnly returns(bool){

        address tokenAddress = symbolToAddress[_symbol];

        if(tokenAddress == address(0))
            revert("Symbol not used");
        
        delete addressToSymbol[tokenAddress];
        delete symbolToAddress[_symbol];

        uint256 lng = currencies.length;

        for(uint256 i = 0; i < lng; i++){

            if(keccak256(abi.encodePacked(_symbol)) == keccak256(abi.encodePacked(currencies[i]))){

                currencies[i] = currencies[lng-1];
                break;
            }
        }

        currencies.pop();

        emit CurrencyRemoval(tokenAddress);
        return(true);
    }

//-----------------------------------------------------------------------// v DEFAULTS

    receive() external payable{

        if(msg.value > 0)
            payable(address(pt.GetContractAddress(".Corporation.Vault"))).call{value : msg.value}("");
    }

    fallback() external{
        
        revert("Currencies fallback reverted");
    }
}