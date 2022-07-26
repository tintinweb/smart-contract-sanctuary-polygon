/**
 *Submitted for verification at polygonscan.com on 2022-07-25
*/

////////
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
* @title Storage
* @dev Store & retrieve value in a variable
*/


contract TSC {



uint kforn = 12; // costo in co2 dell produzioine de trasporto di carbonato di calcio
uint klimenet = 30; // costo in co2 della produzione di idrossido e sottoprodotti
uint ktxidrossido = 3; // costo in co2 del trasporto da limenet alla salina
string data_caco3 = "23/05/2022"; // data consegna lotto
uint t_bic = 0;// tonnellate di bicarbonato di risulta dalla reazione
uint caoh2 = 0; // idrossido di risulta dalla reazione
//uint ktot = 0;
function store_t_bic(uint256 QT) public {
t_bic=QT;
}

function ktotview() public view returns (uint k_tot){
k_tot = kforn + klimenet + ktxidrossido;
return k_tot;
}

function ValT_bic() public view returns (uint256){
return t_bic;
}

}