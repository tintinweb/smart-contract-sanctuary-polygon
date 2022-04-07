/**
 *Submitted for verification at polygonscan.com on 2022-04-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract GasPriceTest  {
  event GasInfoSent(uint256 gasPrice, uint256 baseFee, uint256 blockNum);

  function doit() external returns (bool) {
    emit GasInfoSent(tx.gasprice, block.basefee, block.number );
    return true;
  }

}