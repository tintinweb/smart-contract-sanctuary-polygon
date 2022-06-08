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
  function ownerOf(uint256 _tokenId) external view returns (address owner_);
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
  uint32 public gotchisUnderManagement;

  LendingParameters[] public lendingParameters;

  mapping (uint32 => uint) gotchiUnchanneledLendingParametersIndex;
  mapping (uint32 => uint) gotchiChanneledLendingParametersIndex;

  mapping (uint32 => bool) isGotchiUnchanneledLendingParametersSet;
  mapping (uint32 => bool) isGotchiChanneledLendingParametersSet;

  constructor(address payable _pokeMe, address gotchiDiamond, address realmDiamond, address _gotchiOwner) PokeMeReady(_pokeMe) {
    af = AavegotchiFacet(gotchiDiamond);
    glf = GotchiLendingFacet(gotchiDiamond);
    lgsf = LendingGetterAndSetterFacet(gotchiDiamond);
    alchemicaFacet = AlchemicaFacet(realmDiamond);

    gotchiOwner = _gotchiOwner;

    gotchiIds.push(24428);
    gotchiIds.push(11963);
    gotchiIds.push(15296);

    gotchisUnderManagement = 3;

    address[] memory revenueTokens = new address[](4);
    revenueTokens[0] = 0x403E967b044d4Be25170310157cB1A4Bf10bdD0f;
    revenueTokens[1] = 0x44A6e0BE76e1D9620A7F76588e4509fE4fa8E8C8;
    revenueTokens[2] = 0x6a3E7C3c6EF65Ee26975b12293cA1AAD7e1dAeD2;
    revenueTokens[3] = 0x42E5E06EF5b90Fe15F853F59299Fc96259209c5C;

    LendingParameters memory unchanneledRates = LendingParameters(
      0.0 ether,
      3600 * 1,
      revenueTokens,
      5362,
      [55, 45, 0],
      address(0)
    );
    lendingParameters.push(unchanneledRates);

    LendingParameters memory channeledRates = LendingParameters(
      0.1 ether,
      3600 * 4,
      revenueTokens,
      0,
      [24, 75, 1],
      0xE237122dbCA1001A9A3c1aB42CB8AE0c7bffc338
    );
    lendingParameters.push(channeledRates);

    gotchiUnchanneledLendingParametersIndex[24428] = 0;
    gotchiUnchanneledLendingParametersIndex[11963] = 0;
    gotchiUnchanneledLendingParametersIndex[15296] = 0;

    isGotchiUnchanneledLendingParametersSet[24428] = true;
    isGotchiUnchanneledLendingParametersSet[11963] = true;
    isGotchiUnchanneledLendingParametersSet[15296] = true;

    gotchiChanneledLendingParametersIndex[24428] = 1;
    gotchiChanneledLendingParametersIndex[11963] = 1;
    gotchiChanneledLendingParametersIndex[15296] = 1;

    isGotchiChanneledLendingParametersSet[24428] = true;
    isGotchiChanneledLendingParametersSet[11963] = true;
    isGotchiChanneledLendingParametersSet[15296] = true;
  }

  function addGotchiIds(uint32[] calldata _gotchiIds) external {
    require(msg.sender == gotchiOwner);
    require(_gotchiIds.length > 0);
    for (uint i = 0; i < _gotchiIds.length; i++) {
      require(msg.sender == af.ownerOf(_gotchiIds[i]));
      gotchiIds.push(_gotchiIds[i]);
      gotchisUnderManagement++;
      isGotchiUnchanneledLendingParametersSet[_gotchiIds[i]] = false;
      isGotchiChanneledLendingParametersSet[_gotchiIds[i]] = false;
    }
  }

  // returns a list all of the Gotchi IDs managed by the automated lender
  function getGotchiIds() public view returns(uint32[] memory) {
    return gotchiIds;
  }

  function getGotchiLendingParameters(uint32 gotchiId) public view returns(LendingParameters[] memory) {
    LendingParameters[] memory gotchiLendingParameters = new LendingParameters[](2);
    if (isGotchiChanneledLendingParametersSet[gotchiId]) {
      gotchiLendingParameters[0] = lendingParameters[gotchiUnchanneledLendingParametersIndex[gotchiId]];
    }
    if (isGotchiChanneledLendingParametersSet[gotchiId]) {
      gotchiLendingParameters[1] = lendingParameters[gotchiChanneledLendingParametersIndex[gotchiId]];
    }

    return lendingParameters;
  }

  function addLendingParameters(uint96 _initialCost, uint32 _period, address[] calldata _revenueTokens, uint32 _whitelistId, uint8[3] calldata _revenueSplit, address _thirdParty) external {
    lendingParameters.push(LendingParameters(
      _initialCost,
      _period,
      _revenueTokens,
      _whitelistId,
      _revenueSplit,
      _thirdParty
    ));
  }

  function setGotchiLendingParameters(uint32 _gotchiId, bool _unchanneled, uint _lendingParametersIndex) external {
    require(msg.sender == gotchiOwner);
    if (_unchanneled) {
      gotchiUnchanneledLendingParametersIndex[_gotchiId] = _lendingParametersIndex;
      isGotchiUnchanneledLendingParametersSet[_gotchiId] = true;
    } else {
      gotchiChanneledLendingParametersIndex[_gotchiId] = _lendingParametersIndex;
      isGotchiChanneledLendingParametersSet[_gotchiId] = true;
    }
  }

  function removeGotchi(uint32 _gotchiId) external {
    require(msg.sender == gotchiOwner);
    require(gotchiIds.length >= 1);
    isGotchiUnchanneledLendingParametersSet[_gotchiId] = false;
    isGotchiChanneledLendingParametersSet[_gotchiId] = false;
    uint index = 0;
    for (uint i = 0; i < gotchiIds.length; i++) {
      if (gotchiIds[i] == _gotchiId) {
        index = i;
      }
    }
    for (uint i = index; i < gotchiIds.length - 1; i++) {
      gotchiIds[i] = gotchiIds[i+1];
    }
    gotchiIds.pop();
  }

  function lendGotchis() external onlyPokeMe {
    uint lended = 0;

    for (uint i = 0; i < gotchiIds.length; i++) {
      uint32 gotchiId = gotchiIds[i];
      if (isGotchiUnchanneledLendingParametersSet[gotchiId] && isGotchiChanneledLendingParametersSet[gotchiId]) {
        bool isListed = lgsf.isAavegotchiListed(gotchiId);
        bool isLent = lgsf.isAavegotchiLent(gotchiId);
        bool isExpired = false;

        LendingParameters memory gotchiLendingParameters = lendingParameters[gotchiChanneledLendingParametersIndex[gotchiId]];
        uint gotchiLastChanneledDay = alchemicaFacet.getLastChanneled(gotchiId) / (60 * 60 * 24);
        uint currentDay = (block.timestamp + gotchiLendingParameters.period) / (60 * 60 * 24);
        if (currentDay > gotchiLastChanneledDay) {
          gotchiLendingParameters = lendingParameters[gotchiUnchanneledLendingParametersIndex[gotchiId]];
        }

        if (!isListed) {
          AddGotchiListing memory addGotchiListing = AddGotchiListing(
            gotchiId,
            gotchiLendingParameters.initialCost,
            gotchiLendingParameters.period,
            gotchiLendingParameters.revenueSplit,
            gotchiOwner,
            gotchiLendingParameters.thirdParty,
            gotchiLendingParameters.whitelistId,
            gotchiLendingParameters.revenueTokens
          );

          lended++;

          glf.addGotchiListing(addGotchiListing);
        } else {
          // gotchi is listed
          if (isLent) {
            GotchiLending memory lending = lgsf.getGotchiLendingFromToken(gotchiId);
            if ((lending.timeAgreed + lending.period) <= block.timestamp) {
              isExpired = true;
              lended++;
              glf.claimAndEndGotchiLending(gotchiId);

              AddGotchiListing memory addGotchiListing = AddGotchiListing(
                gotchiId,
                gotchiLendingParameters.initialCost,
                gotchiLendingParameters.period,
                gotchiLendingParameters.revenueSplit,
                gotchiOwner,
                gotchiLendingParameters.thirdParty,
                gotchiLendingParameters.whitelistId,
                gotchiLendingParameters.revenueTokens
              );
              glf.addGotchiListing(addGotchiListing);
            }
          }
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