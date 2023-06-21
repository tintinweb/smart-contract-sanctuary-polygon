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
pragma solidity ^0.8.0;

import "./IFunctionInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract COEHelper {
  address public wAEGAddress;
  address[] public allowedTokens;
  uint256 public waegPrice;
  mapping(address => AggregatorV3Interface) private priceFeeds;
  mapping(address => bool) private isAuthed;

  constructor(
    AggregatorV3Interface _usdcPriceFeed,
    address _usdcToken,
    AggregatorV3Interface _usdtPriceFeed,
    address _usdtToken
  ) {
    isAuthed[msg.sender] = true;
    editPaymentTokenByAddress(_usdcPriceFeed, _usdcToken);
    editPaymentTokenByAddress(_usdtPriceFeed, _usdtToken);
    waegPrice = 45e15;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   * @param _totalCost fixed point with 3 decimal places in USD
   * @param _tokenAddress address of the token to use for payment
   * @param _userAddress address of the user purchasing
   */

  function purchaseWithToken(
    uint256 _totalCost,
    address _tokenAddress,
    address _userAddress
  ) public onlyAuthed {
    require(_tokenAddress != address(0), "Invalid token address");
    uint price;

    uint decimals = FunctionInterface(_tokenAddress).decimals();
    uint256 convertedCost = (_totalCost * 10 ** decimals) / 1000;

    if (_tokenAddress == wAEGAddress) {
      price = waegPrice;
    } else {
      require(checkAllowedToken(_tokenAddress), "Token for pay not supported.");

      uint priceFeedDecimals = priceFeeds[_tokenAddress].decimals();

      price = convertPriceToTokenDecimals(
        getPrice(_tokenAddress),
        decimals,
        priceFeedDecimals
      );
    }

    require(price > 0, "Invalid token price");

    AEGInterface(_tokenAddress).transferFrom(
      _userAddress,
      address(this),
      (convertedCost / price) * 10 ** decimals
    );
  }

  // ----------------- GETTERS -----------------

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

  function getPrice(address _tokenAddress) private view returns (uint256) {
    (, int price, , , ) = priceFeeds[_tokenAddress].latestRoundData();
    return uint256(price);
  }

  // ----------------- SETTERS -----------------

  function editPaymentTokenByAddress(
    AggregatorV3Interface _priceFeedAddress,
    address _tokenAddress
  ) public onlyAuthed {
    priceFeeds[_tokenAddress] = AggregatorV3Interface(_priceFeedAddress);
    if (!checkAllowedToken(_tokenAddress)) {
      allowedTokens.push(_tokenAddress);
    }
  }

  function removePaymentToken(address _tokenAddress) public onlyAuthed {
    delete priceFeeds[_tokenAddress];
    if (checkAllowedToken(_tokenAddress)) {
      for (uint256 i = 0; i < allowedTokens.length; i++) {
        if (allowedTokens[i] == _tokenAddress) {
          delete allowedTokens[i];
        }
      }
    }
  }

  function setWaegPrice(uint256 _waegPrice) public onlyAuthed {
    waegPrice = _waegPrice;
  }

  function setWaegAddress(address _waegAddress) public onlyAuthed {
    wAEGAddress = _waegAddress;
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

  function convertPriceToTokenDecimals(
    uint256 price,
    uint256 tokenDecimals,
    uint256 priceFeedDecimals
  ) private pure returns (uint256) {
    uint256 priceInTokenDecimals;

    if (tokenDecimals > priceFeedDecimals) {
      priceInTokenDecimals =
        price *
        (10 ** (tokenDecimals - priceFeedDecimals));
    } else if (tokenDecimals < priceFeedDecimals) {
      priceInTokenDecimals =
        price /
        (10 ** (priceFeedDecimals - tokenDecimals));
    } else {
      priceInTokenDecimals = price;
    }

    return priceInTokenDecimals;
  }

  // ----------------- WITHDRAW -----------------

  function withdrawEth() public onlyAuthed {
    payable(msg.sender).transfer(address(this).balance);
  }

  function withdrawToken(address _tokenAddress) public onlyAuthed {
    FunctionInterface(_tokenAddress).transfer(
      msg.sender,
      AEGInterface(_tokenAddress).balanceOf(address(this))
    );
  }

  // ----------------- MODIFIERS -----------------

  modifier onlyAuthed() {
    require(isAuthed[msg.sender], "Not authorized to helper.");
    _;
  }

  function editAuthed(address _address, bool _isAuthed) public onlyAuthed {
    isAuthed[_address] = _isAuthed;
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