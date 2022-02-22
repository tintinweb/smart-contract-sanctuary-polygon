// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./RandomSeedInterface.sol";

contract RandomSeedContract is RandomSeedInterface {
  struct Seed {
    bool isUsed; // TODO: 默认值 反了；需要调整
    uint256 seed;
  }

  constructor() { }

  mapping(address => bytes32) private rRSIOfAllPlayers; // player address => request Random Seed ID
  mapping(address => mapping(bytes32 => Seed)) private seedOfAllPlayers; // player address => random seed

  function requestRandomNumber() external payable returns (bytes32 requestId) {
    rRSIOfAllPlayers[tx.origin] = 'MockTest';
    seedOfAllPlayers[tx.origin]['MockTest'].seed = 115792089237316195423570985008687907853269984665640564039458;
    seedOfAllPlayers[tx.origin]['MockTest'].isUsed = false;
    // TODO: 增加 event 方便外部读取 event Test(bytes32 requestId); emit Test('MockTest');
    return 'MockTest';
  }

  function getRandomNumber(uint8 overValue, bool startZero, uint8 rangeStart, uint8 rangeEnd) external view returns (uint8[] memory numbers) {
    require(
      rangeEnd > rangeStart,
      'invalid range'
      );
    require(
      rangeEnd > 0,
      'invalid range'
      );
    bytes32 id = rRSIOfAllPlayers[tx.origin];
    bool isUsed = seedOfAllPlayers[tx.origin][id].isUsed;
    require(
      isUsed == false,
      'random seed is used'
      );
    uint256 seed = seedOfAllPlayers[tx.origin][id].seed;
    require(
      seed != 0,
      'need request random number'
      );
    return _createRandomNumber(seed, overValue, startZero, rangeStart, rangeEnd);
  }

  function _createRandomNumber(uint256 seed, uint8 overValue, bool startZero, uint8 rangeStart, uint8 rangeEnd) internal pure returns (uint8[] memory numbers) {
    uint8 count = rangeEnd - rangeStart;
    uint8[] memory expandedValues = new uint8[](count);
    for (uint8 i = rangeStart; i < rangeEnd; i++) {
      uint8 random = uint8(uint256(keccak256(abi.encode(seed, i))) % overValue);
      if (startZero == false) {
        random++;
      }
      expandedValues[i - rangeStart] = random;
    }
    return expandedValues;
  }

  function markRandomSeedUsed() external {
    bytes32 id = rRSIOfAllPlayers[tx.origin];
    seedOfAllPlayers[tx.origin][id].isUsed = true;
  }

  function checkSeed() external view returns (bool isUsed) {
    bytes32 id = rRSIOfAllPlayers[tx.origin];
    return seedOfAllPlayers[tx.origin][id].isUsed;
  }
}

/**
import "@openzeppelin/[email protected]/utils/math/SafeMath.sol";

struct Ticket {
  uint256 expiredTicketsTimestamp;
  bool isGameOver;
  uint256 roundRoundNumber;
}

struct GameRound {
  bool ended;
  uint256 soldTicketCount;
  uint256 soldTicketFee;
  uint256 sponsorshipFee;
}

contract RlyehContract {
  using SafeMath for *;

// GAME DATA 
//****************
    mapping(address => Ticket) public ticketOfAllPlayers; // player address => ticket data

// ENGINE DATA 
//****************
  uint256 currentRoundNumber; // start timestamp
  mapping(uint256 => GameRound) public roundOfAllGame; // round number => GameRound data

  constructor() {
    
    }

    // function buyTicket(uint8 ticketValidDay, address inviter) external payable {
  function buyTicket(uint8 ticketValidDay) external payable {
      require(
            (ticketValidDay == 1 || ticketValidDay == 2 || ticketValidDay == 3),
            "Invalid ticket valid day"
        );

        require(msg.value == 0.1 ether);
        // (bool sent, bytes memory data)
      (bool sent,) = payable(msg.sender).call{value: msg.value}("");
        require(sent, "Failed to send Ether");

      // if (licenseOfAllInviters[inviter][currentRoundNumber].isRegister == true) {
      //  licenseOfAllInviters[inviter][currentRoundNumber].numberOfInvitees += 1;
      // }

        ticketOfAllPlayers[msg.sender].expiredTicketsTimestamp = block.timestamp + 86400 * ticketValidDay;
        ticketOfAllPlayers[msg.sender].roundRoundNumber = currentRoundNumber;
        ticketOfAllPlayers[msg.sender].isGameOver = false;
    }
}
/**
// interface DaiToken {
//     function transfer(address dst, uint wad) external returns (bool);
//     function balanceOf(address guy) external view returns (uint);
// }

// INVITATION SYSTEM
//==============================================================================

// INVITATION DATA
//****************
  DaiToken daitoken;

  uint256 public ticketPriceOfOnePlayer = 1 * 10 * 18;
  uint256 public inviterFeeRate = 65; // ‰ of inviter fee

  struct InviterLicense {
    uint256 numberOfInvitees;
    bool isWithdraw;
    bool isRegister;
  }
  mapping(address => mapping(uint256 => InviterLicense)) public licenseOfAllInviters;
  
  function registerAnInviter(uint256 roundNumber) external {
    licenseOfAllInviters[msg.sender][roundNumber].numberOfInvitees = 0;
    licenseOfAllInviters[msg.sender][roundNumber].isWithdraw = false;
    licenseOfAllInviters[msg.sender][roundNumber].isRegister = true;
  }

  function withdrawInviterFee(uint256 roundNumber) external {
    require(
      licenseOfAllInviters[msg.sender][roundNumber].numberOfInvitees != 0,
      "Invalid number of invitees"
    );
    require(
      licenseOfAllInviters[msg.sender][roundNumber].isWithdraw == false,
      "License is withdraw"
    );
    require(
      licenseOfAllInviters[msg.sender][roundNumber].isRegister == true,
      "License is not register"
    );
    require(
      roundOfAllGame[roundNumber].ended == true,
      "Only ended rounds can be withdraw"
    );
    uint256 soldTicketCount = roundOfAllGame[roundNumber].soldTicketCount;
    uint256 numberOfInvitees = licenseOfAllInviters[msg.sender][roundNumber].numberOfInvitees;
    uint256 inviterFee = soldTicketCount.mul(numberOfInvitees).mul(ticketPriceOfOnePlayer).mul(inviterFeeRate).div(1000); 
    daitoken.transfer(msg.sender, inviterFee);
    licenseOfAllInviters[msg.sender][roundNumber].isWithdraw == true;
  }

// MANAGEMENT INTERFACE
//****************
*/