/**
 *Submitted for verification at polygonscan.com on 2022-08-19
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract Clase_2 {
    string Name= "Daniel E. Rodriguez";
    address Theaddress=0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    bool x;
    uint BalanceMATIC= 655;
  
    function getMyName() external view returns (string memory){
        return Name;
    }
    function setNewName(string memory NewName) external{
        Name=NewName;
    }
    function getTheaddress()external view returns (address){
        return Theaddress;
    }
    function setTheaddress (address Newaddress) external{
        Theaddress=Newaddress;
    }
    function getBalanceMATIC() external view returns (uint){
        return BalanceMATIC;
    }
    function setBalanceMATIC(uint Newbalance) external{
        BalanceMATIC=Newbalance;
    }
    function getPancakeaddress()external view returns (bool,string memory ){
        if (Theaddress==0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82) {
            return (true, "Este es el contrato de la criptomoneda de pancake(CAKE)");}
        
        else if (Theaddress!=0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82){
            return (false, "No se recono el contrato");}
        
    }
}