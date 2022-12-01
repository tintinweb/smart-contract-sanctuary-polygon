// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./4. Interfaces/IPresale.sol";
import "./4. Interfaces/IRadikalStore.sol";
import "./4. Interfaces/IPresaleRidersFactory.sol";
import "./4. Interfaces/IPresaleRecipesFactory.sol";
import "./4. Interfaces/IRidersFactory.sol";
import "./4. Interfaces/IRecipesFactory.sol";
import "./4. Interfaces/ICollectionRiders.sol";
import "./4. Interfaces/ICollectionRecipes.sol";
import "./4. Interfaces/ICollectionPizzerias.sol";
import "./4. Interfaces/IMarketPlace.sol";
import "./4. Interfaces/IPVPStorage.sol";
import "./4. Interfaces/IRewardPool.sol"; 
import "./4. Interfaces/IPriceOracle.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Lens of Radikal data
/// @author Radikal Riders
/// @notice unique point with all methods needed to fetch important on chain Radikal Riders data
/// @dev API like contract with relevant Radikal Riders data. Front-end interacts with this smart contracts to read on-chain data
contract RadikalLens is Ownable {

  struct MysteryBoxes {
    uint mysteryBoxId;
    uint topType;
    bool hasRiders;
    bool hasRecipes;
    uint statusRiders;
    uint statusRecipes;
    uint riderChainlinkFee;
    uint recipeChainlinkFee;
  }
  
  struct RecipeLen {
    uint recipeId;
    uint16 tipPower;
    bool inPizzeria;
    string tokenURI;
  }
  struct PizzeriaLen {
    uint pizzeriaId;
    uint16 tipPower;
		uint pizzaQuantity;
		uint claimCounter;
		bool retirementFlag;
		bool isSpecial;
    uint favouriteRider;
		ICollectionRiders.RidersAttributes[] ridersList;
		RecipeLen[] recipeList;
    string tokenURI;
    uint balance;
    uint ingredientDays;
    uint lastDeliveryTime;
  }
  struct MarketPlaceRiderLen {
    uint itemId;
		address nft;
		uint tokenId;
		uint price;
		address payable seller;
		bool sold;
    ICollectionRiders.RidersAttributes mktRiderLen;
  }
  struct MarketPlaceRecipeLen {
    uint itemId;
		address nft;
		uint tokenId;
		uint price;
		address payable seller;
		bool sold;
    RecipeLen mktRecipeLen;
  }
  struct MarketPlacePizzeriaLen {
    uint itemId;
		address nft;
		uint tokenId;
		uint price;
		address payable seller;
		bool sold;
    PizzeriaLen mktPizzeriaLen;
  }

  struct constructorAddresses {
    address presaleAddress;
    address radikalStoreInstanceAddress;
    address presaleRidersFactoryAddress;
    address presaleRecipesFactoryAddress;
    address ridersFactoryAddress;
    address recipeFactoryAddress;
    address collectionRidersAddress;
    address collectionRecipesAddress;
    address collectionPizzeriasAddress;
    address marketPlaceAddress;
    address rewardPoolAddress;
    address pvpStorageAddress;
    address oraclePriceAddress;
  }

  address collectionRidersAddress;
  address collectionRecipesAddress;
  address collectionPizzeriasAddress;
  address markePlaceAddress;

  IPresale presaleInstance;
  IRadikalStore radikalStoreInstance;
  IPresaleRidersFactory presaleRidersFactoryInstance;
  IPresaleRecipesFactory presaleRecipesFactoryInstance;
  IRidersFactory ridersFactoryInstance;
  IRecipesFactory recipeFactoryInstance;
  ICollectionRiders ridersInstance;
  ICollectionRecipes recipeInstance;
  ICollectionPizzerias pizzeriasInstance;
  IMarketPlace marketPlaceInstance;
  IPVPStorage pvpStorageInstance;
  IRewardPool rewardPoolInstance;
  IPriceOracle priceOracleInstance;

  constructor(
    RadikalLens.constructorAddresses memory _addressInit
  ) {
    presaleInstance = IPresale(_addressInit.presaleAddress);
    radikalStoreInstance = IRadikalStore(_addressInit.radikalStoreInstanceAddress);
    presaleRidersFactoryInstance = IPresaleRidersFactory(_addressInit.presaleRidersFactoryAddress);
    presaleRecipesFactoryInstance = IPresaleRecipesFactory(_addressInit.presaleRecipesFactoryAddress);
    ridersFactoryInstance = IRidersFactory(_addressInit.ridersFactoryAddress);
    recipeFactoryInstance = IRecipesFactory(_addressInit.recipeFactoryAddress);
    ridersInstance = ICollectionRiders(_addressInit.collectionRidersAddress);
    recipeInstance = ICollectionRecipes(_addressInit.collectionRecipesAddress);
    pizzeriasInstance = ICollectionPizzerias(_addressInit.collectionPizzeriasAddress);
    marketPlaceInstance = IMarketPlace(_addressInit.marketPlaceAddress);
    rewardPoolInstance = IRewardPool(_addressInit.rewardPoolAddress);
    pvpStorageInstance = IPVPStorage(_addressInit.pvpStorageAddress);
    priceOracleInstance = IPriceOracle(_addressInit.oraclePriceAddress);
    collectionRidersAddress = _addressInit.collectionRidersAddress;
    collectionRecipesAddress = _addressInit.collectionRecipesAddress;
    collectionPizzeriasAddress = _addressInit.collectionPizzeriasAddress;
    markePlaceAddress = _addressInit.marketPlaceAddress;
  }

  /********************************************************
   *                                                      *
   *                    ADMIN FUNCTIONS                   *
   *                                                      *
   ********************************************************/

  /// @notice Define price oracle interface
  /// @dev Should only be updated if liquidity is included in different pools or exchanges
  /// @param _priceOracleAddress MarketPlaceRadikals contract address
  function setPriceOracle(address _priceOracleAddress) external onlyOwner {
    priceOracleInstance = IPriceOracle(_priceOracleAddress);
  }

  /********************************************************
   *                                                      *
   *                    VIEW FUNCTIONS                    *
   *                                                      *
   ********************************************************/

  /// @notice returns mystery box related information for a user 
  /// @dev only useful for presale data. Front-end team is the main consumer of this
  /// @param user user to be checked
  function getMysteryBoxes(address user) external view returns (
    MysteryBoxes[] memory
    ) {
    uint[] memory _mysteryBoxes = presaleInstance.getAddressToMysteryBoxes(user);
    uint boxesLength = _mysteryBoxes.length;
    MysteryBoxes[] memory mysteryBoxes = new MysteryBoxes[](boxesLength);
    for(uint i = 0; i < boxesLength; i++ ) {
      (uint topType, uint riderCounter, , uint recipeCounter) = presaleInstance.getPresaleCounter(user, _mysteryBoxes[i]);
      mysteryBoxes[i] = MysteryBoxes(
      _mysteryBoxes[i],
      topType,
      riderCounter > 0,
      recipeCounter > 0,
      presaleRidersFactoryInstance.getMintingState(_mysteryBoxes[i]),
      presaleRecipesFactoryInstance.getMintingState(_mysteryBoxes[i]),
      presaleInstance.getRiderQuantityToChainLinkFee(riderCounter),
      presaleInstance.getRecipeQuantityToChainLinkFee(recipeCounter)
      );
    }
    return mysteryBoxes;
  }

  /// @notice returns the rider minting state for regular RidersFactory contract
  /// @dev consumed by front-end team to guide user in the rider minting flow
  function getRiderMintingState(address _user) external view returns(uint) {
    return ridersFactoryInstance.getMintingState(_user);
  }

  /// @notice returns the recipe minting state for regular RecipeFactory contract
  /// @dev consumed by front-end team to guide user in the recipe minting flow
  function getRecipesMintingState(address _user) external view returns(uint) {
    return recipeFactoryInstance.getMintingState(_user);
  }

  /// @notice Retrieve all info related to your riders
  /// @dev consumed by front-end to display all the riders of a user
  /// @param consumerAddress address of user to check riders
  function getRiderLen(address consumerAddress) public view returns(ICollectionRiders.RidersAttributes[] memory) {
    uint[] memory userRiders = ridersInstance.getRiderList(consumerAddress);
    return ridersInstance.getAttributes(userRiders);
  }

  /// @notice Retrieve all info related to your recipe
  /// @dev consumed by front-end to display all the recipe of a user
  /// @param consumerAddress address of user to check recipe
  function getRecipeLen(address consumerAddress) public view returns(RecipeLen[] memory) {
    uint[] memory userRecipes = recipeInstance.getRecipeList(consumerAddress);
    return _getRecipeListToRecipeLenList(userRecipes);
  }

  /// @notice Retrieve all info related to your pizzerias
  /// @dev consumed by front-end to display all the pizzerias of a user
  /// @param consumerAddress address of user to check pizzerias
  function getPizzeriaLen(address consumerAddress) public view returns(PizzeriaLen[] memory) {
    uint[] memory userPizzerias = pizzeriasInstance.getPizzeriasList(consumerAddress);
    uint pizzeriasLength = userPizzerias.length;
    ICollectionPizzerias.PizzeriasAttributes[] memory pizzeriasAttributes = pizzeriasInstance.getAttributes(userPizzerias);
    PizzeriaLen[] memory pizzeriaLen = new PizzeriaLen[](pizzeriasLength);
    for(uint i = 0; i < pizzeriasLength; i++) {
      pizzeriaLen[i] = PizzeriaLen(
        userPizzerias[i],
        pizzeriasAttributes[i].tipPower,
        pizzeriasAttributes[i].pizzaQuantity,
        pizzeriasAttributes[i].claimCounter,
        pizzeriasAttributes[i].retirementFlag,
        pizzeriasAttributes[i].isSpecial,
        pizzeriasAttributes[i].favouriteRider,
        _getRiderListToRiderLenList(pizzeriasAttributes[i].ridersList),
        _getRecipeListToRecipeLenList(pizzeriasAttributes[i].recipeList), 
        pizzeriasInstance.getTokenURI(userPizzerias[i]),
        rewardPoolInstance.getPizzeriaBalance(userPizzerias[i]),
        rewardPoolInstance.getPizzeriaIngredients(userPizzerias[i]),
        rewardPoolInstance.getLastDeliveryTime(userPizzerias[i])
      );
    }
    return pizzeriaLen;
  }

  /// @dev Retrieve all info related Riders available in the market place
  function getMarketPlaceRiderLen() external view returns(MarketPlaceRiderLen[] memory) {
    IMarketPlace.Item[] memory mktPlaceRiders = marketPlaceInstance.getNftToItems(collectionRidersAddress);
    uint mktPlaceRidersLength = mktPlaceRiders.length;
    ICollectionRiders.RidersAttributes[] memory riderLen = getRiderLen(markePlaceAddress);
    MarketPlaceRiderLen[] memory marketPlaceRiderLen = new MarketPlaceRiderLen[](mktPlaceRidersLength);
    for(uint i = 0; i < mktPlaceRidersLength; i++) {
      marketPlaceRiderLen[i] = MarketPlaceRiderLen(
        mktPlaceRiders[i].itemId,
        mktPlaceRiders[i].nft,
        mktPlaceRiders[i].tokenId,
        mktPlaceRiders[i].price,
        mktPlaceRiders[i].seller,
        mktPlaceRiders[i].sold,
        riderLen[i]
      );
    }
    return marketPlaceRiderLen;
  }

  /// @dev Retrieve all info related Recipes available in the market place
  function getMarketPlaceRecipeLen() external view returns(MarketPlaceRecipeLen[] memory) {
    IMarketPlace.Item[] memory mktPlaceRecipes = marketPlaceInstance.getNftToItems(collectionRecipesAddress);
    uint mktPlaceRecipesLength = mktPlaceRecipes.length;
    RecipeLen[] memory recipeLen = getRecipeLen(markePlaceAddress);
    MarketPlaceRecipeLen[] memory marketPlaceRecipeLen = new MarketPlaceRecipeLen[](mktPlaceRecipesLength);
    for(uint i = 0; i < mktPlaceRecipesLength; i++) {
      marketPlaceRecipeLen[i] = MarketPlaceRecipeLen(
        mktPlaceRecipes[i].itemId,
        mktPlaceRecipes[i].nft,
        mktPlaceRecipes[i].tokenId,
        mktPlaceRecipes[i].price,
        mktPlaceRecipes[i].seller,
        mktPlaceRecipes[i].sold,
        recipeLen[i]
      );
    }
    return marketPlaceRecipeLen;
  }

  /// @dev Retrieve all info related Pizzeria available in the market place
  function getMarketPlacePizzeriaLen() external view returns(MarketPlacePizzeriaLen[] memory) {
    IMarketPlace.Item[] memory mktPlacePizzerias = marketPlaceInstance.getNftToItems(collectionPizzeriasAddress);
    uint mktPlacePizzeriasLength = mktPlacePizzerias.length;
    PizzeriaLen[] memory pizzeriaLen = getPizzeriaLen(markePlaceAddress);
    MarketPlacePizzeriaLen[] memory marketPlacePizzeriaLen = new MarketPlacePizzeriaLen[](mktPlacePizzeriasLength);
    for(uint i = 0; i < mktPlacePizzeriasLength; i++) {
      marketPlacePizzeriaLen[i] = MarketPlacePizzeriaLen(
        mktPlacePizzerias[i].itemId,
        mktPlacePizzerias[i].nft,
        mktPlacePizzerias[i].tokenId,
        mktPlacePizzerias[i].price,
        mktPlacePizzerias[i].seller,
        mktPlacePizzerias[i].sold,
        pizzeriaLen[i]
      );
    }
    return marketPlacePizzeriaLen;
  }

  /// @dev Retrieve all PVP races information
  function getAllPVPRaces() external view returns(IPVPStorage.Race[] memory, ICollectionRiders.RidersAttributes[][] memory riders) {
    return pvpStorageInstance.getAllRaces();
  }

  /// @dev Retrieve all jackpots by buyin from PVP
  function getPVPBuyinAndJackpots() external view returns(uint16[] memory, uint[] memory) {
    return pvpStorageInstance.getBuyinAndJackpots(); 
  }

  /// @dev Retrieve top 5 claimed jackpots
  function getPVPTopFiveJackpots() external view returns(uint[5] memory) {
    return pvpStorageInstance.getPVPTopFiveJackpots(); 
  }

  /// @notice Exchange from usdt to token
  /// @param _usdtQuantity it has 2 decimals. E.g: 2,00 $ -> the input should be 200
  /// @return tokenQuantity the token quantity is returned in wei (18 decimal places)
  function getUsdtToToken(uint _usdtQuantity) external view returns (uint) {
    return priceOracleInstance.getUsdtToToken(_usdtQuantity);
  }

  /// @notice Exchange from usdt to token
  /// @param _tokenQuantity Quantity of radikal tokens in wei to convert to Usdt. 18 decimals needed for the token
  /// @return usdtQuantity amount of usdt with 2 digits (e.g. 23,41 -> 2341)
  function getTokenToUsdt(uint _tokenQuantity) external view returns (uint) {
    return priceOracleInstance.getTokenToUsdt(_tokenQuantity);
  }

  /// @notice Matic amount users need to pay to buy a mysterybox. Mysterybox price + chainlinkFee 
  /// @param _mBoxType bottom mystery box type. 0 = LEG30 | 1 = LEG250 | 2 = MYT60 | 3 = MYT500 | 4 = SP75 | 5 = SP1000
  function getPresaleBoxMaticCost(uint _mBoxType) external view returns (uint) {
    return presaleInstance.getPresaleChainLinkFee() + presaleInstance.getTypePrice(_mBoxType);
  }

  /// @dev Matic amount users need to pay for chainlink use. This is used in RewardPool contract
  function getPveChainLinkFee() external view returns(uint) {
    return radikalStoreInstance.getPveChainLinkFee();
  }

  /// @dev Matic amount users need to pay for chainlink use. This is used in PVP contract
  function getPvpChainLinkFee() external view returns(uint) {
    return radikalStoreInstance.getPvpChainLinkFee();
  }

  /// @dev Matic amount users need to pay to buy Riders. Used in RidersFactory contract
  /// @return RiderPackCost cost for each rider pack. packs are: 0: 1 nft | 1: 5 nft | 2: 10 nft | 3: 20 nft
  function getRiderMaticCost() external view returns(uint[] memory) {
    uint8 tokenQuantity;
    uint _riderCost;
    uint _twoPercRiderCost;
    uint _chainLinkCost;
    uint [] memory _RiderPackCost = new uint[](4);
    for (uint8 i = 0; i < 4; i++) {
      tokenQuantity = radikalStoreInstance.getMintingPackToQuantity(i);
      _riderCost = 375 * uint(tokenQuantity) * (10 ** 18) * (10 ** 6) / (uint(priceOracleInstance.getLatestPrice()));
      _twoPercRiderCost = 2 * 375 * uint(tokenQuantity) * (10 ** 18) * (10 ** 6) / ((uint(priceOracleInstance.getLatestPrice())) * 100);
      _chainLinkCost = radikalStoreInstance.getRiderQuantityToChainLinkFee(tokenQuantity);
      _RiderPackCost[i] =  (_riderCost + _twoPercRiderCost ) + _chainLinkCost;
    }
    return _RiderPackCost;
  }

  /// @dev Matic amount users need to pay to buy Recipes. Used in RecipesFactory contract
  /// @return RecipePackCost cost for each recipe pack. packs are: 0: 1 nft | 1: 5 nft | 2: 10 nft | 3: 20 nft
  function getRecipeMaticCost() external view returns(uint[] memory) {
    uint8 tokenQuantity;
    uint _recipeCost;
    uint _twoPercRecipeCost;
    uint _chainLinkCost;
    uint [] memory _RecipePackCost = new uint[](4);
    for (uint8 i = 0; i < 4; i++) {
      tokenQuantity = radikalStoreInstance.getMintingPackToQuantity(i);
      _recipeCost = 375 * uint(tokenQuantity) * (10 ** 18) * (10 ** 6) / (uint(priceOracleInstance.getLatestPrice()));
      _twoPercRecipeCost = 2 * 375 * uint(tokenQuantity) * (10 ** 18) * (10 ** 6) / ( (uint(priceOracleInstance.getLatestPrice())) * 100);
      _chainLinkCost = radikalStoreInstance.getRecipeQuantityToChainLinkFee(tokenQuantity);
      _RecipePackCost[i] = (_recipeCost + _twoPercRecipeCost ) + _chainLinkCost;
    }
    return _RecipePackCost;
  }

  /********************************************************
   *                                                      *
   *                 INTERNAL FUNCTIONS                   *
   *                                                      *
   ********************************************************/

  /// @dev used in getRiderLen and  getPizzeriaLen functions of this contract
  /// @param _riderList list of riders to check
  /// @return RiderLenList list with all riders and their relevant attributes
  function _getRiderListToRiderLenList(uint[] memory _riderList) internal view returns(ICollectionRiders.RidersAttributes[] memory) {
    return ridersInstance.getAttributes(_riderList);
  }

  /// @dev used in getRecipeLen and  getPizzeriaLen functions of this contract
  /// @param _recipeList list of recipe to check
  /// @return RecipeLenList list with all recipe and their relevant attributes
  function _getRecipeListToRecipeLenList(uint[] memory _recipeList) internal view returns(RecipeLen[] memory) {
    uint recipeLength = _recipeList.length;
    RecipeLen[] memory recipeLen = new RecipeLen[](recipeLength);
    for(uint i = 0; i < recipeLength; i++) {
        recipeLen[i] = RecipeLen(
        _recipeList[i],
        recipeInstance.getTipPower(_recipeList[i]),
        recipeInstance.getInPizzeria(_recipeList[i]),
        recipeInstance.getTokenURI(_recipeList[i])
      );
    }
    return recipeLen;
  }
}

// SPDX-License-Identifier: MIT
  pragma solidity ^0.8.0;

  interface IPresale{ 

    struct RiderAttributes {
      uint8 pizzaQuantity;
      uint8[2] wheel;
      uint8[2] fairing;
      uint8[2] clutch;
      uint8[2] exhaustPipe;
      uint8[2] turbo;
      uint8[2] nitro;
    }

    function getRecipeTPRange(uint _bottomLimit) external view returns (uint16);
    function getRecipesBaseURI() external view returns (string memory);
    function getTypePrice(uint _mBoxType) external view returns (uint);
    function getTypeProbability(uint _mBoxType) external view returns (uint[] memory);
    function getRiderAttributes(uint _mBoxType, uint16 _prob) external view returns (RiderAttributes memory attributes);
    function getRecipeAttribute(uint _mBoxType, uint _prob) external view returns (uint16);
    function getPresaleCounter(address _userAddress, uint _mysteryBoxCounter) external view returns (uint, uint, uint, uint);
    function countDown(address _userAddress, uint _mysteryBoxCounter, uint _mBoxType) external;
    function getTypeQuantity(uint _mBoxType) external view returns (uint);
    function getRidersURIs(uint8 _nftRareness) external view returns (string memory, string memory);
    function getBaseURILength(string memory _baseURI) external view returns (uint);  
    function getMotorbikes() external view returns (bytes12 [] memory);
    function getAddressToMysteryBoxes(address _user) external view returns (uint[] memory);
    function getRiderQuantityToChainLinkFee(uint _riderQuantity) external view returns (uint);
    function getRecipeQuantityToChainLinkFee(uint _recipeQuantity) external view returns (uint);
    function getPresaleChainLinkFee() external view returns (uint);
    function getMysteryBoxIdToTopTypeRider(address _user, uint _mysteryBoxId) external view returns (uint _riderTopType);
    function getMysteryBoxIdToTopTypeRecipe(address _user, uint _mysteryBoxId) external view returns (uint _recipeTopType);
  }

// SPDX-License-Identifier: MIT
  pragma solidity ^0.8.0;

  interface IPresaleRecipesFactory {
    function getMintingState(uint _mysteryBoxId) external view returns(uint);
  }

// SPDX-License-Identifier: MIT
  pragma solidity ^0.8.0;

  interface IRidersFactory {
    function getMintingState(address _user) external view returns(uint);
  }

// SPDX-License-Identifier: MIT
  pragma solidity ^0.8.0;

  interface IPresaleRidersFactory {
    function getMintingState(uint _mysteryBoxId) external view returns(uint);
  }

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRadikalStore {

	struct RiderAttributes {
    uint8 pizzaQuantity;
    uint8[2] wheel;
    uint8[2] fairing;
    uint8[2] clutch;
    uint8[2] exhaustPipe;
    uint8[2] turbo;
    uint8[2] nitro;
  }

	// PVE/rewardPool
	function getTipPower() external view returns(uint16 [] memory);
	function getIngredientPackToDays(uint8 _ingredientPack) external view returns(uint16);
	function getIngredientPackToPrice(uint8 _ingredientPack) external view returns(uint);
	function getPveProbability(uint _buyin, uint _probIndex) external view returns(uint16);
	function getBuyinReward(uint _buyin) external view returns(uint);
	function getMultiplierToProbability(uint _multiplier) external view returns(uint16);
	function getMultiplier(uint8 _multiplier) external view returns(uint16);
	function getPveChainLinkFee() external view returns(uint);
	function getPvpChainLinkFee() external view returns(uint);
	
	// Minting
	function getMintingPackToQuantity(uint8 mintingPack) external view returns(uint8);
	function getRecipeAttribute(uint _prob) external view returns(uint16);
	function getRegularMintingProbs() external view returns(uint [] memory);
	function getRecipeTPRange(uint _bottomLimit) external view returns (uint);
	function getRecipesBaseURI() external view returns (string memory);
	function getRiderAttributes(uint16 _prob) external view returns (RiderAttributes memory attributes);
	function getMotorbikes() external view returns (bytes12 [] memory);
	function getBaseURILength(string memory _baseURI) external view returns (uint);
	function getRidersURIs(uint8 _nftRareness) external view returns (string memory, string memory);
	function getRiderQuantityToChainLinkFee(uint _riderQuantity) external view returns (uint);
	function getRecipeQuantityToChainLinkFee(uint _recipeQuantity) external view returns (uint);

	// Pizzerias
	function getTipPowerURIRanges() external view returns(uint[] memory);
	function getRarenessToTokenURI(uint _rarenessLimit) external view returns(string memory);
}

// SPDX-License-Identifier: MIT
  pragma solidity ^0.8.0;

  interface IMarketPlace {
  struct Item{
		uint itemId;
		address nft;
		uint tokenId;
		uint price;
		address payable seller;
		bool sold;
	}
    function getNftToItems(address _allowedNFT) external view returns(Item[] memory);

  }

// SPDX-License-Identifier: MIT
  pragma solidity ^0.8.0;

  interface IRecipesFactory {
    function getMintingState(address _user) external view returns(uint);
  }

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICollectionRiders {
	struct RidersAttributes {
    uint riderId;
    uint8 pizzaQuantity;
    uint8 wheel;
    uint8 fairing;
    uint8 clutch;
    uint8 exhaustPipe;
    uint8 turbo;
    uint8 nitro;
    bytes12 motorBike;
    bool inPizzeria;
    bool isPromotionalA;
    bool isFusioned;
    bool isRetired;
    string tokenURI;
    string imageURI;
  }

	function setInPizzeria(uint[] calldata riders) external;
	function getInPizzeria(uint _tokenId) external view returns(bool);
	function getPizzaQuantity(uint _tokenId) external view returns(uint8);
	function isOwner(uint _tokenId, address _user) external view returns(bool);
  function getOwnerOf(uint _tokenId) external view returns(address);
  function getMotorbike(uint _tokenId) external view returns(bytes12);
  function getAttributes(uint[] memory riders) external view returns(RidersAttributes[] memory attributes);
  function mint(address user, RidersAttributes memory attributes) external returns(uint _id);
  function getRiderList(address _user) external view returns(uint[] memory);
  function getTokenURI(uint _tokenId) external view returns (string memory);
  function getImageURI(uint _tokenId) external view returns (string memory);
  function burn(uint _tokenId) external;
  function getIsPromotional(uint _tokenId) external view returns(bool);
  function getIsFusioned(uint _tokenId) external view returns(bool);
  function setRetirement(uint[] calldata riders) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICollectionPizzerias {
	struct PizzeriasAttributes {
		uint16 tipPower;
		uint pizzaQuantity;
		uint claimCounter;
		bool retirementFlag;
		bool isSpecial;
		uint[] ridersList;
		uint[] recipeList;
		uint favouriteRider;
	}

	function mint(address user, PizzeriasAttributes memory attributes, string memory _tokenURI) external returns(uint _id);
	function updateRidersAttributes(uint _tokenId, uint[] calldata riders, uint _totalPizzaQuantity) external;
	function updateRecipesAttributes(uint _tokenId, uint[] calldata recipe, uint16 _totalTipPower) external;
	function updateIsSpecial(uint _tokenId, bool _isSpecial) external;
	function updateTokenURI(uint _tokenId, string memory _tokenURI) external;
	function updateClaimCounter(uint _tokenId) external;
	function pizzeriaRetirement(uint _tokenId) external;
	function getRidersNumberAndPizzaQuantity(uint _tokenId) external view returns(uint, uint);
	function getRecipesNumberAndTipPower(uint _tokenId) external view returns(uint16, uint);
  function getAttributes(uint[] memory pizzerias) external view returns (PizzeriasAttributes[] memory);
	function isOwner(uint _tokenId, address _user) external view returns(bool);
	function extOwnerOf(uint _tokenId) external view returns(address);
	function getRetiredPizzeriasList() external view returns(uint[] memory);
	function getTipPower(uint _tokenId) external view returns(uint16);
	function getTokenURI(uint _tokenId) external view returns (string memory);
	function getTotalRetiredPizzeriasTP() external view returns(uint16);
	function getPizzeriasList(address user) external view returns(uint[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICollectionRecipes {
	function setInPizzeria(uint[] calldata recipe) external;
    function getInPizzeria(uint _tokenId) external view returns(bool);
    function getTipPower(uint _tokenId) external view returns(uint16);
    function isOwner(uint _tokenId, address _user) external view returns(bool);
    function mint(address user, string memory _tokenURI, uint16 tipPower) external; 
    function getTokenURI(uint _tokenId) external view returns (string memory);
    function getRecipeList(address _user) external view returns(uint[] memory);
    function burn(uint _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ICollectionRiders.sol"; 

interface IPVPStorage {

  struct Race {
    uint raceId;
    uint[] riderId;
    uint32[] ridersPoints;
    bytes12 raceType;
    uint32 startingShot;
    uint16 buyinUsdt;
    address[] userList;
    uint rewardAmount;
    uint buyinToken;
    uint winnerRiderId;
    uint jackpot;
    bool claimed;
  }
  function getRace(uint _raceId) external view returns(Race memory);
  function increaseJackpot(uint16 _buyinUSD, uint _jackpotAmount) external;
  function getJackpot(uint16 _buyinUSD) external view returns(uint _jackpot);
  function updateRidersPoints(uint _raceId, uint32[] calldata _ridersPoints) external;
  function updateRaceClaim(uint _raceId) external;
  function updateRaceWinner(uint _raceId, uint _winnerIndex) external;
  function updateJackpot(uint _raceId) external;
  function updateRaceRegister(uint _raceId, uint _riderId, uint _reward, address _user) external;
  function updateTopJackpots(uint _jackpot) external;
  function getBuyinAndJackpots() external view returns(uint16[] memory, uint[] memory);
  function getAllRaces() external view returns(Race[] memory, ICollectionRiders.RidersAttributes[][] memory);
  function getPVPTopFiveJackpots() external view returns(uint[5] memory _topFiveClaimedJackpots);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPriceOracle {
  function getTokenToUsdt(uint tokenQuantity) external view returns(uint exchange);
  function getUsdtToToken(uint usdtQuantity) external view returns(uint exchange);
  function getLatestPrice() external view returns (int);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRewardPool {
	function transfer(address recipient, uint _pizzeriaId) external;
	function getPizzeriaBalance(uint _pizzeriaId) external view returns(uint);
	function getPizzeriaIngredients(uint _pizzeriaId) external view returns (uint16); 
	function getLastDeliveryTime(uint _pizzeriaId) external view returns (uint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}