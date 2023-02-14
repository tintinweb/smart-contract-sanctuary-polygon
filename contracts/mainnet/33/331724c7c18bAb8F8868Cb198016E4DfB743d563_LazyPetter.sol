// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import { PokeMeReady } from "./PokeMeReady.sol";

interface AavegotchiFacet {
  function tokenIdsOfOwner(address _owner) external view returns (uint32[] memory tokenIds_);
}

interface AavegotchiGameFacet {
  function interact(uint256[] calldata _tokenIds) external;
}

struct GotchiLending {
    // storage slot 1
    address lender;
    uint96 initialCost; // GHST in wei, can be zero
    // storage slot 2
    address borrower;
    uint32 listingId;
    uint32 erc721TokenId;
    uint32 whitelistId; // can be zero
    // storage slot 3
    address originalOwner; // if original owner is lender, same as lender
    uint40 timeCreated;
    uint40 timeAgreed;
    bool canceled;
    bool completed;
    // storage slot 4
    address thirdParty; // can be address(0)
    uint8[3] revenueSplit; // lender/original owner, borrower, thirdParty
    uint40 lastClaimed; //timestamp
    uint32 period; //in seconds
    // storage slot 5
    address[] revenueTokens;
}

interface GotchiLendingFacet {
  function getOwnerGotchiLendings(address _lender, bytes32 _status, uint256 _length) external view returns (GotchiLending[] memory listings_) ;
}

contract LazyPetter {
  uint256 public lastExecuted;
  address private gotchiOwner;
  AavegotchiFacet private af;
  AavegotchiGameFacet private agf;
  uint256[] private gotchiIds;
  // GotchiLendingFacet private glf;
  address private authorizedExecutor;

  constructor(address _authorizedExecutor, address gotchiDiamond, address _gotchiOwner) {
    af = AavegotchiFacet(gotchiDiamond);
    agf = AavegotchiGameFacet(gotchiDiamond);
    // glf = GotchiLendingFacet(gotchiDiamond);
    gotchiOwner = _gotchiOwner;

    authorizedExecutor = _authorizedExecutor;

    gotchiIds = [
      // tier 1
      // 6912, 8256, 6342, 820, 7030, 9685, 5702, 8364, 7026, 2967, 6257, 3201, 2674, 5514, 5516, 6169, 185, 8634, 5017

      // tier 2
      // 13974, 20952, 16980, 12628, 14046, 13676, 19784, 12593, 14437, 12532, 10221, 15427, 18989, 17957,15328,16925,17821,16368,11093,12555,14817,15351,19263,18465,15603,14537,19411,20897,12652,14805
      
      // tier 3
      // 20601,21141,18013,13102,21048,17495,15079,24941,24935,24936,23309,23098,24564,23861,24004,22929,23918,24004,24564,22934,10055,23085,23591,23810,24561,24561,17443,18812,22530,24559,13608,19943,21586,10566

      // tier 4 (needs refresh)
      22518,
      22710,
      10531,
       13344, 15522,
       24428,
      20279,
      11405,
       21728,
       24138, 
      17617, 11293,
      14675, 13879, 13209, 11963,
      23864, 23496, 19819,
      16324, 22103, 13502, 23721, 22518,
      23897

      // sold
      // 22921, 10755, 22561, 2987, 14999, 22392, 12220, 24806, 11345, 16876
      // 14160, 11408, 18594, 22580, 15672, 13785, 14055, 20469, 16206, 14357
      // 23689, 15296, 10273, 24803, 18365, 20058, 12771, 14913, 12797, 15542
    ];
  }

  // function setGotchiIds(uint[] memory _gotchiIds) external {
  //   require(msg.sender == gotchiOwner);
  //   gotchiIds = _gotchiIds;
  // }

  function petGotchis() external {
    require(msg.sender == authorizedExecutor, "Not authorised to execute");
    require(
      ((block.timestamp - lastExecuted) > 43200),
      "LazyPetter: pet: 12 hours not elapsed"
    );

    // uint32[] memory gotchis = af.tokenIdsOfOwner(gotchiOwner);
    // GotchiLending[] memory activeRentalGotchis = glf.getOwnerGotchiLendings(gotchiOwner, bytes32("active"), 150);

    // uint256[] memory gotchiIds = new uint256[](gotchis.length + activeRentalGotchis.length);
    // for (uint i = 0; i < gotchis.length; i++) {
    //   gotchiIds[i] = uint256(gotchis[i]);
    // }

    // for (uint i = 0; i < activeRentalGotchis.length; i++) {
    //   gotchiIds[i] = uint256(activeRentalGotchis[i].erc721TokenId);
    // }
    agf.interact(gotchiIds);

    lastExecuted = block.timestamp;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

abstract contract PokeMeReady {
  address payable public immutable pokeMe;

  constructor(address payable _pokeMe) {
    pokeMe = _pokeMe;
  }

  modifier onlyPokeMe() {
    require(msg.sender == pokeMe, "PokeMeReady: onlyPokeMe");
    _;
  }
}