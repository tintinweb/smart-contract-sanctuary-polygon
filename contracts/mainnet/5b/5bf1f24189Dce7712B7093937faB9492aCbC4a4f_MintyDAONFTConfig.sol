/**
 *Submitted for verification at polygonscan.com on 2022-11-30
*/

pragma solidity ^0.8.11;

contract MintyDAONFTConfig {

  address public platformToken;
  address public router;
  address public OpenSeaRegistry;

  constructor(
    address _platformToken,
    address _router,
    address _OpenSeaRegistry
    )
  {
    platformToken = _platformToken;
    router = _router;
    OpenSeaRegistry = _OpenSeaRegistry;
  }
}