// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line
pragma solidity ^0.8.0;

import "./Library.sol";
import "./IFunctionInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// import "@openzeppelin/contracts/access/Ownable.sol";

contract COEHelper {
  // address public packs;
  address public aegAddress;
  address[] public allowedTokens;
  mapping(address => AggregatorV3Interface) public priceFeeds;

  mapping(address => bool) public isAuthed;

  constructor(
    address _aegAddress,
    AggregatorV3Interface _usdcPriceFeed,
    address _usdcToken,
    AggregatorV3Interface _usdtPriceFeed,
    address _usdtToken
  ) {
    isAuthed[msg.sender] = true;
    aegAddress = _aegAddress;
    addPaymentToken(_usdcPriceFeed, _usdcToken);
    addPaymentToken(_usdtPriceFeed, _usdtToken);
  }

  modifier onlyAuthed() {
    require(isAuthed[msg.sender], "Not authorized.");
    _;
  }

  function editAuthed(address _address, bool _isAuthed) public onlyAuthed {
    isAuthed[_address] = _isAuthed;
  }

  function purchaseWithToken(
    uint256 _totalCost, //in USD from the pack struct * amount of packs purchasing
    address _tokenAddress, //address of the token to use for payment
    address _userAddress //address of the user purchasing
  ) public onlyAuthed {
    //if token is AEG, check if user has enough AEG and transfer to this contract
    if (_tokenAddress == aegAddress) {
      FunctionInterface(_tokenAddress).transferFrom(
        _userAddress,
        msg.sender,
        _totalCost
      );
      return;
    }

    require(
      // _tokenAddress != address(0) &&
      checkAllowedToken(_tokenAddress),
      "Token for pay not supported."
    );

    (, int price, , , ) = priceFeeds[_tokenAddress].latestRoundData();

    // require(price > 0, "Invalid token price");

    uint256 tokenAmount = (_totalCost *
      10 ** FunctionInterface(_tokenAddress).decimals()) / uint256(price);

    FunctionInterface(_tokenAddress).transferFrom(
      msg.sender,
      address(this),
      tokenAmount
    );
  }

  function checkAllowedToken(
    address _tokenAddress
  ) private view returns (bool) {
    for (uint256 i = 0; i < allowedTokens.length; i++) {
      if (allowedTokens[i] == _tokenAddress) {
        return true;
      }
    }
    return false;
  }

  // ----------------- ADD -----------------

  function addPaymentToken(
    AggregatorV3Interface _priceFeedAddress,
    address _tokenAddress
  ) public onlyAuthed {
    // Create a new AggregatorV3Interface instance for the price feed
    AggregatorV3Interface priceFeed = AggregatorV3Interface(_priceFeedAddress);

    // Add the price feed and token to the mapping and array
    priceFeeds[_tokenAddress] = priceFeed;
    allowedTokens.push(_tokenAddress);
  }

  // ----------------- OTHER -----------------

  function trim(
    uint _count,
    uint[] memory _cardIds
  ) public pure returns (uint[] memory) {
    uint256[] memory trimmed = new uint256[](_count);
    for (uint256 i = 0; i < _count; i++) {
      trimmed[i] = _cardIds[i];
    }
    return trimmed;
  }
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line
pragma solidity ^0.8.0;

import "./Library.sol";

interface AEGInterface {
  function balanceOf(address) external view returns (uint256);
}

interface FunctionInterface {
  // function tokenOfOwnerByIndex(address, uint256)
  //   external
  //   view
  //   returns (uint256);

  function fpMint(address, uint256, uint256) external;

  function fpMintBasic(address) external;

  function packInfo(uint256) external view returns (Library.CardPack memory);

  function burn(uint256) external;

  function totalTokens() external view returns (uint256);

  function getPromoCardIds() external view returns (uint256[] memory);

  function randomPrice() external view returns (uint256);

  function transfer(address, uint256) external;

  function transferFrom(address, address, uint256) external;

  function decimals() external view returns (uint8);

  function purchaseWithToken(uint256, address, address) external;

  function trim(
    uint256,
    uint256[] memory
  ) external pure returns (uint256[] memory);

  function mintBatch(
    address, //address to mint to
    uint256[] memory, // token ids
    uint256[] memory // amounts
  ) external; //mint cards

  function burn(address, uint256, uint256) external;

  function balanceOf(address, uint256) external view returns (uint256);

  function getCardRarityPercentages(
    uint256
  ) external view returns (uint256[] memory);

  function getCardCount(uint256) external view returns (uint32);

  // function getCardsOfRarityAndTypes(
  //   Library.Rarity rarity,
  //   Library.CardType[] memory cardTypes
  // ) external view returns (uint256[] memory);

  function getCardsOfRarityTypeRaceElement(
    Library.Rarity rarity,
    Library.CardType[] memory cardTypes,
    Library.Race[] memory race,
    Library.Element[] memory element
  ) external view returns (uint256[] memory);

  function getCardIdsOfRarity(
    Library.Rarity rarity
  ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./IFunctionInterface.sol";

library Library {
  enum Rarity {
    Basic,
    Common,
    Uncommon,
    Rare,
    Epic,
    Legendary
  }

  enum Race {
    None,
    Demon,
    Beast,
    Elemental,
    Fairy,
    Troll,
    Dragon
  }

  enum Element {
    Fire,
    Water,
    Earth,
    Air,
    Ice,
    Thunder,
    Nature,
    Chaos,
    Light
  }

  enum CardType {
    Creature,
    Spell,
    Relic
  }

  struct Card {
    uint256 id;
    uint256 mintCount;
    uint256 burnCount;
    uint256 price;
    uint256 season;
    string uri;
    Rarity rarity;
    Library.CardType cardType;
    Library.Race race;
    Library.Element element;
    bool paused;
    bool exists;
    bool isPromo;
  }

  struct CardPack {
    uint256 maxSupply;
    uint256 mintCount;
    uint256 price;
    uint256 cardCount; //number of cards in pack
    uint256 burnCount; //number of cards that have been burned
    uint256[] rarityAllocations; //amount of each rarity in pack ex. [0, 6, 3, 2, 1, 3] // this should be as long as the number of rarities // THE LAST NUMBER IS THE PERCENT CHANCE OF REPLACING A RARE WITH A LEGENDARY
    Race[] races;
    Element[] elements;
    uint256 season; //season of pack
    string uri;
    bool paused;
    PackType packType;
    bool exists;
    // mapping(Rarity => uint256) rarityAllocationsMap;
    // mapping(RaceElementTypes => bool) raceElementTypesMap;
  }

  enum PackType {
    Basic,
    Any,
    Creatures,
    Spells_Relics
  }

  struct NewTokenData {
    uint256 id;
    uint256 price;
    uint256 maxSupply;
    uint256 cardCount;
    uint256[] rarityAllocations;
    Race[] races;
    Element[] elements;
    PackType packType;
    uint256 season;
    string uri;
  }

  // function trim(
  //   uint _count,
  //   uint[] memory _cardIds
  // ) internal pure returns (uint[] memory) {
  //   uint256[] memory trimmed = new uint256[](_count);
  //   for (uint256 i = 0; i < _count; i++) {
  //     trimmed[i] = _cardIds[i];
  //   }
  //   return trimmed;
  // }

  // function _trim(
  //   uint256 _count,
  //   uint256[] memory _cardIds
  // ) private pure returns (uint256[] memory) {
  //   uint256[] memory trimmed = new uint256[](_count);
  //   for (uint256 i = 0; i < _count; i++) {
  //     trimmed[i] = _cardIds[i];
  //   }
  //   return trimmed;
  // }

  // function checkAllowedToken(
  //   address _tokenAddress,
  //   address[] memory allowedTokens
  // ) private pure returns (bool) {
  //   for (uint256 i = 0; i < allowedTokens.length; i++) {
  //     if (allowedTokens[i] == _tokenAddress) {
  //       return true;
  //     }
  //   }
  //   return false;
  // }

  // function getTokenAmountFromUSD(
  //   uint256 _usdCost,
  //   address _tokenAddress,
  //   address _priceFeedAddress
  // ) private view returns (uint256) {
  //   AggregatorV3Interface priceFeed = AggregatorV3Interface(_priceFeedAddress);

  //   require(address(priceFeed) != address(0), "Unsupported token");
  //   (, int price, , , ) = priceFeed.latestRoundData();

  //   require(price > 0, "Invalid token price");

  //   return (_usdCost * FunctionInterface(_tokenAddress).decimals()) / uint256(price);
  // }

  // function getLatestPrice(
  //   AggregatorV3Interface _priceFeed
  // ) private view returns (int) {
  //   require(address(_priceFeed) != address(0), "Unsupported token");

  //   (, int price, , , ) = _priceFeed.latestRoundData();
  //   return price;
  // }

  // function purchaseWithToken(
  //   uint256 _totalCost, //in USD from the pack struct * amount of packs purchasing
  //   address _tokenAddress, //address of the token to use for payment
  //   address[] memory _allowedTokens,
  //   AggregatorV3Interface _priceFeedAddress,
  //   address _aegAddress,
  //   address _user,
  //   address _contractAddress
  // ) internal {
  //   _purchaseWithToken(
  //     _totalCost,
  //     _tokenAddress,
  //     _allowedTokens,
  //     _priceFeedAddress,
  //     _aegAddress,
  //     _user,
  //     _contractAddress
  //   );
  // }

  // function purchaseWithToken(
  //   uint256 _totalCost, //in USD from the pack struct * amount of packs purchasing
  //   address _tokenAddress, //address of the token to use for payment
  //   address[] storage _allowedTokens,
  //   AggregatorV3Interface _priceFeedAddress,
  //   address _aegAddress // address _user, // address _contractAddress
  // ) internal {
  //   //if token is AEG, check if user has enough AEG and transfer to this contract
  //   if (_tokenAddress == _aegAddress) {
  //     FunctionInterface(_tokenAddress).transferFrom(
  //       msg.sender,
  //       address(this),
  //       _totalCost
  //     );
  //     return;
  //   }

  //   require(
  //     // _tokenAddress != address(0) &&
  //     checkAllowedToken(_tokenAddress, _allowedTokens),
  //     "Token for pay not supported."
  //   );

  //   (, int price, , , ) = _priceFeedAddress.latestRoundData();

  //   // require(price > 0, "Invalid token price");

  //   uint256 tokenAmount = (_totalCost *
  //     FunctionInterface(_tokenAddress).decimals()) / uint256(price);

  //   FunctionInterface(_tokenAddress).transferFrom(
  //     msg.sender,
  //     address(this),
  //     tokenAmount
  //   );
  // }

  // function addNewPack(
  //   // mapping(uint256 => CardPack) storage _tokens,
  //   // uint256 _totalTokens,
  //   NewTokenData memory _data,
  //   address _owner,
  //   bool _exists
  // ) external pure returns (CardPack memory) {
  //   require(_owner != address(0), "Invalid owner address");

  //   CardPack memory newToken;
  //   newToken.maxSupply = _data.maxSupply;
  //   newToken.price = _data.price;
  //   newToken.cardCount = _data.cardCount;
  //   newToken.rarityAllocations = _data.rarityAllocations;
  //   newToken.races = _data.races;
  //   newToken.elements = _data.elements;
  //   newToken.season = _data.season;
  //   newToken.uri = _data.uri;
  //   newToken.packType = _data.packType;

  //   if (!_exists) {
  //     newToken.paused = false;
  //     newToken.burnCount = 0;
  //     newToken.mintCount = 0;
  //     newToken.exists = true;
  //     // _totalTokens++;
  //   }

  //   return newToken;
  // }
}