// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;


contract AadharRegistery{
    struct aadharcard{
        uint256 ano;
        string _name;
        string _address;
    }
    mapping (address => aadharcard) public person;
    function createAadhar(address a,uint256 ano,string memory _name,string memory _address)public{
        aadharcard storage p = person[a];
        p._name=_name;
        p._address=_address;
        p.ano=ano;
    }
    function getDetails(address a)public view returns(aadharcard memory){
        return person[a];
    }
}