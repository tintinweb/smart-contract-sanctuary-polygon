/**
 *Submitted for verification at polygonscan.com on 2022-11-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract PlanNutricionalSA{
    
    mapping(string => planNutricional) listPlan;

    struct planNutricional{
        string idDeportista;
        string _hashPlanAlimenticio;
    }
       
    function crearPlanAlimenticioSA(string memory idDeportista, string memory hashPlanAlimenticio)public {
        listPlan[idDeportista] = planNutricional(idDeportista, hashPlanAlimenticio);
    }

    function consultarPlanNutricionalSA(string memory idDeportista) public view returns (planNutricional memory plan){
        return listPlan[idDeportista];
    }
    
}