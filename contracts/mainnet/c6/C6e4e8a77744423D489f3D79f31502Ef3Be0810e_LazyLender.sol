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

struct LendingParameters {
  uint96 initialCost;
  uint32 period;
  address[] revenueTokens;
  uint32 whitelistId;
  uint8[3] revenueSplit;
  address thirdParty;
}

interface AavegotchiFacet {
  function tokenIdsOfOwner(address _owner) external view returns (uint32[] memory tokenIds_);
}

interface GotchiLendingFacet {
  function getOwnerGotchiLendings(address _lender, bytes32 _status, uint256 _length) external view returns (GotchiLending[] memory listings_);
  function batchClaimAndEndAndRelistGotchiLending(uint32[] calldata _tokenIds) external;
  function batchAddGotchiListing(AddGotchiListing[] memory listings) external;
  function addGotchiListing(AddGotchiListing memory p) external;
  function claimAndEndAndRelistGotchiLending(uint32 _tokenId) external;
  function claimAndEndGotchiLending(uint32 _tokenId) external;
}

interface LendingGetterAndSetterFacet {
  function isAavegotchiLent(uint32 _erc721TokenId) external view returns (bool);
  function isAavegotchiListed(uint32 _erc721TokenId) external view returns (bool);
  function getGotchiLendingFromToken(uint32 _erc721TokenId) external view returns (GotchiLending memory listing_);
}

interface AlchemicaFacet {
  function getLastChanneled(uint256 _gotchiId) external view returns (uint256);
}

contract LazyLender is PokeMeReady {
  AavegotchiFacet private af;
  GotchiLendingFacet private glf;
  LendingGetterAndSetterFacet private lgsf;
  AlchemicaFacet private alchemicaFacet;

  uint256 public lastExecuted;

  address public gotchiOwner;
  uint32[] public gotchiIds;

  // lending parameters
  LendingParameters public unchanneledLendingParameters;
  LendingParameters public channeledLendingParameters;

  // uint96 public initialCost;
  // uint32 public period;
  // address[] public revenueTokens;
  // uint32 public whitelistId;
  // uint8[3] public revenueSplit;
  // address public thirdParty;

  constructor(address payable _pokeMe, address gotchiDiamond, address realmDiamond, address _gotchiOwner) PokeMeReady(_pokeMe) {
    af = AavegotchiFacet(gotchiDiamond);
    glf = GotchiLendingFacet(gotchiDiamond);
    lgsf = LendingGetterAndSetterFacet(gotchiDiamond);
    alchemicaFacet = AlchemicaFacet(realmDiamond);

    gotchiOwner = _gotchiOwner;

    gotchiIds.push(11408);

    address[] memory revenueTokens = new address[](4);
    revenueTokens[0] = 0x403E967b044d4Be25170310157cB1A4Bf10bdD0f;
    revenueTokens[1] = 0x44A6e0BE76e1D9620A7F76588e4509fE4fa8E8C8;
    revenueTokens[2] = 0x6a3E7C3c6EF65Ee26975b12293cA1AAD7e1dAeD2;
    revenueTokens[3] = 0x42E5E06EF5b90Fe15F853F59299Fc96259209c5C;

    unchanneledLendingParameters = LendingParameters(
      0.8 ether,
      3600 * 1,
      revenueTokens,
      // 4968,
      0,
      // [20, 70, 10],
      [0, 100, 0],
      // 0xE237122dbCA1001A9A3c1aB42CB8AE0c7bffc338
      address(0)
    );

    channeledLendingParameters = LendingParameters(
      0.1 ether,
      3600 * 4,
      revenueTokens,
      // 4967,
      0,
      // [30, 60, 10],
      [24, 75, 1],
      0xE237122dbCA1001A9A3c1aB42CB8AE0c7bffc338
    );

    // initialCost = 0.1 ether;
    // period = 3600 * 4;
    // revenueTokens = [0x403E967b044d4Be25170310157cB1A4Bf10bdD0f, 0x44A6e0BE76e1D9620A7F76588e4509fE4fa8E8C8, 0x6a3E7C3c6EF65Ee26975b12293cA1AAD7e1dAeD2, 0x42E5E06EF5b90Fe15F853F59299Fc96259209c5C];
    // whitelistId = 0;
    // revenueSplit = [24, 75, 1];
    // thirdParty = 0xE237122dbCA1001A9A3c1aB42CB8AE0c7bffc338;
  }

  function addGotchiIds(uint32[] calldata _gotchiIds) external {
    require(msg.sender == gotchiOwner);
    for (uint i = 0; i < _gotchiIds.length; i++) {
      gotchiIds.push(_gotchiIds[i]);
    }
  }

  function setLendingParameters(bool unchanneled, uint96 _initialCost, uint32 _period, address[] calldata _revenueTokens, uint32 _whitelistId, uint8[3] calldata _revenueSplit, address _thirdParty) external {
    require(msg.sender == gotchiOwner);
    if (unchanneled) {
      unchanneledLendingParameters = LendingParameters(
        _initialCost,
        _period,
        _revenueTokens,
        _whitelistId,
        _revenueSplit,
        _thirdParty
      );
    } else {
      channeledLendingParameters = LendingParameters(
        _initialCost,
        _period,
        _revenueTokens,
        _whitelistId,
        _revenueSplit,
        _thirdParty
      );
    }
    // initialCost = _initialCost;
    // period = _period;
    // revenueTokens = _revenueTokens;
    // whitelistId = _whitelistId;
    // revenueSplit = _revenueSplit;
    // thirdParty = _thirdParty;
  }

  function lendGotchis() external onlyPokeMe {
    bool isListed = lgsf.isAavegotchiListed(gotchiIds[0]);
    bool isLent = lgsf.isAavegotchiLent(gotchiIds[0]);
    bool isExpired = false;
    uint lended = 0;

    LendingParameters memory lendingParamters = channeledLendingParameters;
    uint gotchiLastChanneledDay = alchemicaFacet.getLastChanneled(gotchiIds[0]) / (60 * 60 * 24);
    uint currentDay = block.timestamp / (60 * 60 * 24);
    if (currentDay > gotchiLastChanneledDay) {
      lendingParamters = unchanneledLendingParameters;
    }

    uint32 gotchiId = gotchiIds[0];
    if (!isListed) {
      AddGotchiListing memory addGotchiListing = AddGotchiListing(
        gotchiId,
        lendingParamters.initialCost,
        lendingParamters.period,
        lendingParamters.revenueSplit,
        gotchiOwner,
        lendingParamters.thirdParty,
        lendingParamters.whitelistId,
        lendingParamters.revenueTokens
      );

      lended++;

      glf.addGotchiListing(addGotchiListing);
    } else {
      // gotchi is listed
      if (isLent) {
        GotchiLending memory lending = lgsf.getGotchiLendingFromToken(gotchiIds[0]);
        if ((lending.timeAgreed + lending.period) <= block.timestamp) {
          isExpired = true;
          lended++;
          glf.claimAndEndGotchiLending(gotchiId);

          AddGotchiListing memory addGotchiListing = AddGotchiListing(
            gotchiId,
            lendingParamters.initialCost,
            lendingParamters.period,
            lendingParamters.revenueSplit,
            gotchiOwner,
            lendingParamters.thirdParty,
            lendingParamters.whitelistId,
            lendingParamters.revenueTokens
          );
          glf.addGotchiListing(addGotchiListing);
        }
      }
    }

    require(
      (lended > 0),
      "LazyLender: At least one Gotchi must be lended or relisted"
    );

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