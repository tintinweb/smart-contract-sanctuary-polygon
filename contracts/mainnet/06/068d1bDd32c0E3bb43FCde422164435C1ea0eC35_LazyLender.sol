// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import { PokeMeReady } from "./PokeMeReady.sol";

struct AddGotchiListing {
    uint32 tokenId;
    uint96 initialCost;
    uint32 period;
    uint8[3] revenueSplit;
    address originalOwner;
    address thirdParty;
    uint32 whitelistId;
    address[] revenueTokens;
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

interface AavegotchiFacet {
  function tokenIdsOfOwner(address _owner) external view returns (uint32[] memory tokenIds_);
}

interface GotchiLendingFacet {
  function getOwnerGotchiLendings(address _lender, bytes32 _status, uint256 _length) external view returns (GotchiLending[] memory listings_);
  function batchClaimAndEndAndRelistGotchiLending(uint32[] calldata _tokenIds) external;
  function batchAddGotchiListing(AddGotchiListing[] memory listings) external;
}

interface LendingGetterAndSetterFacet {
  function isAavegotchiLent(uint32 _erc721TokenId) external view returns (bool);
  function isAavegotchiListed(uint32 _erc721TokenId) external view returns (bool);
  function getGotchiLendingFromToken(uint32 _erc721TokenId) external view returns (GotchiLending memory listing_);
}

contract LazyLender is PokeMeReady {
  AavegotchiFacet private af;
  GotchiLendingFacet private glf;
  LendingGetterAndSetterFacet private lgsf;

  uint256 public lastExecuted;

  address public gotchiOwner;
  uint32[] public gotchiIds;

  // lending parameters
  uint96 public initialCost;
  uint32 public period;
  address[] public revenueTokens;
  uint32 public whitelistId;
  uint8[3] public revenueSplit;
  address public thirdParty;

  constructor(address payable _pokeMe, address gotchiDiamond, address _gotchiOwner) PokeMeReady(_pokeMe) {
    af = AavegotchiFacet(gotchiDiamond);
    glf = GotchiLendingFacet(gotchiDiamond);
    lgsf = LendingGetterAndSetterFacet(gotchiDiamond);

    gotchiOwner = _gotchiOwner;

    gotchiIds.push(11408);
    initialCost = 0.01 ether;
    period = 180;
    revenueTokens = [0x403E967b044d4Be25170310157cB1A4Bf10bdD0f, 0x44A6e0BE76e1D9620A7F76588e4509fE4fa8E8C8, 0x6a3E7C3c6EF65Ee26975b12293cA1AAD7e1dAeD2, 0x42E5E06EF5b90Fe15F853F59299Fc96259209c5C];
    whitelistId = 0;
    revenueSplit = [90, 5, 5];
    thirdParty = 0xE237122dbCA1001A9A3c1aB42CB8AE0c7bffc338;
  }

  function addGotchiIds(uint32[] calldata _gotchiIds) external {
    require(msg.sender == gotchiOwner);
    for (uint i = 0; i < _gotchiIds.length; i++) {
      gotchiIds.push(_gotchiIds[i]);
    }
  }

  function setLendingParameters(uint96 _initialCost, uint32 _period, address[] calldata _revenueTokens, uint32 _whitelistId, uint8[3] calldata _revenueSplit, address _thirdParty) external {
    require(msg.sender == gotchiOwner);
    initialCost = _initialCost;
    period = _period;
    revenueTokens = _revenueTokens;
    whitelistId = _whitelistId;
    revenueSplit = _revenueSplit;
    thirdParty = _thirdParty;
  }

  function lendGotchis() external onlyPokeMe {
    bool isListed = lgsf.isAavegotchiListed(gotchiIds[0]);
    bool isLent = lgsf.isAavegotchiLent(gotchiIds[0]);
    bool isExpired = false;

    if (!isListed) {
      AddGotchiListing[] memory addGotchiRelistings = new AddGotchiListing[](1);
      addGotchiRelistings[0] = AddGotchiListing(
        gotchiIds[0],
        initialCost,
        period,
        revenueSplit,
        gotchiOwner,
        thirdParty,
        whitelistId,
        revenueTokens
      );

      glf.batchAddGotchiListing(addGotchiRelistings);
    } else {
      // gotchi is listed
      if (isLent) {
        GotchiLending memory lending = lgsf.getGotchiLendingFromToken(gotchiIds[0]);
        if ((lending.timeAgreed + lending.period) >= block.timestamp) {
          isExpired = true;
          uint32[] memory relistGotchis = new uint32[](1);
          relistGotchis[0] = gotchiIds[0];
          glf.batchClaimAndEndAndRelistGotchiLending(relistGotchis);
        }
      }
    }

    require(isListed == false || isExpired == true);


    // require(
    //   ((block.timestamp - lastExecuted) > 900),
    //   "LazyLender: lendGotchis - 15 minutes not elapsed"
    // );
    //
    // uint32[] storage gotchiIdsToList;
    // uint32[] storage gotchiIdsToRelist;
    // for (uint i = 0; i < gotchiIds.length; i++) {
    //   if (!lgsf.isAavegotchiListed(gotchiIds[i])) {
    //     gotchiIdsToList.push(gotchiIds[i]);
    //   } else {
    //     // if gotchi lent
    //     if (lgsf.isAavegotchiLent(gotchiIds[i])) {
    //       GotchiLending memory lending = lgsf.getGotchiLendingFromToken(gotchiIds[i]);
    //       if ((lending.timeAgreed + lending.period) >= block.timestamp) {
    //         // gotchi expired
    //         gotchiIdsToRelist.push(gotchiIds[i]);
    //       }
    //     }
    //   }
    // }
    //
    // require(
    //   (gotchiIdsToList.length > 0 || gotchiIdsToRelist.length > 0),
    //   "LazyLender: no gotchis to lend"
    // );
    //
    // if (gotchiIdsToList.length > 0) {
    //   AddGotchiListing[] memory addGotchiRelistings = new AddGotchiListing[](gotchiIdsToList.length);
    //
    //   for (uint i = 0; i < gotchiIdsToList.length; i++) {
    //     addGotchiRelistings[i] = AddGotchiListing(
    //       gotchiIdsToList[i],
    //       initialCost,
    //       period,
    //       revenueSplit,
    //       gotchiOwner,
    //       thirdParty,
    //       whitelistId,
    //       revenueTokens
    //     );
    //   }
    //
    //   glf.batchAddGotchiListing(addGotchiRelistings);
    // }
    //
    // if (gotchiIdsToRelist.length > 0) {
    //   glf.batchClaimAndEndAndRelistGotchiLending(gotchiIdsToRelist);
    // }

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