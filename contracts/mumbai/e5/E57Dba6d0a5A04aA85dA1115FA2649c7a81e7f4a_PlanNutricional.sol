/**
 *Submitted for verification at polygonscan.com on 2022-11-24
*/

pragma solidity ^0.8.3;

contract PlanNutricional{
   
    mapping(int => planNutricional) listPlan;

    struct planNutricional{
        int idDeportista;
        string descripcion;
    }

    constructor(){
       
    } 

    function getPlanNutricional(int idDeportista) public view returns (planNutricional memory plan){
        return listPlan[idDeportista];
    }

    function setPlanByIdDeportista (int idDeportista, string memory descripcion) public{
        listPlan[idDeportista] = planNutricional(idDeportista, descripcion);
    } 

}