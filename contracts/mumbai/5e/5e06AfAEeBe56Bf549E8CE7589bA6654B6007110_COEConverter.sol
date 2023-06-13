// SPDX-License-Identifier: MIT
// solhint-disable-next-line
pragma solidity ^0.8.0;

import "./IFunctionInterface.sol";

contract COEConverter {
  address public aegToken;
  address public cards;
  address public ethernals;
  address public adventurers;
  address public emotes;

  event ConvertedCards(
    address indexed _assetAddress,
    address indexed _userAddress,
    uint256[] _ids,
    uint256[] _amounts
  );

  // address _emotes
  constructor(
    address _aegToken,
    address _cards,
    address _ethernals,
    address _adventurers
  ) {
    aegToken = _aegToken;
    cards = _cards;
    ethernals = _ethernals;
    adventurers = _adventurers;
    // emotes = _emotes;
    roles[OWNER][msg.sender] = true;
    roles[ADMIN][msg.sender] = true;
  }

  function convertAssets(
    address _assetAddress,
    address _userAddress,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    uint256 _price, // (ex. 45 = $0.045, 500 = $0.5, 1000 = $1, 10000 = $10) //SEND CALCULATED PRICE
    bool _sb
  ) external onlyRole(ADMIN) {
    require(_ids.length == _amounts.length, "Invalid input");
    //see if user hase enough aeg tokens to convert, including amounts of each type
    // uint256 totalPrice;
    // for (uint256 i = 0; i < _ids.length; i++) {
    //   totalPrice += _amounts[i] * _prices[i];
    // }

    //convert prices to aeg assuming aeg is .045 cents per token and has 18 decimals MAYBE DON"T EVEN CONVERT HERE AND DO BEFORE SENDING
    uint256 convertedPrice = (_price * 10 ** 18 * 1000) / 45; // THOUSANDTHS :: we multiply by 1000 to get the decimals right and divide by 45 to get the price in aeg at .045 cents per token

    //tranfer AEG/wAEG from user to this contrac
    require(
      AEGInterface(aegToken).balanceOf(_userAddress) >= convertedPrice,
      "Not enough AEG tokens"
    );

    // Transfer the AEG tokens from the user to the contract
    // THIES IS WRONG, WE CAN'T SEND TOKENS FROM THE USER FROM ADMIN WALLET
    AEGInterface(aegToken).transferFrom( // TODO: NEED TO CHECK HOW WE WILL DO CONVERSION PRICES
      _userAddress,
      address(this),
      convertedPrice
    );

    for (uint256 i = 0; i < _ids.length; i++) {
      _convertAsset(_assetAddress, _userAddress, _ids[i], _amounts[i], _sb);
    }

    emit ConvertedCards(_assetAddress, _userAddress, _ids, _amounts);
  }

  function _convertAsset(
    address _assetAddress,
    address _userAddress,
    uint256 _type,
    uint256 _amount,
    bool _sb
  ) private {
    //detrmine which contract to convert to, ethernals, adventurers, cards or emotes
    if (_assetAddress == ethernals) {
      // TODO: check for that one special ethernal???
    } else if (_assetAddress == adventurers) {
      //TODO: check for FRODO???
    } else if (_assetAddress == emotes) {
      //
    } else if (_assetAddress == cards) {
      //check that none are promo cards
      uint256[] memory promoCards = CardInterface(cards).promoTypes();
      for (uint256 j = 0; j < promoCards.length; j++) {
        require(_type != promoCards[j], "Cannot convert promo cards");
      }
    } else {
      revert("Invalid asset address");
    }

    NftInterface(_assetAddress).adminMint(_userAddress, _type, 1, _amount, _sb);
  }

  // ---------------------------- SETTERS ----------------------------

  function setAegToken(address _aegToken) external onlyRole(OWNER) {
    aegToken = _aegToken;
  }

  // ACCESS CONTROL ----------------------------

  mapping(bytes32 => mapping(address => bool)) private roles;
  bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
  bytes32 private constant OWNER = keccak256(abi.encodePacked("OWNER"));

  modifier onlyRole(bytes32 role) {
    require(roles[role][msg.sender], "Not authorized to converter.");
    _;
  }

  function grantRole(bytes32 role, address account) public onlyRole(OWNER) {
    roles[role][account] = true;
  }

  function revokeRole(bytes32 role, address account) public onlyRole(OWNER) {
    roles[role][account] = false;
  }

  function transferOwnershipp(address newOwner) external onlyRole(OWNER) {
    grantRole(OWNER, newOwner);
    grantRole(ADMIN, newOwner);
    revokeRole(OWNER, msg.sender);
    revokeRole(ADMIN, msg.sender);
  }
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line
pragma solidity ^0.8.0;

import "./Library.sol";

interface AEGInterface {
  function balanceOf(address) external view returns (uint256);

  function transferFrom(address, address, uint256) external;
}

interface NftInterface {
  function adminMint(
    address _to,
    uint256 _type,
    uint256 _level,
    uint256 _amount,
    bool _sb
  ) external;

  function ownerOf(uint256) external view returns (address);

  function totalTypes() external view returns (uint256);
}

interface CardInterface {
  function packMint(address, uint256[] memory, bool) external;

  function promoTypes() external view returns (uint256[] memory);

  function getRarityToCardTypes(
    Library.Rarity
  ) external view returns (uint256[] memory);
}

interface FunctionInterface {
  function fpMint(address, uint256, uint256) external;

  function burn(uint256) external;

  function totalTokens() external view returns (uint256);

  function transfer(address, uint256) external;

  function decimals() external view returns (uint8);

  function purchaseWithToken(uint256, address, address) external;

  function trim(
    uint256,
    uint256[] memory
  ) external pure returns (uint256[] memory);

  function burn(address, uint256, uint256) external;

  function balanceOf(address, uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line
pragma solidity ^0.8.0;

library Library {
  enum Rarity {
    Basic,
    Common,
    Uncommon,
    Rare,
    Epic,
    Legendary
  }

  // struct Card {
  //   uint256 id;
  //   uint256 mintCount;
  //   uint256 burnCount;
  //   uint256 season;
  //   string uri;
  //   Rarity rarity;
  //   bool paused;
  //   bool exists;
  //   bool isPromo;
  // }
}