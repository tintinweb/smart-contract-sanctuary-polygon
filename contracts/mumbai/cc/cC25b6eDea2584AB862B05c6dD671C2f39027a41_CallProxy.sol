/**
 *Submitted for verification at polygonscan.com on 2022-07-01
*/

pragma solidity 0.8.13;
// SPDX-License-Identifier: UNLICENSED

interface PlayerCoinInterface{
  function buyTokenOnBehalfOf(address beneficiaryWalletAddress) external payable;
  function currentState() external view returns (uint8);

}

contract CallProxy {
  function callMeCarreiraContract(address _playerContract, address _buyOnBehalf) public payable {
      // minimum 1000 wei
      require (msg.value >= 2000000000000000000,"Minimum 2 MATIC required");
      PlayerCoinInterface playerContract = PlayerCoinInterface(_playerContract);
      // check if in subscription
      uint8 state = playerContract.currentState();
      // fail if not in subscription
      require (state==1,"Contract not in subscription");
      

      uint256 val=0;
      uint256 matic=0;

      if (address(_buyOnBehalf).balance < 1000000000000000000) {
        // deduct 1 Matic to be sent to buyer to be later used as fee
        val = msg.value - 1000000000000000000;
        matic = msg.value - val;
        // send matic to buyer
        payable(_buyOnBehalf).transfer(matic);
      } else {
        // entire MATIC amount to be sent into contract
        val = msg.value;
      }
      // fire the token purchase
      playerContract.buyTokenOnBehalfOf{value: val}(_buyOnBehalf);
  }
}