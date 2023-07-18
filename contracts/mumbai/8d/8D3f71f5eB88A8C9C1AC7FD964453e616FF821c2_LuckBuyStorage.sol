/**
 *Submitted for verification at polygonscan.com on 2023-07-17
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https:
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

pragma solidity >=0.4.22 <0.9.0;

struct LuckBuyItemTemplate {
  uint256 itemID ; 
  address tokenContract ; 
  uint256 totalAmount ; 
  uint256 bonusAmount ; 
  uint256 price ; 
  bool restart ; 
  uint256 period ; 
  bool online ; 
}

struct LuckBuyItem {
  uint256 itemID ; 
  address tokenContract ; 
  uint256 totalAmount ; 
  uint256 bonusAmount ; 
  uint256 price ; 
  bool restart ; 
  uint256 period ; 
  uint256 startTime ; 
  uint256 endTime ; 
  address[] buyers ; 
  address[] buyerSets ; 
  address[] rewardUserSets; 
  mapping (address=>uint256) buyQuantity; 
  mapping (address=>uint256) rewardAmount; 
}

struct LuckBuyItemData {
  uint256 itemID ; 
  address tokenContract ; 
  uint256 totalAmount ; 
  uint256 bonusAmount ; 
  uint256 price ; 
  uint256 period ; 
  uint256 startTime ; 
  uint256 endTime ; 
  uint256 userCount ; 
  uint256 quantity ; 
  uint256 ownerQuantity; 
  bool timeout ; 
  bool finished ; 
}

struct LuckBuyItemLog {
  uint256 itemID ; 
  address tokenContract ; 
  uint256 startTime ; 
  address winner ; 
  uint256 quantity ; 
  uint256 bonus ; 
}

struct LuckBuyItemUserLog {
  uint256 itemID ; 
  address tokenContract ; 
  uint256 startTime ; 
  uint256 quantity ; 
  bool finished ; 
  bool win; 
  uint256 bonus ; 
}

pragma solidity >=0.4.22 <0.9.0;

contract LuckBuyStorage {

  address private logicContract; 
  uint256[] private itemIDs; 
  mapping (uint256=>LuckBuyItem) private items; 
  mapping (uint256=>LuckBuyItemLog[]) private itemLogs; 
  mapping (address=>uint256) empty; 

  constructor(address _logic) {
    logicContract = _logic;
  }

  
  modifier onlyLogicContract() {
    require(msg.sender == logicContract, "Only logicContract");
    _;
  }

  
  function getItemList(address player) public view returns (LuckBuyItemData[] memory) {
    LuckBuyItemData[] memory itemArray = new LuckBuyItemData[](itemIDs.length);
    for(uint i = 0; i < itemIDs.length; i++) {
      LuckBuyItem storage item = items[itemIDs[i]];
      itemArray[i] = LuckBuyItemData(
        item.itemID, 
        item.tokenContract,
        item.totalAmount, 
        item.bonusAmount,
        item.price, 
        item.period, 
        item.startTime,
        item.endTime,
        item.buyerSets.length,
        item.buyers.length,
        item.buyQuantity[player],
        checkTimeout(item.itemID),
        checkFinished(item.itemID)
      );
    }
    return itemArray;
  }

  
  function getItem(address player, uint256 itemID) public view returns (LuckBuyItemData memory item) {
    LuckBuyItem storage _item = items[itemID];
    return LuckBuyItemData(
      _item.itemID, 
      _item.tokenContract,
      _item.totalAmount, 
      _item.bonusAmount,
      _item.price, 
      _item.period, 
      _item.startTime,
      _item.endTime,
      _item.buyerSets.length,
      _item.buyers.length,
      _item.buyQuantity[player],
      checkTimeout(itemID),
      checkFinished(itemID)
      );
  }

  
  function getItemLogs(uint256 itemID, uint page, uint size) public view returns (LuckBuyItemLog[] memory, uint256) {
    uint256 start; 
    uint256 end;
    uint tag = 0;
    if (itemLogs[itemID].length > (page+1) * size) { 
      start = itemLogs[itemID].length - (page+1) * size;
      end = itemLogs[itemID].length - page * size;
    } else {
      start = 0;
      if (itemLogs[itemID].length > page * size) {
        end = itemLogs[itemID].length - page * size;
      } else {
        end = 0;
      }
    }
    LuckBuyItemLog[] memory logs = new LuckBuyItemLog[](end - start);
    for(uint i = end; i > start; i--) {
      logs[tag] = itemLogs[itemID][i - 1];
      tag++;
    }
    return (logs, itemLogs[itemID].length);
  }

  
  function checkItemExist(uint256 itemID) public view returns (bool) {
    return items[itemID].itemID != 0;
  }

  
  function checkFinished(uint256 itemID) public view returns (bool) {
    if(items[itemID].itemID == 0) return false; 
    return items[itemID].buyers.length >= (items[itemID].totalAmount / items[itemID].price);
  }

  
  function checkTimeout(uint256 itemID) public view returns (bool) {
    if(items[itemID].itemID == 0) return false; 
    if(items[itemID].buyers.length >= (items[itemID].totalAmount / items[itemID].price)) return false; 
    return block.timestamp >= items[itemID].endTime;
  }

  
  function addItem(uint256 itemID, address tokenContract, uint256 totalAmount, uint256 bonusAmount, uint256 price, uint256 period) public onlyLogicContract returns (bool) {
    require(items[itemID].itemID == 0, "item already exist");
    items[itemID].itemID = itemID;
    items[itemID].tokenContract = tokenContract;
    items[itemID].totalAmount = totalAmount;
    items[itemID].bonusAmount = bonusAmount;
    items[itemID].price = price;
    items[itemID].restart = true;  
    items[itemID].period = period;
    items[itemID].startTime = block.timestamp;
    items[itemID].endTime = block.timestamp + period;
    itemIDs.push(itemID);
    return true;
  }

  
  function delItem(uint256 itemID) public onlyLogicContract returns (bool) {
    require(items[itemID].itemID != 0, "item not exist");
    items[itemID].restart = false; 
    return true;
  }

  
  function cleanItem(uint256 itemID) public onlyLogicContract returns (bool){
    require(items[itemID].itemID != 0, "item not exist"); 
    address tokenContract = items[itemID].tokenContract;
    uint256 totalAmount = items[itemID].totalAmount;
    uint256 price = items[itemID].price;
    bool restart = items[itemID].restart;
    uint256 period = items[itemID].period;
    
    
    for (uint256 i = 0; i < items[itemID].buyerSets.length; i++) {
      delete items[itemID].buyQuantity[items[itemID].buyerSets[i]];
    }
    
    for (uint256 i = 0; i < items[itemID].rewardUserSets.length; i++) {
      delete items[itemID].rewardAmount[items[itemID].rewardUserSets[i]];
    }
    if (items[itemID].restart) { 
      
      items[itemID].itemID = itemID;
      items[itemID].tokenContract = tokenContract;
      items[itemID].totalAmount = totalAmount;
      items[itemID].price = price;
      items[itemID].restart = restart;
      items[itemID].period = period;
      items[itemID].startTime = block.timestamp;
      items[itemID].endTime = block.timestamp + period;
      delete items[itemID].buyers;
      delete items[itemID].buyerSets;
      delete items[itemID].rewardUserSets;
    } else { 
      delete items[itemID];
      for (uint256 i = 0; i < itemIDs.length; i++) {
        if (itemIDs[i] == itemID) {
          delete itemIDs[i];
          break;
        }
      }
    }
    return true;
  }
  
  
  function buyItem(uint256 itemID, address buyer, uint256 quantity) public onlyLogicContract returns (bool){
    require(items[itemID].itemID != 0, "item not exist"); 
    require(items[itemID].startTime <= block.timestamp, "item not start"); 
    require(items[itemID].endTime >= block.timestamp, "item already end"); 
    require(items[itemID].buyers.length + quantity <= (items[itemID].totalAmount / items[itemID].price), "item not enough"); 
    for (uint256 i = 0; i < quantity; i++) {
      items[itemID].buyers.push(buyer);
    }
    if (items[itemID].buyQuantity[buyer] == 0) { 
      items[itemID].buyerSets.push(buyer);  
    }
    items[itemID].buyQuantity[buyer] += quantity;
    return true;
  }

  
  function addRewardUser(uint256 itemID, address user, uint256 amount) public onlyLogicContract returns (bool){
    require(items[itemID].itemID != 0, "item not exist"); 
    require(items[itemID].buyQuantity[user] > 0, "item not buy"); 
    if (items[itemID].rewardAmount[user] == 0) { 
      items[itemID].rewardUserSets.push(user);  
    }
    items[itemID].rewardAmount[user] += amount;
    return true;
  }

  
  function addItemLog(uint256 itemID, address tokenContract, uint256 startTime, address winner, uint256 quantity, uint256 bonus) private {
    
  }

  
  function transfer(address tokenContract, address to, uint256 amount) public onlyLogicContract returns (bool){
    if (tokenContract == address(0)) { 
      payable(to).transfer(amount);
    } else { 
      IERC20(tokenContract).transfer(to, amount);
    }
    return true;
  }

  
  function refundItem(uint256 itemID) public onlyLogicContract returns (bool) {
    require(items[itemID].itemID != 0, "item not exist"); 
    require(items[itemID].startTime <= block.timestamp, "item not start"); 
    require(items[itemID].endTime <= block.timestamp, "item not end"); 
    require(items[itemID].buyers.length < (items[itemID].totalAmount / items[itemID].price), "item already enough"); 
    for (uint256 i = 0; i < items[itemID].buyerSets.length; i++) {
      address buyer = items[itemID].buyerSets[i];
      uint256 quantity = items[itemID].buyQuantity[buyer];
      uint256 amount = quantity * items[itemID].price;
      transfer(items[itemID].tokenContract, buyer, amount); 
    }
    addItemLog(itemID, items[itemID].tokenContract, items[itemID].startTime, address(0), 0, 0); 
    cleanItem(itemID); 
    return true;
  }

  
  function rewardItem(uint256 itemID,uint256 winnerIndex, address platform) public onlyLogicContract returns (bool, address, uint256, uint256) {
    require(items[itemID].itemID != 0, "item not exist"); 
    require(items[itemID].buyers.length >= (items[itemID].totalAmount / items[itemID].price), "item not enough"); 
    uint256 balance = items[itemID].totalAmount;
    address winner = items[itemID].buyers[winnerIndex];
    uint256 quantity = items[itemID].buyQuantity[winner];
    transfer(items[itemID].tokenContract, winner, items[itemID].bonusAmount); 
    balance -= items[itemID].bonusAmount;
    
    for (uint256 i = 0; i < items[itemID].rewardUserSets.length; i++) {
      address user = items[itemID].rewardUserSets[i];
      uint256 amount = items[itemID].rewardAmount[user];
      transfer(items[itemID].tokenContract, user, amount); 
      balance -= amount;
    }
    cleanItem(itemID); 
    
    transfer(items[itemID].tokenContract, platform, balance);
    
    itemLogs[itemID].push(
      LuckBuyItemLog(
        itemID,
        items[itemID].tokenContract,
        items[itemID].startTime,
        winner,
        quantity,
        items[itemID].bonusAmount
      )
    );
    return (true, winner, quantity, items[itemID].bonusAmount);
  }

  receive() external payable {
    
  }

}