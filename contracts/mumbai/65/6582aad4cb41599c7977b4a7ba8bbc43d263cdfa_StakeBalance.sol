/**
 *Submitted for verification at polygonscan.com on 2022-02-22
*/

// File: contracts/3_IStaker.sol



pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */


contract IStaker {
    mapping(uint32 => mapping(address => uint256)) public userNextPrice_stakedActionIndex;
    mapping(uint32 => mapping(bool => mapping(address => uint256))) public userNextPrice_amountStakedSyntheticToken_toShiftAwayFrom;
    mapping(uint32 => mapping(bool => mapping(address => uint256))) public userNextPrice_paymentToken_depositAmount;
    mapping(address => mapping(address => uint256)) public userAmountStaked;
    mapping(address => uint32) public marketIndexOfToken;
    mapping(uint32 => uint256) public latestRewardIndex;
    mapping(uint32 => mapping(bool => address)) public syntheticTokens;
    mapping(uint32 => mapping(address => uint256)) public userIndexOfLastClaimedReward;
}

// File: contracts/2_ILongShort.sol



pragma solidity >=0.7.0 <0.9.0;

/**
 * @title IStaker
 * @dev Set & change owner
 */
interface ILongShort {
  function get_syntheticToken_priceSnapshot_side(
    uint32,
    bool,
    uint256
  ) external view returns (uint256);

  function getAmountSyntheticTokenToMintOnTargetSide(
    uint32 marketIndex,
    uint256 amountSyntheticTokenShiftedFromOneSide,
    bool isShiftFromLong,
    uint256 priceSnapshotIndex
  ) external view returns (uint256 amountSynthShiftedToOtherSide);
}
// File: contracts/1_StakeBalance.sol



pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */



contract StakeBalance {
    address public owner;
    ILongShort public longShort;
    IStaker public staker;

        // creator and the assigned name.
    constructor(address _staker, address _longShort) {
        owner = msg.sender;

        staker = IStaker(_staker);
        longShort = ILongShort(_longShort);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner!");
        _;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function changeLongShort(address _newLongShort) public onlyOwner {
        longShort = ILongShort(_newLongShort);
    }

    function changeStaker(address _staker) onlyOwner public {
        staker = IStaker(_staker);
    }

    function userAmountStaked(address user, address token) public view returns(uint256 amountStaked) {
        amountStaked = staker.userAmountStaked(token, user);

        uint32 marketIndex = staker.marketIndexOfToken(token);
        uint256 stakerIndex = staker.latestRewardIndex(marketIndex);
        uint256 userIndex = staker.userNextPrice_stakedActionIndex(marketIndex, user);

        bool isLong = staker.syntheticTokens(marketIndex, true) == token;

        if(userIndex > 0 && userIndex <= stakerIndex){
            uint256 amountToken = staker.userNextPrice_amountStakedSyntheticToken_toShiftAwayFrom(
                marketIndex, isLong, user
            );
            if(amountToken > 0){
                amountStaked -= amountToken;
            }
            amountToken = staker.userNextPrice_amountStakedSyntheticToken_toShiftAwayFrom(marketIndex, !isLong, user);
            if(amountToken > 0){
                amountStaked += longShort.getAmountSyntheticTokenToMintOnTargetSide(marketIndex, amountToken, !isLong, userIndex);
            }
            amountToken = staker.userNextPrice_paymentToken_depositAmount(marketIndex, isLong, user);
            if(amountToken > 0){
                amountStaked += (amountToken * 1e18) / longShort.get_syntheticToken_priceSnapshot_side(marketIndex, isLong, userIndex);
            }
        }
    }
}