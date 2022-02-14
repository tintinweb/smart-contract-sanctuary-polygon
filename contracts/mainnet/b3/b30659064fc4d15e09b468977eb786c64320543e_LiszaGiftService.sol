/**
 *Submitted for verification at polygonscan.com on 2022-02-14
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface ILiszaGiftService {

  /// Позволяет узнать общее количество подарков
  function getGiftsCount() external view returns (uint);

  /// Позволяет открыть подарок и возвращает его описание
  function openNextGift() external returns (string memory);
  
  /// Возвращает уже открытый (!) подарок по индексу
  function getOpenGift(uint index) external view returns (string memory);
}

contract LiszaGiftService is ILiszaGiftService {

  /* Properties */

  address sasha;
  address lisza;
  string[] gifts;
  uint openGiftsCount;
  uint lastOpenTimestamp;
  uint OPEN_COOLDOWN = 14_440; // 4 hours

  /* Constructor */

  constructor(address lisza_) {
    sasha = msg.sender;
    lisza = lisza_;
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
    returns (string memory) 
  {
    require(
      openGiftsCount < gifts.length,
      "All gifts are already open. Finita la comedia!"
    );
    require(
      block.timestamp - lastOpenTimestamp > OPEN_COOLDOWN,
      "You should be more patient, 4 hours havn't passed since last gift"
    );
    string memory message = messageForGift(openGiftsCount + 1, gifts[openGiftsCount]);
    openGiftsCount++;
    lastOpenTimestamp = block.timestamp;
    return message;
  }

  function getGiftsCount()
    onlyLisza
    external
    view
    returns (uint)
  {
    return gifts.length;
  }

  function getOpenGift(uint index)
    onlyLisza
    external 
    view 
    returns (string memory) 
  {
    require(index > 0, "Index should be positive");
    uint arrayIndex = index - 1;
    require(arrayIndex < openGiftsCount, "There's no open gift with such index");
    return messageForGift(index, gifts[arrayIndex]);
  }

  /* Private */

  function messageForGift(uint index_, string memory name_) 
    private 
    pure 
    returns (string memory) 
  {
    return string(
      abi.encodePacked(
        "Gift #", 
        index_, 
        ": ",
        name_  
      )
    );
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