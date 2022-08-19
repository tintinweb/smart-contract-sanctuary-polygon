/**
 *Submitted for verification at polygonscan.com on 2022-08-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

contract Clase_2_ejercicio {
   
    string name = "Dvjorge";
    uint edad = 37;
    bool spanish = true;
    address cartera = 0x313605855224EE134B60F8F1d98e123F66d60cf6;

    function getName() public view returns (string memory){
        return name;
     }
    
    function setName(string memory newName) public {
        name = newName;
        }

    function getEdad() public view returns (uint){
        return edad;
    }

    function setEdad(uint newEdad) public {
        edad = newEdad;
    }

    function getSpanish() public view returns (bool){
        return spanish;
    }

    function setSpanish(bool newSpanish) public {
        spanish = newSpanish;
    }
    
    function getCartera() public view returns (address){
        return cartera;
    }

    function setCartera(address newCartera) public {
        cartera = newCartera;
    }








     
}