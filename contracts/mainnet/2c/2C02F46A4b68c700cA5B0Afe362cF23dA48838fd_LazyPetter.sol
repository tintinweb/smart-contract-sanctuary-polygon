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

contract LazyPetter is PokeMeReady {
  uint256 public lastExecuted;
  address private gotchiOwner;
  AavegotchiFacet private af;
  AavegotchiGameFacet private agf;
  uint256[] private gotchiIds;
  // GotchiLendingFacet private glf;

  constructor(address payable _pokeMe, address gotchiDiamond, address _gotchiOwner) PokeMeReady(_pokeMe) {
    af = AavegotchiFacet(gotchiDiamond);
    agf = AavegotchiGameFacet(gotchiDiamond);
    // glf = GotchiLendingFacet(gotchiDiamond);
    gotchiOwner = _gotchiOwner;

    gotchiIds = [
      18365
      // 20058
      // 21141, 10531, 15672,
      //  2674, 12797, 18013, 13344, 15522, 23689, 20897,  6912, 23861,
      //  5702,  8634, 24564, 24428,  5514, 14817, 23309, 20952, 24935,
      // 17443, 20279, 20601, 19784, 16925, 16368, 23810, 12652, 14805,
      // 14160, 13974, 11405, 18989, 19411, 12628, 19263, 24941, 18465,
      // 19943, 15603, 17495,   185,  6342,   820,  7030,  8364,  8256,
      //  9685,  5516,  7026,  6257,  6169,  2967, 21728,  5017, 23098,
      //  3201, 18594, 24138, 24004, 23918, 22921, 14046, 13676, 16980,
      // 17957, 17617, 15542, 14913, 11293, 17821, 14537, 15427, 15328,
      // 14675, 15351, 13879, 13785, 13209, 11963, 12593, 11093, 10221,
      // 12532, 11408, 12555, 23864, 13608, 23496, 19819, 14437, 22530,
      // 10566, 16324, 15296, 22103, 20469, 14357, 13502, 21586, 23721,
      // 15079, 13102, 23085, 21048, 10055, 23591, 22934, 24936, 24559,
      // 24561, 18812, 22929,
      // 2987
    ];
  }

  // function setGotchiIds(uint[] memory _gotchiIds) external {
  //   require(msg.sender == gotchiOwner);
  //   gotchiIds = _gotchiIds;
  // }

  function petGotchis() external onlyPokeMe {
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