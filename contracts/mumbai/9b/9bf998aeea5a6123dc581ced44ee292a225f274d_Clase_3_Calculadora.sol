/**
 *Submitted for verification at polygonscan.com on 2022-08-26
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract Clase_3_Calculadora {    

    int num1=0;
    int num2=0;
    uint feed= 0.0000001 ether;

    //Ingrese los numeros con que decee operar
    function setNum(int NewNum1,int NewNum2) external{
        num1=NewNum1;
        num2=NewNum2;}

    //SUMA
    function sum() external payable returns (int){
        if(msg.value>= feed){
            int Sumatoria = num1+num2;
            return  Sumatoria;}}
        
    //RESTA
    function resta() external payable returns (int){
        if(msg.value>= feed){
            int Restar= num1-num2;
            return Restar;}}

    //MULTIPLICACION
        
    function multi() external payable returns (int){
        if(msg.value>= feed){
            int Multiplicar= num1*num2;
            return Multiplicar;}}

    //MODULO    
    
    function div() external payable returns (int){
        if(msg.value>=feed){
            int divicion= num1*num2;
            return divicion;}}
}