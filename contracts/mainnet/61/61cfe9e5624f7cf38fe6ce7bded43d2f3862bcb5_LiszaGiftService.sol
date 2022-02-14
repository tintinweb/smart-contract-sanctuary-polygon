/**
 *Submitted for verification at polygonscan.com on 2022-02-14
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface ILiszaGiftService {

  /// Позволяет узнать общее количество подарков
  function getGiftsCount() external view returns (uint);

  /// Открывает следующий подарок, делая его доступным; ничего не возвращает
  function openNextGift() external;
  
  /// Возвращает уже открытый (!) подарок по индексу
  function getOpenGift(uint index) external view returns (string memory);
}

contract LiszaGiftService is ILiszaGiftService {

  /* Constants */

  address internal immutable sasha;
  address internal immutable lisza;
  uint internal constant OPEN_COOLDOWN = 14_440; // 4 hours
  string internal encryptionHint;

  /* State */

  string[] internal gifts;
  uint internal openGiftsCount;
  uint internal lastOpenTimestamp;

  /* Constructor */

  constructor(address _lisza, string memory _encryptionHint) {
    sasha = msg.sender;
    lisza = _lisza;
    encryptionHint = _encryptionHint;
  }

  /* Public */

  function addGift(string memory gift_) 
    onlySasha 
    external 
  {
    gifts.push(gift_);
  }

  function openNextGift() 
    onlyLisza 
    external 
  {
    require(
      openGiftsCount < gifts.length,
      "All gifts are already open. Finita la comedia!"
    );
    require(
      block.timestamp - lastOpenTimestamp > OPEN_COOLDOWN,
      "You should be more patient, 4 hours havn't passed since last gift"
    );
    openGiftsCount++;
    lastOpenTimestamp = block.timestamp;
  }

  function getGiftsCount()
    external
    view
    returns (uint)
  {
    return gifts.length;
  }

  function getOpenGift(uint index)
    external 
    view 
    returns (string memory) 
  {
    require(index > 0, "Index should be positive");
    uint arrayIndex = index - 1;
    require(arrayIndex < openGiftsCount, "There's no open gift with such index");
    return gifts[arrayIndex];
  }

  function getEncryptionHint()
    external
    view
    returns (string memory)
  {
    return encryptionHint;
  }

  /* Modifiers */

  modifier onlySasha() {
    require(msg.sender == sasha, "This operations can be executed only by Sasha");
    _;
  }

  modifier onlyLisza() {
    require(msg.sender == lisza, "This operations can be executed only by Lisza");
    _;
  }
}