/**
 *Submitted for verification at polygonscan.com on 2022-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract Clase2ejercicio {

    // El ejercicio consiste en utilizar 4 variables diferentes de tipo string, uint, bool y address

        string name;   
        uint edad=18;

    // aunque haya definido la variable Medad haciendo referencia a la mayoria de edad
    // realmente no se va a utilizar ya que el valor se recoge de la variable edad

        bool Medad;  
        address cartera;

    // utilización de funciones set y get para cada tipo de variable diferente

    function getName() public view returns (string memory) {
        return name;
    }
    function setName(string memory Pname) public {
        name = Pname;
    }

    function getEdad() external view returns (uint) {
        return edad;
    }

    function setEdad(uint Pedad) external {
        edad = Pedad;
    }

    function getCartera() external view returns (address) {
        return cartera;
    }

    function setCartera(address Pcartera) external {
        cartera = Pcartera;
    }

    function getMayoredad() external view returns (bool) {
        if (edad >= 18) {
        return true;
                }                   
        return false;

    
    
    }

       

}