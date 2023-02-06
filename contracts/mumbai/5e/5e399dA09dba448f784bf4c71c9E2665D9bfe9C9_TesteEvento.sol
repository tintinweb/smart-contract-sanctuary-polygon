// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract TesteEvento {
   
   event ResultadoPositivo(int256 resultado, string mensagem);
   event ResultadoNegativo(int256 resultado, string mensagem);
   event ResultadoZerado(string mensagem);
   event FuncaoFinalizada(string mensagem);

   constructor() {}

    function Soma(int256 numeroA, int256 numeroB) public returns (int256 resultado){

      int256 _resultado = numeroA + numeroB;

      if(_resultado > 0)
      {
        emit ResultadoPositivo(_resultado, "Retorno positivo");
      }

      if(_resultado < 0)
      {
        emit ResultadoNegativo(_resultado, "Retorno negativo");
      }

      if(_resultado == 0)
      {
        emit ResultadoZerado("Retorno zerado");
      }
      
      emit FuncaoFinalizada("OK");

      return _resultado;

    }
}