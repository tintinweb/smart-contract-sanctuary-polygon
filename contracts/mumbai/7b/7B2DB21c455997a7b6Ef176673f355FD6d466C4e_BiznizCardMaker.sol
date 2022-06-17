/**
 *Submitted for verification at polygonscan.com on 2022-06-16
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

  contract BiznizCardMaker {
      // all are going to be set to uuid value in smart contract, so declare as same type
    struct BiznizCard {
      string f_name;
      string l_name;
      string wallet_address;
    }

    BiznizCard[] biznizCards; // array of all binizCards

    function _createBiznizCard (string memory _uuid) public {
      biznizCards.push(BiznizCard({
        f_name: _uuid,
        l_name: _uuid,
        wallet_address: _uuid
      }));
    }
  }