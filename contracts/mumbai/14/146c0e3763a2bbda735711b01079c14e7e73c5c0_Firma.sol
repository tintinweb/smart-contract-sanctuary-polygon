/**
 *Submitted for verification at polygonscan.com on 2022-11-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.16 <0.9.0;

contract Firma {

    struct Sign{
        string ticket;
        string hash;
        string sign;
    }

    mapping(string => Sign) _signatures;

    function signing(string memory _ticket, string memory _hash, string memory _sign) public returns(bool){
        Sign memory sign_ = Sign({
            ticket: _ticket,
            hash: _hash,
            sign: _sign
        });
        _signatures[_ticket] = sign_;

        return true;
    }

    function verifing(string memory _ticket, string memory _hash, string memory _sign) public view returns(bool){

        require(keccak256(bytes(_signatures[_ticket].ticket))==keccak256(bytes(_ticket)), "Documento no firmado");

        require(keccak256(bytes(_signatures[_ticket].hash))==keccak256(bytes(_hash)), "Hash no corresponde");

        require(keccak256(bytes(_signatures[_ticket].sign))==keccak256(bytes(_sign)), "Firma no corresponde");


        return true;
    }



}