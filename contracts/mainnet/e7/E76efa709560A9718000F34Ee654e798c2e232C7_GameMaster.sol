// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import { EntryTicket } from "./EntryTicket.sol";
import { AccessControl } from "./AccessControl.sol"; 
import { ERC20 } from "./ERC20.sol";

contract GameMaster is AccessControl {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
  bytes32 public constant GAME_MASTER = keccak256("GAME_MASTER");

  struct RedemptionInfo {
    uint256 amount;
    uint256 ticketId;
    uint256 timestamp;
  }

  EntryTicket entryTicket;

  uint256 public maxLimitPerUser;
  uint256 public redemptionTimeLock;

  mapping(address => uint256) public redemptionPerUser;
  mapping(address => mapping(uint256 => uint256)) public redemptionTime;
  mapping(address => mapping(uint256 => RedemptionInfo)) public redemptionInfo;
  mapping(address => mapping(uint256 => uint256)) public redemptionTicketAmountPerUser;

  address public GCOIN;

  mapping(bytes32 => bool) public matchRewards;

  mapping(uint256 => uint256) public gCoinCostPerTicket;
  
  event REDEMPTION(uint256 ticketId, uint256 amount, string playfabId, address player, uint256 timestamp);
  event MINTER_GRANTED(address _beneficiary);
  event MINTER_REMOVED(address _beneficiary);
  event BURNER_GRANTED(address _beneficiary);
  event BURNER_REMOVED(address _beneficiary);
  event GAME_MASTER_GRANTED(address _beneficiary);
  event GAME_MASTER_REMOVED(address _beneficiary);
  event MatchAlreadyProcessed(bytes32 matchId);
  event MatchComplete(bytes32 matchId);
  event RedeemGCoin(address _beneficiary, uint256 amount);

  constructor(EntryTicket _entryTicket, uint256 _cost, address gCoin, uint256 _maxLimitPerUser, uint256 _redemptionTimeLock) {
    entryTicket = _entryTicket;
    gCoinCostPerTicket[1] = _cost;
    GCOIN = gCoin;
    maxLimitPerUser = _maxLimitPerUser;
    redemptionTimeLock = _redemptionTimeLock;

    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  /****** Onwer functions  ******/

  function grantMinter(address _beneficiary) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _grantRole(MINTER_ROLE, _beneficiary);
    emit MINTER_GRANTED(_beneficiary);
  }

  function removeMinter(address _beneficiary) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _revokeRole(MINTER_ROLE, _beneficiary);
    emit MINTER_REMOVED(_beneficiary);
  }

  function grantBurner(address _beneficiary) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _grantRole(BURNER_ROLE, _beneficiary);
    emit BURNER_GRANTED(_beneficiary);
  }

  function removeBurner(address _beneficiary) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _revokeRole(BURNER_ROLE, _beneficiary);
    emit BURNER_REMOVED(_beneficiary);
  }

  function grantGameMaster(address _beneficiary) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _grantRole(GAME_MASTER, _beneficiary);
    emit GAME_MASTER_GRANTED(_beneficiary);
  }

  function removeGameMaster(address _beneficiary) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _revokeRole(GAME_MASTER, _beneficiary);
    emit GAME_MASTER_REMOVED(_beneficiary);
  }

  function setGCoinCostPerTicket(uint256 _ticketId, uint256 _cost) external onlyRole(DEFAULT_ADMIN_ROLE) {
    gCoinCostPerTicket[_ticketId] = _cost;
  }

  function setMaxLimitPerUser(uint256 _maxLimitPerUser) external onlyRole(DEFAULT_ADMIN_ROLE) {
    maxLimitPerUser = _maxLimitPerUser;
  }

  function setRedemptionTimeLock(uint256 _redemptionTimeLock) external onlyRole(DEFAULT_ADMIN_ROLE) {
    redemptionTimeLock = _redemptionTimeLock;
  }

  /****** Public functions  ******/
  function redemption(uint256 ticketId, uint256 amount, string memory playfabId, uint256 redeemId) public {
    _redemption(ticketId, amount, playfabId, _msgSender(), redeemId);
  }

  function redemptionAdmin(uint256 ticketId, uint256 amount, string memory playfabId, address player, uint256 redeemId) public onlyRole(GAME_MASTER) {
    _redemption(ticketId, amount, playfabId, player, redeemId);
  }

  function redeemGCoin(uint256 redeemId, uint256 ticketId) public {
    RedemptionInfo memory rInfo = redemptionInfo[_msgSender()][redeemId];
    uint256 amount = rInfo.amount;
    require(amount > 0, "insufficient amount to redeem");
    require(gCoinCostPerTicket[ticketId] > 0, "invalid ticket id");
    require(rInfo.ticketId == ticketId, "wrong ticket id");
    require(rInfo.timestamp + redemptionTimeLock <= block.timestamp, "redeem locked");
    require(entryTicket.balanceOf(_msgSender(), ticketId) >= amount, "insufficient user balance to redeem");

    redemptionPerUser[_msgSender()] -= amount;
    entryTicket.burn(_msgSender(), ticketId, amount);
    redemptionTicketAmountPerUser[_msgSender()][ticketId] -= amount;

    delete redemptionInfo[_msgSender()][redeemId];
    require(ERC20(GCOIN).transfer(_msgSender(), amount * gCoinCostPerTicket[ticketId]), "transfer failed");
    emit RedeemGCoin(_msgSender(), amount * gCoinCostPerTicket[ticketId]);
  }

  function matchReward(address[] memory receivingAddreses, uint256[] memory receivingAmounts, address[] memory burningAddresses, uint256[] memory burningAmounts, bytes32 matchId) public onlyRole(GAME_MASTER) {
    require(receivingAddreses.length == receivingAmounts.length, "receiving addresses length should be same as amounts length");
    require(burningAddresses.length == burningAmounts.length, "burning addresses length should be same as amounts length");
    if(matchRewards[matchId]) {
      emit MatchAlreadyProcessed(matchId);
      return;
    }
    uint256 totalReceiving;

    for (uint8 i; i < receivingAmounts.length; i ++) {
      totalReceiving += receivingAmounts[i];
    }

    require(totalReceiving <= entryTicket.balanceOf(address(this), 1), "insufficient ticket balance");

    for (uint8 i; i < receivingAddreses.length; i ++) {
      entryTicket.safeTransferFrom(address(this), receivingAddreses[i], 1, receivingAmounts[i], "");
    }

    for (uint8 i; i < burningAddresses.length; i ++) {
      require(burningAmounts[i] <= entryTicket.balanceOf(burningAddresses[i], 1), "insufficient burning amount");
      entryTicket.burn(burningAddresses[i], 1, burningAmounts[i]);
    }
    matchRewards[matchId] = true;

    emit MatchComplete(matchId);
  }

  function burnTicket(uint256 ticketId, uint256 amount, address player) public onlyRole(BURNER_ROLE) {
    require(entryTicket.balanceOf(player, ticketId) >= amount, "insufficient ticket amount");

    entryTicket.burn(player, ticketId, amount);
  }

  function mintTicket(uint256 ticketId, uint256 amount, address player) public onlyRole(MINTER_ROLE) {
    entryTicket.mint(player, ticketId, amount, "");
  }

  function mintTicketWithGCoin(uint256 ticketId, uint256 amount) public {
    require(gCoinCostPerTicket[ticketId] > 0, "invalid ticket id");
    require(ERC20(GCOIN).balanceOf(_msgSender()) >= amount * gCoinCostPerTicket[ticketId], "insufficient gcoin amount");
    require(ERC20(GCOIN).allowance(_msgSender(), address(this)) >= amount * gCoinCostPerTicket[ticketId], "insufficient gcoin allowance");
    require(ERC20(GCOIN).transferFrom(_msgSender(), address(this), amount * gCoinCostPerTicket[ticketId]), "transfer failed");

    entryTicket.mint(_msgSender(), ticketId, amount, "");
  }

  function withdrawGCoin(address receiver) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(receiver != address(0), "invalid receiver");
    require(ERC20(GCOIN).transfer(receiver, ERC20(GCOIN).balanceOf(address(this))), "transfer failed");
  }

  function getRedemptionForUser(address user) external view returns(uint256) {
    return redemptionPerUser[user];
  }

  function getTicketBalanceForUser(address user, uint256 ticketId) external view returns(uint256) {
    uint256 userBalance = entryTicket.balanceOf(user, ticketId);
    uint256 redemptionAmount = redemptionTicketAmountPerUser[user][ticketId];
    return userBalance > redemptionAmount ? userBalance - redemptionAmount : 0;
  }

  function getRedemptionInfo(address user, uint256 redeemId) external view returns(RedemptionInfo memory) {
    return redemptionInfo[user][redeemId];
  }

  function _redemption(uint256 ticketId, uint256 amount, string memory playfabId, address player, uint256 redeemId) internal {
    require(gCoinCostPerTicket[ticketId] > 0, "invalid ticket id");
    require(entryTicket.balanceOf(player, ticketId) >= amount + redemptionTicketAmountPerUser[player][ticketId], "insufficient ticket amount");
    require(redemptionPerUser[player] + amount <= maxLimitPerUser, "user redemption limit reached");

    redemptionTicketAmountPerUser[player][ticketId] = redemptionTicketAmountPerUser[player][ticketId] + amount;
    redemptionPerUser[player] = redemptionPerUser[player] + amount;
    redemptionInfo[player][redeemId] = RedemptionInfo(amount, ticketId, block.timestamp);

    emit REDEMPTION(ticketId, amount, playfabId, player, block.timestamp);
  }
}