// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {INFTOracle} from "../interfaces/INFTOracle.sol";
import {BlockContext} from "../utils/BlockContext.sol";

// modified from BendDao NFTOracle
// add a new feature to get different tokenId's price under every NFT collection

contract NFTOracle is INFTOracle, Initializable, OwnableUpgradeable, BlockContext {

  // OracleType.withoutTokenId Represents that NFTs under the same collection share a floor price (same as original function of BendDao)
  // OracleType.withTokenId Represents that NFTs under the same collection have different prices
  enum OracleType {
    withoutTokenId,
    withTokenId
  }
  
  modifier onlyAdmin() {
    require(_msgSender() == priceFeedAdmin, "NFTOracle: !admin");
    _;
  }

  /**
   * @notice The new added modifier
   * @dev check the oracleType of nftcontract
   * @param oracleType See the description at the top of the file
   */
  modifier checkOracleType(OracleType oracleType , address _nftContract){
    require(oracleType == getOracleType(_nftContract) , "oracleType mismatch");
    _;
  }

  // add oracleType
  event AssetAdded(OracleType oracleType , address indexed asset);

  // add oracleType
  event AssetRemoved(address indexed asset);

  event FeedAdminUpdated(address indexed admin);
  event SetAssetData(address indexed asset, uint256 price, uint256 timestamp, uint256 roundId);

  struct NFTPriceData {
    uint256 roundId;
    uint256 price;
    uint256 timestamp;
  }

  struct NFTPriceFeed {
    bool registered;

    OracleType oracleType;   // new added

    NFTPriceData[] nftPriceData;  // Old BendDao param (can only get the floor price of nft collection)

    // nft tokenId => nftPriceData
    mapping(uint => NFTPriceData[]) nftPriceDataTypeOne;  // new added (For OracleType=1)
  }

  address public priceFeedAdmin;

  // key is nft contract address
  mapping(address => NFTPriceFeed) public nftPriceFeedMap;


  address[] public nftPriceFeedKeys;

  // data validity check parameters
  uint256 private constant DECIMAL_PRECISION = 10**18;
  // Maximum deviation allowed between two consecutive oracle prices. 18-digit precision.
  uint256 public maxPriceDeviation; // 20%,18-digit precision.
  // The maximum allowed deviation between two consecutive oracle prices within a certain time frame. 18-bit precision.
  uint256 public maxPriceDeviationWithTime; // 10%
  uint256 public timeIntervalWithPrice; // 30 minutes
  uint256 public minimumUpdateTime; // 10 minutes

  mapping(address => bool) internal _nftPaused;

  modifier whenNotPaused(address _nftContract) {
    _whenNotPaused(_nftContract);
    _;
  }

  function _whenNotPaused(address _nftContract) internal view {
    bool _paused = _nftPaused[_nftContract];
    require(!_paused, "NFTOracle: nft price feed paused");
  }

  function initialize(
    address _admin,
    uint256 _maxPriceDeviation,
    uint256 _maxPriceDeviationWithTime,
    uint256 _timeIntervalWithPrice,
    uint256 _minimumUpdateTime
  ) public initializer {
    __Ownable_init();
    priceFeedAdmin = _admin;
    maxPriceDeviation = _maxPriceDeviation;
    maxPriceDeviationWithTime = _maxPriceDeviationWithTime;
    timeIntervalWithPrice = _timeIntervalWithPrice;
    minimumUpdateTime = _minimumUpdateTime;
  }

  function setPriceFeedAdmin(address _admin) external onlyOwner {
    priceFeedAdmin = _admin;
    emit FeedAdminUpdated(_admin);
  }

  /**
   * @notice The original BendDao function
   * @dev Batch call addAsset
   * @dev The default oracleType is 0
   */
   function setAssets(address[] calldata _nftContracts) external onlyOwner {
    for (uint256 i = 0; i < _nftContracts.length; i++) {
      addAssetInternal(OracleType.withoutTokenId , _nftContracts[i]);
    }
  }

  /**
   * @notice The new added function
   * @dev Batch call addAsset and set their oracleType
   */
    function setAssetsWithTokenId(
      address[] calldata _nftContracts ,
      OracleType[] calldata _oracleTypes
    ) external onlyOwner {
      // check the length of nftContracts and oracleTypes
      require(_nftContracts.length == _oracleTypes.length , "length mismatch");
      
      for (uint256 i = 0; i < _nftContracts.length; i++) {
        addAssetInternal(_oracleTypes[i] , _nftContracts[i]);
      }
  }



  /**
   * @notice The original BendDao function
   * @dev Add a nft collection to the oracle that OracleType.withoutTokenId
   */
  function addAsset(address _nftContract) external onlyOwner {
    addAssetInternal(OracleType.withoutTokenId , _nftContract);
  }

  /**
   * @notice The new added function
   * @notice Name change from addAsset
   * @dev Add a nft collection to the oracle that OracleType.withTokenId
   * @param oracleType See the description at enum OracleType
   */
  function addAssetWithTokenId(
    OracleType oracleType,
    address _nftContract
  ) external onlyOwner {
    addAssetInternal(oracleType , _nftContract );
  }

  function addAssetInternal(
    OracleType oracleType,
    address _nftContract
  ) internal {
    requireKeyExisted(_nftContract, false);
    nftPriceFeedKeys.push(_nftContract);
    nftPriceFeedMap[_nftContract].registered = true;

    nftPriceFeedMap[_nftContract].oracleType = oracleType;

    emit AssetAdded(oracleType , _nftContract);
  }

  /**
   * @notice The original Bendao function
   * @dev To removeAsset a nft collection from the oracle
   * @param _nftContract The nft contract address
   */
  function removeAsset(address _nftContract) external onlyOwner {
    requireKeyExisted(_nftContract, true);
    delete nftPriceFeedMap[_nftContract];

    uint256 length = nftPriceFeedKeys.length;
    for (uint256 i = 0; i < length; i++) {
      if (nftPriceFeedKeys[i] == _nftContract) {
        nftPriceFeedKeys[i] = nftPriceFeedKeys[length - 1];
        nftPriceFeedKeys.pop();
        break;
      }
    }

    emit AssetRemoved(_nftContract);
  }


  /**
   * @notice The original BendDao function
   * @dev push the NFT latest floor price
   * @dev used in oracleType=0
   */
  function setAssetData(
    address _nftContract,
    uint256 _price,
    uint256, /*_timestamp*/  // We use _blockTimestamp to replace it
    uint256 _roundId
  ) external override onlyAdmin whenNotPaused(_nftContract) {
    setAssetDataInternal(
      OracleType.withoutTokenId, // oracleType=0
      0, // tokenId not used
      _nftContract,
      _price,
      _roundId
    );
  }
  
  /**
   * @notice The new added function
   * @notice Name change from setAssetData
   * @dev push the NFT latest price
   * @dev can only be used to OracleType.withTokenId
   */
  function setAssetDataWithTokenId(
    address _nftContract,
    uint256 _tokenId,  // new added (for oracleType=0)
    uint256 _price,
    uint256, /*_timestamp*/  // We use _blockTimestamp to replace it
    uint256 _roundId
  ) external onlyAdmin whenNotPaused(_nftContract) {
    OracleType oracleType = getOracleType(_nftContract);

    setAssetDataInternal(
      oracleType,
      _tokenId, // tokenId not used
      _nftContract,
      _price,
      _roundId
    );
  }

  /**
   * @notice The new added function
   * @dev push the latest price of multiple NFTs under one _nftContract 
   * @dev can only be used to OracleType.withTokenId
   */
  function setBatchAssetDataWithTokenId(
    address _nftContract,
    uint256[] calldata _tokenIds,  // new added
    uint256[] calldata _prices,
    uint256, /*_timestamp*/  // We use _blockTimestamp to replace it
    uint256 _roundId
  ) external onlyAdmin whenNotPaused(_nftContract) {
    require(_tokenIds.length == _prices.length , "prices length mismatch");

    for(uint i=0; i<_tokenIds.length; i++){
      uint _tokenId = _tokenIds[i];
      uint _price = _prices[i];

      setAssetDataInternal(
        OracleType.withTokenId,
        _tokenId, // tokenId not used
        _nftContract,
        _price,
        _roundId
      );
    }

  }

  /**
   * @notice The new added internal function
   * @dev To set the new nft price
   * @param oracleType See the description at the top of the file
   * @param _tokenId The NFT tokenId (used when oracleType=1)
   * @param _nftContract The smart contract address of nft
   * @param _price The NFT floor price
   * @param _roundId Same as roundId in Chainlink oracle (https://docs.chain.link/docs/historical-price-data/)
   */
  function setAssetDataInternal(
    OracleType oracleType,
    uint256 _tokenId,
    address _nftContract,
    uint256 _price,
    uint256 _roundId
  ) internal checkOracleType(oracleType , _nftContract) {

    requireKeyExisted(_nftContract, true);
    uint256 _timestamp = _blockTimestamp();
    require(_timestamp > getLatestTimestampWithTokenId(_nftContract , _tokenId), "NFTOracle: incorrect timestamp");
    require(_price > 0, "NFTOracle: price can not be 0");
    bool dataValidity = checkValidityOfPrice(oracleType , _nftContract, _price, _timestamp , _tokenId);
    require(dataValidity, "NFTOracle: invalid price data");
    NFTPriceData memory data = NFTPriceData({price: _price, timestamp: _timestamp, roundId: _roundId});

    if(oracleType == OracleType.withoutTokenId){
      nftPriceFeedMap[_nftContract].nftPriceData.push(data);
    } 
    else if (oracleType == OracleType.withTokenId){
      nftPriceFeedMap[_nftContract].nftPriceDataTypeOne[_tokenId].push(data);
    }
    

    emit SetAssetData(_nftContract, _price, _timestamp, _roundId);
  }

  /**
   * @notice The original BendDao function
   * @dev To get the nft floor price
   * @dev used in oracleType=0
   */
  function getAssetPrice(address _nftContract) external view override returns (uint256) {
    return getAssetPriceInternal(
      OracleType.withoutTokenId, // oracleType=0
      _nftContract,
      0 // tokenId not used when oracleType=0
    );
  }

  /**
   * @notice The new added function
   * @notice Name change from getAssetPrice
   * @dev To get the price of specific tokenId in NFT collection
   * @dev This function will be call by GenericLogic in LendingPool contract
   * @param _tokenId The tokenId of NFTl. Will be not used when OracleType.withoutTokenId
   */
  function getAssetPriceWithTokenId(address _nftContract , uint _tokenId) external view override returns (uint256){
    OracleType oracleType = getOracleType(_nftContract);
    
    return getAssetPriceInternal(
      oracleType,
      _nftContract,
      _tokenId
    );
  }

  /**
   * @notice The new added internal function
   * @dev To get the NFT price
   * @param oracleType See the description at the top of the file
   * @param _nftContract The nft contract address
   * @param _tokenId The nft tokenId
   */
  function getAssetPriceInternal(
    OracleType oracleType,
    address _nftContract,
    uint256 _tokenId // Not used if oracleType=0
  ) internal view checkOracleType(oracleType , _nftContract) returns (uint256 price){
    
    require(isExistedKey(_nftContract), "NFTOracle: key not existed");
    uint256 len = getPriceFeedLengthWithTokenId(_nftContract , _tokenId);
    require(len > 0, "NFTOracle: no price data");

    if(oracleType == OracleType.withoutTokenId){
      return nftPriceFeedMap[_nftContract].nftPriceData[len - 1].price;
    }
    else if(oracleType == OracleType.withTokenId){
      return nftPriceFeedMap[_nftContract].nftPriceDataTypeOne[_tokenId][len - 1].price;
    }
  }

  /**
   * @notice The original BendDao function
   * @dev Can only be used when oracleType=0
   * @param _nftContract the nft contract address
   */
  function getLatestTimestamp(address _nftContract) public view override returns (uint256) {
    
    return getLatestTimestampInternal(
      OracleType.withoutTokenId ,  // oracleType = 0
      _nftContract,
      0 // tokenId not used when oracleType=0
    );
  }

  /**
   * @notice The new added function
   * @notice Name change from getLatestTimestamp
   * @dev Can be used to any oracleType
   * @param _nftContract the nft contract address
   * @param _tokenId The NFT tokenId
   */
  function getLatestTimestampWithTokenId(address _nftContract , uint _tokenId) public view returns (uint256){
    OracleType oracleType = getOracleType(_nftContract);

    return getLatestTimestampInternal(
      oracleType,
      _nftContract,
      _tokenId
    );
  }

  function getLatestTimestampInternal(
    OracleType oracleType,
    address _nftContract ,
    uint _tokenId
    ) internal view checkOracleType(oracleType , _nftContract) returns (uint256 latestTimestamp){
    require(isExistedKey(_nftContract), "NFTOracle: key not existed");
    uint256 len = getPriceFeedLengthWithTokenId(_nftContract , _tokenId);
    if (len == 0) {
      return 0;
    }

    if(oracleType == OracleType.withoutTokenId){
      latestTimestamp = nftPriceFeedMap[_nftContract].nftPriceData[len - 1].timestamp;
    }
    else if(oracleType == OracleType.withTokenId){
      latestTimestamp = nftPriceFeedMap[_nftContract].nftPriceDataTypeOne[_tokenId][len - 1].timestamp;
    }

    
  }

  /**
   * @notice The original BendDao function
   * @dev To get the time weightedPrice
   */
  function getTwapPrice(address _nftContract, uint256 _interval) external view override returns (uint256) {
    require(isExistedKey(_nftContract), "NFTOracle: key not existed");
    require(_interval != 0, "NFTOracle: interval can't be 0");

    uint256 len = getPriceFeedLength(_nftContract);
    require(len > 0, "NFTOracle: Not enough history");
    uint256 round = len - 1;
    NFTPriceData memory priceRecord = nftPriceFeedMap[_nftContract].nftPriceData[round];
    uint256 latestTimestamp = priceRecord.timestamp;
    uint256 baseTimestamp = _blockTimestamp() - _interval;
    // if latest updated timestamp is earlier than target timestamp, return the latest price.
    if (latestTimestamp < baseTimestamp || round == 0) {
      return priceRecord.price;
    }

    // rounds are like snapshots, latestRound means the latest price snapshot. follow chainlink naming
    uint256 cumulativeTime = _blockTimestamp() - latestTimestamp;
    uint256 previousTimestamp = latestTimestamp;
    uint256 weightedPrice = priceRecord.price * cumulativeTime;
    while (true) {
      if (round == 0) {
        // if cumulative time is less than requested interval, return current twap price
        return weightedPrice / cumulativeTime;
      }

      round = round - 1;
      // get current round timestamp and price
      priceRecord = nftPriceFeedMap[_nftContract].nftPriceData[round];
      uint256 currentTimestamp = priceRecord.timestamp;
      uint256 price = priceRecord.price;

      // check if current round timestamp is earlier than target timestamp
      if (currentTimestamp <= baseTimestamp) {
        // weighted time period will be (target timestamp - previous timestamp). For example,
        // now is 1000, _interval is 100, then target timestamp is 900. If timestamp of current round is 970,
        // and timestamp of NEXT round is 880, then the weighted time period will be (970 - 900) = 70,
        // instead of (970 - 880)
        weightedPrice = weightedPrice + (price * (previousTimestamp - baseTimestamp));
        break;
      }

      uint256 timeFraction = previousTimestamp - currentTimestamp;
      weightedPrice = weightedPrice + price * timeFraction;
      cumulativeTime = cumulativeTime + timeFraction;
      previousTimestamp = currentTimestamp;
    }
    return weightedPrice / _interval;
  }

  /**
   * @notice The original BendDao function
   * @dev To get the previous price of specific RoundBack
   */
  function getPreviousPrice(address _nftContract, uint256 _numOfRoundBack) public view override returns (uint256) {
    require(isExistedKey(_nftContract), "NFTOracle: key not existed");

    uint256 len = getPriceFeedLength(_nftContract);
    require(len > 0 && _numOfRoundBack < len, "NFTOracle: Not enough history");
    return nftPriceFeedMap[_nftContract].nftPriceData[len - _numOfRoundBack - 1].price;
  }

  /**
   * @notice The original BendDao function
   * @dev To get the previous timestamp of specific RoundBack
   */
  function getPreviousTimestamp(address _nftContract, uint256 _numOfRoundBack) public view override returns (uint256) {
    require(isExistedKey(_nftContract), "NFTOracle: key not existed");

    uint256 len = getPriceFeedLength(_nftContract);
    require(len > 0 && _numOfRoundBack < len, "NFTOracle: Not enough history");
    return nftPriceFeedMap[_nftContract].nftPriceData[len - _numOfRoundBack - 1].timestamp;
  }

  /**
   * @notice Bendao function
   * @notice Get the history price length of _nftContract
   * @dev Used for OracleType.withoutTokenId
   */
  function getPriceFeedLength(
    address _nftContract
  ) public view checkOracleType(OracleType.withoutTokenId , _nftContract) returns (uint256 length) {
    return getPriceFeedLengthInternal(
      _nftContract,
      0 //tokenId not used
    );
  }


  /**
   * @notice New function
   * @notice Name change from getPriceFeedLength
   * @notice Get the history price length of specific nft tokenId
   * @dev Used for any oracleType
   * @param _tokenId The NFT tokeId (not used if oracleType=0)
   */
  function getPriceFeedLengthWithTokenId(address _nftContract , uint _tokenId) public view returns (uint256 length) {
    return getPriceFeedLengthInternal(
      _nftContract,
      _tokenId
    );
    
  }

  /**
   * @notice The internal function to get the history price length of _nftContract
   * @param _tokenId The NFT tokenId (not used if oracleType == 0)
   * @return length The length of NFT price historical data
   */
  function getPriceFeedLengthInternal(
    address _nftContract ,
    uint _tokenId
  ) public view returns (uint256 length) {
    OracleType oracleType = getOracleType(_nftContract);
    if(oracleType == OracleType.withoutTokenId){
      return nftPriceFeedMap[_nftContract].nftPriceData.length;
    }
    else if(oracleType == OracleType.withTokenId){
      return nftPriceFeedMap[_nftContract].nftPriceDataTypeOne[_tokenId].length;
    }

  }

  /**
   * @notice The new added function
   * @dev Get the oracleType of the nftcontract
   */
  function getOracleType(address _nftContract) public view returns (OracleType oracleType) {
    oracleType = nftPriceFeedMap[_nftContract].oracleType;
  }

  function getLatestRoundId(address _nftContract) public view returns (uint256) {
    uint256 len = getPriceFeedLength(_nftContract);
    if (len == 0) {
      return 0;
    }
    return nftPriceFeedMap[_nftContract].nftPriceData[len - 1].roundId;
  }

  function isExistedKey(address _nftContract) private view returns (bool) {
    return nftPriceFeedMap[_nftContract].registered;
  }

  function requireKeyExisted(address _key, bool _existed) private view {
    if (_existed) {
      require(isExistedKey(_key), "NFTOracle: key not existed");
    } else {
      require(!isExistedKey(_key), "NFTOracle: key existed");
    }
  }


  /**
   * @notice The original BendDao internal function
   * @dev check the new added nft price meet the critera
   */
   function checkValidityOfPrice(
    OracleType oracleType,  // new added
    address _nftContract,
    uint256 _price,
    uint256 _timestamp,
    uint256 _tokenId  // new added
  ) private view returns (bool) {

    uint256 len;
    uint256 price;
    uint256 timestamp;

    if(oracleType == OracleType.withoutTokenId){
      len = getPriceFeedLength(_nftContract);
      if(len==0){
        return true;
      }
      price = nftPriceFeedMap[_nftContract].nftPriceData[len - 1].price;
      timestamp = nftPriceFeedMap[_nftContract].nftPriceData[len - 1].timestamp;
    }
    else if (oracleType == OracleType.withTokenId){
      len = getPriceFeedLengthWithTokenId(_nftContract , _tokenId);
      if(len==0){
        return true;
      }
      price = nftPriceFeedMap[_nftContract].nftPriceDataTypeOne[_tokenId][len - 1].price;
      timestamp = nftPriceFeedMap[_nftContract].nftPriceDataTypeOne[_tokenId][len - 1].timestamp;
    }

    
    if (_price == price) {
      return true;
    }
    uint256 percentDeviation;
    if (_price > price) {
      percentDeviation = ((_price - price) * DECIMAL_PRECISION) / price;
    } else {
      percentDeviation = ((price - _price) * DECIMAL_PRECISION) / price;
    }
    uint256 timeDeviation = _timestamp - timestamp;
    if (percentDeviation > maxPriceDeviation) {
      return false;
    } else if (timeDeviation < minimumUpdateTime) {
      return false;
    } else if ((percentDeviation > maxPriceDeviationWithTime) && (timeDeviation < timeIntervalWithPrice)) {
      return false;
    }
    

    return true;
  }

  /**
   * @notice The original BendDao function
   * @dev set the new added nft price critera
   * @param _maxPriceDeviation The maximum price deviation between the latest price and the previous price
   * @param _maxPriceDeviationWithTime TODO
   * @param _timeIntervalWithPrice TODO
   * @param _minimumUpdateTime Minimum time to update price again after updating price
   */
  function setDataValidityParameters(
    uint256 _maxPriceDeviation,
    uint256 _maxPriceDeviationWithTime,
    uint256 _timeIntervalWithPrice,
    uint256 _minimumUpdateTime
  ) external onlyOwner {
    maxPriceDeviation = _maxPriceDeviation;
    maxPriceDeviationWithTime = _maxPriceDeviationWithTime;
    timeIntervalWithPrice = _timeIntervalWithPrice;
    minimumUpdateTime = _minimumUpdateTime;
  }

  function setPause(address _nftContract, bool val) external override onlyOwner {
    _nftPaused[_nftContract] = val;
  }

  function paused(address _nftContract) external view override returns (bool) {
    return _nftPaused[_nftContract];
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/************
@title INFTOracle interface
@notice Interface for NFT price oracle.*/
interface INFTOracle {
  /* CAUTION: Price uint is ETH based (WEI, 18 decimals) */
  // get latest price
  function getAssetPrice(address _asset) external view returns (uint256);

  /* CAUTION: Price uint is ETH based (WEI, 18 decimals) */
  // get latest price
  function getAssetPriceWithTokenId(address _asset , uint _tokenId) external view returns (uint256);


  // get latest timestamp
  function getLatestTimestamp(address _asset) external view returns (uint256);

  // get previous price with _back rounds
  function getPreviousPrice(address _asset, uint256 _numOfRoundBack) external view returns (uint256);

  // get previous timestamp with _back rounds
  function getPreviousTimestamp(address _asset, uint256 _numOfRoundBack) external view returns (uint256);

  // get twap price depending on _period
  function getTwapPrice(address _asset, uint256 _interval) external view returns (uint256);

  function setAssetData(
    address _asset,
    uint256 _price,
    uint256 _timestamp,
    uint256 _roundId
  ) external;

  function setPause(address _nftContract, bool val) external;

  function paused(address _nftContract) external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

// wrap block.xxx functions for testing
// only support timestamp and number so far
abstract contract BlockContext {
  //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

  //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//
  uint256[50] private __gap;

  function _blockTimestamp() internal view virtual returns (uint256) {
    return block.timestamp;
  }

  function _blockNumber() internal view virtual returns (uint256) {
    return block.number;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}