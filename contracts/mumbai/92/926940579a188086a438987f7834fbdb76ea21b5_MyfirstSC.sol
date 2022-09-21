/**
 *Submitted for verification at polygonscan.com on 2022-09-20
*/

//EJERCICIO 1. Escribir un SC y desplegarlo

//Primera línea --> SPDX... (la podemos copiar desde default). Incicar la licencia del SC (MIT)
// SPDX-License-Identifier: MIT

//Ponemos la versión de solidity en la que vamos a escribir el SC. 
//Debe coincidir con la versión del compilador (si no queremos rango, no debe tener signos). La línea acaba en ";"
pragma solidity 0.8.17;

//A continuación, comenzamos a escribir el SC. La palabra reservada (se marca en azul) es "contract"
//El nombre debe comenzar con mayúsculas y es conveniente que sea lo más parecido posible al fichero .sol
//Añadimos llaves para indicar lo que va dentro del SC
contract MyfirstSC {
    //Aquí irá el código del SC
}

//Después, compilamos (debajo de la lupa). Es buena practica complilar (CRTL+s) con cada línea

//Una vez que el compilador no nos da errores, para desplegar, vamos al icono de ETH
//Elegimos el entorno LONDON para probar cosas dentro de nuestro ordenador
//Elegimos "injected provider" para interactuar con metamask y la red de pruebas MUMBAI
//Después, configuramos el GAS LIMIT (se paga, pero luego se devuelve)

//Pulsamos el botón DEPLOY para desplegar nuestro SC dentro de la red MUMBAI. IMPORTANTE: hay que tener MATIC, 
//ya que estamos modificando una blockchain, y hay que pagar gas