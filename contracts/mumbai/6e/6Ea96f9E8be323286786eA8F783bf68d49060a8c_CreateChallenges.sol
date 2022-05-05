pragma solidity 0.5.16;
import "./ChallengeDetails.sol";

contract CreateChallenges{
    using SafeMath for uint256;
    /**
     * @dev Value send to contract should be equal with `amount`.
     */
    modifier validateFee(uint256 _amount) {
        require(msg.value == _amount, "Invalid ETH fee");
        _;
    }
    /**
     * @dev Create new Challenge with token.
     * @param _stakeHolders : 0-sponsor, 1-challenger, 2-sever address, 3-token address
     * @param _primaryRequired : 0-duration, 1-start, 2-end, 3-goal, 4-day require
     * @param _totalReward : total reward token send to challenge
     * @param _awardReceivers : list receivers address
     * @param _awardReceiversApprovals : list award token for receiver address index slpit receiver array
     * @param _index : index slpit receiver array
     * @param _allowGiveUp : challenge allow give up or not
     * @param _gasData : 0-token for sever success, 1-token for sever fail, 2-eth for challenger transaction fee
     * @param _allAwardToSponsorWhenGiveUp : transfer all award back to sponsor or not
     */
    function CreateChallenge(
        address payable[] memory _stakeHolders,
        uint256[] memory _primaryRequired,
        uint256 _totalReward,
        address payable[] memory _awardReceivers,
        uint256[] memory _awardReceiversApprovals,
        uint256 _index,
        bool _allowGiveUp,
        uint256[] memory _gasData,
        bool _allAwardToSponsorWhenGiveUp
    )
    public
    payable
    validateFee(_gasData[2])
    returns (address challengeAddress)
    {
        ChallengeDetails newChallengeDetails = (new ChallengeDetails).value(msg.value)(
            _stakeHolders,
            _primaryRequired,
            _totalReward,
            _awardReceivers,
            _awardReceiversApprovals,
            _index,
            _allowGiveUp,
            _gasData,
            _allAwardToSponsorWhenGiveUp
        );      
        IERC20(_stakeHolders[3]).transferFrom(msg.sender, address(newChallengeDetails), _totalReward + _gasData[0]);
        return address(newChallengeDetails);
    }
}