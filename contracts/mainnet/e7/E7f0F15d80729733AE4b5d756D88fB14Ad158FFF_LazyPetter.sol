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
  GotchiLendingFacet private glf;

  constructor(address payable _pokeMe, address gotchiDiamond, address _gotchiOwner) PokeMeReady(_pokeMe) {
    af = AavegotchiFacet(gotchiDiamond);
    agf = AavegotchiGameFacet(gotchiDiamond);
    glf = GotchiLendingFacet(gotchiDiamond);
    gotchiOwner = _gotchiOwner;
  }

  function petGotchis() external onlyPokeMe {
    require(
      ((block.timestamp - lastExecuted) > 43200),
      "LazyPetter: pet: 12 hours not elapsed"
    );

    uint32[] memory gotchis = af.tokenIdsOfOwner(gotchiOwner);
    GotchiLending[] memory activeRentalGotchis = glf.getOwnerGotchiLendings(gotchiOwner, bytes32("active"), 150);

    uint256[] memory gotchiIds = new uint256[](gotchis.length + activeRentalGotchis.length);
    for (uint i = 0; i < gotchis.length; i++) {
      gotchiIds[i] = uint256(gotchis[i]);
    }
    for (uint i = 0; i < activeRentalGotchis.length; i++) {
      gotchiIds[i] = uint256(activeRentalGotchis[i].erc721TokenId);
    }
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