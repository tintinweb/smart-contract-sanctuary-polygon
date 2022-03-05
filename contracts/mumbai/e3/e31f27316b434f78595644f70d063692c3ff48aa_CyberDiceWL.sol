/**
 *Submitted for verification at polygonscan.com on 2022-03-04
*/

// File: contracts/CyberDiceWL.sol


pragma solidity ^0.8.0;

contract CyberDiceWL {
  /**
    @dev structs and enums
   */
  enum BetRisk {
    low,
    med,
    high
  }

  struct Bet {
    address user;
    uint256 minimumBlockNumberForRoll;
    uint256 cap;
    BetRisk risk;
  }

  /**
    @dev events
   */

  event BetPlaced(
    uint256 _id,
    address _user,
    uint256 _cap,
    BetRisk risk
  );

  event Roll(uint256 _id, uint256 _cap, uint256 _rolled, uint256 winnings);
  
  /**
    @dev global variables
   */

  uint256 gameStartedBlockTimeStamp;
  address public admin;
  uint256 counter = 0;
  uint256 blockNumber = 0;
  mapping(uint256 => Bet) public bets;
  mapping(address => uint256) public winnings;

  /**
    @dev game parameters
   */
  uint256 public constant MAXIMUM_CAP = 12;

  /**
    @dev play around with numbers underneath to change odds/winnings/price
    all enums are of the same lenght to allow for simple swithcing from 'control center'
   */

  uint256[] public odds = [12, 12, 12]; //6, 4, 2
  uint256[] public winningAmounts = [1, 5, 10];
  uint256[] public riskTaxes = [0.1 ether, 0.05 ether, 0.025 ether];
  uint256 public maximumNumberOfWL;
  uint256 public whitelistedCounter = 0;

  constructor() {
    admin = msg.sender;
  }

  function getCurrentPrice(BetRisk riskLevel) public view returns (uint256 price) {
    return riskTaxes[uint256(riskLevel)];
  }

  function placeBet(BetRisk riskLevel) public payable {

    require(msg.value >= getCurrentPrice(riskLevel), 'msg.value LESS THAN BET VALUE');
    counter++;
    bets[counter] = Bet(
      msg.sender,
      block.number + 1,
      odds[uint256(riskLevel)],
      riskLevel
    );
    emit BetPlaced(
      counter,
      msg.sender,
      odds[uint256(riskLevel)],
      riskLevel
    );
  }

  function roll(uint256 id) public returns (uint256) {
    require(msg.sender == bets[id].user, 'ROLLER MUST HAVE SET BET');
    require(
      block.number >= bets[id].minimumBlockNumberForRoll,
      'CANT ROLL BEFORE 3 BLOCKS SINCE BET'
    );
    require(block.number <= bets[id].minimumBlockNumberForRoll + 255, 'TOO LATE');
    bytes32 random = keccak256(
      abi.encodePacked(blockhash(bets[id].minimumBlockNumberForRoll), id)
    );
    uint256 rolled = uint256(random) % MAXIMUM_CAP;

    if (rolled < bets[id].cap) {
      uint256 whitelistPayout = winningAmounts[uint256(bets[id].risk)];

      // if (maximumNumberOfWL < whitelistedCounter + whitelistPayout) {
      //   uint256 wlSpotsLeft = maximumNumberOfWL - whitelistedCounter;
      //   whitelistPayout = wlSpotsLeft;
      // }

      whitelistedCounter = whitelistedCounter + whitelistPayout;
      winnings[msg.sender] = winnings[msg.sender] + whitelistPayout;

      emit Roll(id, bets[id].cap, rolled, whitelistPayout);
    }

    emit Roll(id, bets[id].cap, rolled, 0);
    return rolled;
  }
}