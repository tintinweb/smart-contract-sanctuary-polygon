// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./IPriceFeedProvider.sol";
import "../../interfaces/IMeralManager.sol";

contract EternalBattle is ERC721Holder {

  event StakeCreated (uint indexed tokenId, uint priceFeedId, uint positionSize, uint startingPrice, bool long);
  event StakeCanceled (uint indexed tokenId, uint change, uint reward, bool win);
  event TokenRevived (uint indexed tokenId, uint reviver);

  /*///////////////////////////////////////////////////////////////
                  STORAGE
  //////////////////////////////////////////////////////////////*/

  struct Stake {
    uint timestamp;
    uint16 priceFeedId;
    uint16 positionSize;
    uint startingPrice;
    bool long;
  }

  struct GamePair {
    bool active;
    uint longs;
    uint shorts;
  }

  mapping(uint16 => mapping(uint32 => bool)) bonusLongs;
  mapping(uint16 => mapping(uint32 => bool)) bonusShorts;

  // pricefeed > longs? > cmId > bonus?
  mapping(uint16 => mapping(bool => mapping(uint32 => bool))) gamePairsBonus;

  IMeralManager meralManager;
  IPriceFeedProvider priceFeed;

  uint16 public atkDivMod; // lower number higher multiplier
  uint16 public defDivMod; // lower number higher multiplier
  uint16 public spdDivMod; // lower number higher multiplier
  uint16 public xpMod; // lower number higher multiplier
  uint32 public reviverReward = 500; //500 tokens

  address private admin;

  // mapping tokenId to stake;
  mapping (uint => Stake) private stakes;

  // mapping of active longs/shorts to priceIds
  mapping (uint16 => GamePair) private gamePairs;

  constructor(address _meralManagerAddress, address _priceFeedAddress) {
    admin = msg.sender;
    meralManager = IMeralManager(_meralManagerAddress);
    priceFeed = IPriceFeedProvider(_priceFeedAddress);
    atkDivMod = 1200;
    defDivMod = 2000;
    spdDivMod = 5000;
    xpMod = 3600;
  }


  /*///////////////////////////////////////////////////////////////
                  PUBLIC FUNCTIONS
  //////////////////////////////////////////////////////////////*/


  /**
    * @dev
    * sends token to contract
    * requires price in range
    * creates stakes struct,
    */
  function createStake(uint _tokenId, uint16 _priceFeedId, uint16 _positionSize, bool long) external {
    require(gamePairs[_priceFeedId].active, 'not active');
    uint price = uint(priceFeed.getLatestPrice(_priceFeedId));
    require(price > 1000, 'pbounds');
    require(_positionSize >= 100 && _positionSize <= 1000, 'bounds');
    IMeralManager.Meral memory _meral = meralManager.getMeralById(_tokenId);
    require(_meral.elf > reviverReward, 'needs ELF');
    meralManager.transfer(msg.sender, address(this), _tokenId);
    stakes[_tokenId] = Stake(block.timestamp, _priceFeedId, _positionSize, price, long);

    _changeGamePair(_priceFeedId, long, _positionSize, true);
    emit StakeCreated(_tokenId, _priceFeedId, _positionSize, price, long);
  }

  /**
    * @dev
    * gets price and score change
    * returns token to owner
    *
    */
  function cancelStake(uint _tokenId) external {
    address owner = meralManager.getVerifiedOwner(_tokenId);
    require(owner == msg.sender, 'only owner');
    require(meralManager.ownerOf(_tokenId) == address(this), 'only staked');
    (uint change, uint reward, bool win) = getChange(_tokenId);
    meralManager.transfer(address(this), owner, _tokenId);
    meralManager.changeHP(_tokenId, uint16(change), win); // change in bps
    meralManager.changeXP(_tokenId, uint32((block.timestamp - stakes[_tokenId].timestamp) / xpMod), true);

    if(win) {
      meralManager.changeELF(_tokenId, uint32(reward), true);
    }

    _changeGamePair(stakes[_tokenId].priceFeedId, stakes[_tokenId].long, stakes[_tokenId].positionSize, false);
    emit StakeCanceled(_tokenId, change, reward, win);
  }

  /**
    * @dev
    * allows second token1 to revive token0 and take rewards
    * returns token1 to owner
    *
    */
  function reviveToken(uint _id0, uint _id1) external {
    require(meralManager.ownerOf(_id0) == address(this), 'only staked');
    require(meralManager.ownerOf(_id1) == msg.sender, 'only owner');
    // GET CHANGE
    Stake storage _stake = stakes[_id0];
    IMeralManager.Meral memory _meral = meralManager.getMeralById(_id0);

    (uint change, , bool win) = getChange(_id0);

    require((win != true && _meral.hp <= (change + 35)), 'not dead');
    address owner = meralManager.getVerifiedOwner(_id0);
    meralManager.transfer(address(this), owner, _id0);

    if(_meral.hp < 100) {
      meralManager.changeHP(_id0, uint16(100 - _meral.hp), true); // reset scores to 100
    } else {
      meralManager.changeHP(_id0, uint16(_meral.hp - 100), false); // reset scores to 100
    }

    meralManager.changeELF(_id0, reviverReward, false);
    meralManager.changeELF(_id1, reviverReward, true);
    meralManager.changeXP(_id0, uint32((block.timestamp - stakes[_id0].timestamp) / xpMod), true);

    _changeGamePair(_stake.priceFeedId, _stake.long, _stake.positionSize, false);
    emit TokenRevived(_id0, _id1);
  }


  /**
    * @dev
    * adds / removes long shorts
    * does not check underflow should be fine
    */
  function _changeGamePair(uint16 _priceFeedId, bool _long, uint _positionSize, bool _stake) internal {
    GamePair memory _gamePair  = gamePairs[_priceFeedId];
    if(_long) {
      gamePairs[_priceFeedId].longs = _stake ? _gamePair.longs + _positionSize : _gamePair.longs - _positionSize;
    } else {
      gamePairs[_priceFeedId].shorts = _stake ? _gamePair.shorts + _positionSize : _gamePair.shorts - _positionSize;
    }
  }


  /*///////////////////////////////////////////////////////////////
                  INTERNAL VIEW FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  function _calcBonus(uint _stat) internal pure returns (uint16) {
    uint stat = _stat * 10000;
    return uint16((stat + stat / 2) / 10000);
  }

  function safeScale(uint num, uint inMax, uint outMin, uint outMax) internal pure returns(uint16) {
    uint scaled = (num * (outMax - outMin)) / inMax + outMin;
    return uint16(scaled > outMax ? outMax : scaled);
  }


  /*///////////////////////////////////////////////////////////////
                  PUBLIC VIEW FUNCTIONS
  //////////////////////////////////////////////////////////////*/


  /**
    * @dev
    * gets price difference in bps
    * modifies the score change and rewards by atk/def/spd
    * atk increase winning score change, def reduces losing score change, spd increase rewards
    */
  function getChange(uint _tokenId) public view returns (uint, uint, bool) {
    Stake storage _stake = stakes[_tokenId];
    IMeralManager.Meral memory _meral = meralManager.getMeralById(_tokenId);
    uint priceEnd = uint(priceFeed.getLatestPrice(_stake.priceFeedId));
    uint reward;
    bool win = _stake.long ? _stake.startingPrice < priceEnd : _stake.startingPrice > priceEnd;
    uint change = _stake.positionSize * calcBps(_stake.startingPrice, priceEnd);

    uint16 atk = _meral.atk;
    uint16 def = _meral.def;
    uint16 spd = _meral.spd;


    //scale stats
    if(getShouldBonus(_stake.priceFeedId, _meral.cmId, _stake.long)) {
      atk = _calcBonus(atk);
      def = _calcBonus(def);
      spd = _calcBonus(spd);
    }

    atk = safeScale(atk, 2000, 100, 2000);
    def = safeScale(def, 2000, 100, 2000);
    spd = safeScale(spd, 2000, 100, 2000);

    change = change / 1000;

    if(win) {
      // REWARDS
      uint longs = gamePairs[_stake.priceFeedId].longs;
      uint shorts = gamePairs[_stake.priceFeedId].shorts;
      uint counterTradeBonus = 1;

      if(!_stake.long && longs > shorts) {
        counterTradeBonus = longs / shorts;
      }
      if(_stake.long && shorts > longs) {
        counterTradeBonus = shorts / longs;
      }
      counterTradeBonus = counterTradeBonus > 3 ? 3 : counterTradeBonus;

      reward = change * spd / spdDivMod * counterTradeBonus + change;

      change = change * atk / atkDivMod + change;

    } else {
      uint subtract = change * def / defDivMod;
      change = change > subtract ? change - subtract : 0;
    }

    return (change, reward, win);
  }

  function getShouldBonus(uint16 _gamePair, uint32 _cmId, bool _long) public view returns (bool shouldBonus) {
    return gamePairsBonus[_gamePair][_long][_cmId];
  }


  function calcBps(uint _x, uint _y) public pure returns (uint) {
    // 1000 = 10% 100 = 1% 10 = 0.1% 1 = 0.01%
    return _x < _y ? (_y - _x) * 10000 / _x : (_x - _y) * 10000 / _y;
  }

  function getStake(uint _tokenId) external view returns (Stake memory) {
    return stakes[_tokenId];
  }

  function getGamePair(uint8 _gamePair) external view returns (GamePair memory) {
    return gamePairs[_gamePair];
  }


  /*///////////////////////////////////////////////////////////////
                  ADMIN FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  function resetGamePair(uint8 _gameIndex, bool _active) external onlyAdmin() { //admin
    gamePairs[_gameIndex].active = _active;
    gamePairs[_gameIndex].longs = 0;
    gamePairs[_gameIndex].shorts = 0;
  }

  function cancelStakeAdmin(uint _tokenId) external onlyAdmin() { //admin
    address owner = meralManager.getVerifiedOwner(_tokenId);
    meralManager.transfer(address(this), owner, _tokenId);

    _changeGamePair(stakes[_tokenId].priceFeedId, stakes[_tokenId].long, stakes[_tokenId].positionSize, false);
    emit StakeCanceled(_tokenId, 0, 0, false);
  }

  function setCMIDBonus(uint32[] calldata _cmIds, uint16 _gamePair, bool _long, bool _bonus) external onlyAdmin() { //admin
    for (uint256 i = 0; i < _cmIds.length; i++) {
      gamePairsBonus[_gamePair][_long][_cmIds[i]] = _bonus;
    }
  }

  function setReviverRewards(uint32 _reward) external onlyAdmin() { //admin
    reviverReward = _reward;
  }

  function setStatsDivMod(uint16 _atkDivMod, uint16 _defDivMod, uint16 _spdDivMod, uint16 _xpMod) external onlyAdmin() { //admin
    atkDivMod = _atkDivMod;
    defDivMod = _defDivMod;
    spdDivMod = _spdDivMod;
    xpMod = _xpMod;
  }

  function setPriceFeedContract(address _pfAddress) external onlyAdmin() { //admin
    priceFeed = IPriceFeedProvider(_pfAddress);
  }

  modifier onlyAdmin() {
    require(msg.sender == admin, 'admin only');
    _;
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IPriceFeedProvider {
    /**
     * Returns the latest price for a price feed.
     * It reverts if the feed id is invalid: there was no price feed address provided for the given id yet
     */
    function getLatestPrice(uint16 _priceFeedId)
        external
        view
        returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IMeralManager {

  struct Meral {
    uint32 cmId;
    uint32 elf;
    uint32 xp;
    uint16 hp;
    uint16 maxHp;
    uint16 atk;
    uint16 def;
    uint16 spd;
    uint16 maxStamina;
    uint8 element;
    uint8 subclass;
    uint8 status;
  }

  function ownerOf(uint _id) external returns (address);
  function transfer(address from, address to, uint _id) external;
  function changeHP(uint _id, uint16 offset, bool add) external;
  function changeXP(uint _id, uint32 offset, bool add) external;
  function changeELF(uint _id, uint32 offset, bool add) external;
  function changeStats(uint _id, uint16 _atk, uint16 _def, uint16 _spd) external;
  function changeMax(uint _id, uint16 _maxHp, uint16 _maxStamina) external;
  function changeElement(uint _id, uint8 _element) external;
  function changeCMID(uint _id, uint32 _cmId) external;
  function getVerifiedOwner(uint _id) external view returns (address);
  function getMeralById(uint _id) external view returns (Meral memory);
  function getMeralByType(uint _type, uint _tokenId) external view returns (Meral memory);
  function getTypeByContract(address contractAddress) external view returns (uint);
  function getMeralByContractAndTokenId(address contractAddress, uint _tokenId) external view returns (Meral memory);
  function registerOGMeral(
    address contractAddress,
    uint _tokenId,
    uint32 _cmId,
    uint32 _elf,
    uint16 _hp,
    uint16 _atk,
    uint16 _def,
    uint16 _spd,
    uint8 _element,
    uint8 _subclass
  ) external;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}