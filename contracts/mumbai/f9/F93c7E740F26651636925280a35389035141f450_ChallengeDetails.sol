// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

import "./SafeMath.sol";
import "./TanimoToken.sol";
/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */

contract Challenge{
    using SafeMath for uint256;

    /** @param ChallengeState currentState of challenge:
         1 : in processs
         2 : success
         3 : failed
         4 : gave up
         5 : closed
    */
    enum ChallengeState{
        PROCESSING,
        SUCCESS,
        FAILED,
        GAVE_UP,
        CLOSED
    }

    /** @dev securityAddress address to verify app signature.
    */
    address constant private securityAddress = 0x547d99b46B58C313F95A09913C517dB4E42437aB;

    /** @dev sponsor sponsor of challenge.
    */
    address payable public sponsor;

    /** @dev challenger challenger of challenge.
    */
    address payable public challenger;

    /** @dev serverAddress serverAddress of challenge.
    */
    address payable serverAddress;

    /** @dev awardReceivers list of receivers when challenge success and fail, start by success list.
    */
    address payable[] public awardReceivers;

    /** @dev awardReceiversApprovals list of award for receivers when challenge success and fail, start by success list.
    */
    uint256[] public awardReceiversApprovals;

    /** @dev historyData number of steps each day in challenge.
    */
    uint256[] historyData;

    /** @dev historyDate date in challenge.
    */
    uint256[] historyDate;

    /** @dev index index to split array receivers.
    */
    uint256 public index;

    /** @dev totalReward total reward receiver can receive in challenge.
    */
    uint256 public totalReward;

    /** @dev gasFee ETH for challenger transaction fee. Transfer for challenger when create challenge.
    */
    uint256 public gasFee;

    /** @dev serverSuccessFee ETH for sever when challenge success.
    */
    uint256 public serverSuccessFee;

    /** @dev serverFailureFee ETH for sever when challenge fail.
    */
    uint256 public serverFailureFee;

    /** @dev duration duration of challenge from start to end time.
    */
    uint256 public duration;

    /** @dev startTime startTime of challenge.
    */
    uint256 public startTime;

    /** @dev endTime endTime of challenge.
    */
    uint256 public endTime;

    /** @dev dayRequired number of day which challenger need to finish challenge.
    */
    uint256 public dayRequired;

    /** @dev goal number of steps which challenger need to finish in day.
    */
    uint256 public goal;

    /** @dev currentStatus currentStatus of challenge.
    */
    uint256 currentStatus;

    /** @dev sumAwardSuccess sumAwardSuccess of challenge.
    */
    uint256 sumAwardSuccess;

    /** @dev sumAwardFail sumAwardFail of challenge.
    */
    uint256 sumAwardFail;

    /** @dev sequence submit daily result count number of challenger.
    */
    uint256 sequence;

    /** @dev allowGiveUp challenge allow give up or not.
    */
    bool public allowGiveUp;

    /** @dev isFinished challenge finish or not.
    */
    bool public isFinished;

    /** @dev isSuccess challenge success or not.
    */
    bool public isSuccess;

    /** @dev choiceAwardToSponsor all award will go to sponsor wallet when challenger give up or not.
    */
    bool public choiceAwardToSponsor;

    /** @dev selectGiveUpStatus challenge need be give up one time.
    */
    bool selectGiveUpStatus;

    /** @dev approvalSuccessOf get amount of ETH an `address` can receive when ckhallenge success.
    */
    mapping(address => uint256) public approvalSuccessOf;

    /** @dev approvalFailOf get amount of ETH an `address` can receive when challenge fail.
    */
    mapping(address => uint256) public approvalFailOf;

    /** @dev stepOn get step on a day.
    */
    mapping(uint256 => uint256) public stepOn;

    /** @dev verifyMessage keep track and reject double secure message.
    */
    mapping(string => bool) public verifyMessage;

    event SendDailyResult(uint256 indexed currentStatus);
    event FundTransfer(address indexed to, uint256 indexed valueSend);
    event GiveUp(address indexed from);
    event CloseChallenge(bool indexed challengeStatus);

    /**
     * @dev Action should be called in challenge time.
     */
    modifier onTime() {
        require(block.timestamp >= startTime, "Challenge has not started yet");
        require(block.timestamp <= endTime, "Challenge was finished");
        _;
    }

    /**
     * @dev Action should be called in required time.
     */
    modifier onTimeSendResult() {
        require(block.timestamp <= endTime.add(2 days), "Challenge was finished");
        require(block.timestamp >= startTime, "Challenge has not started yet");
        _;
    }

    /**
     * @dev Action should be called after challenge start.
     */
    modifier mustStart() {
        require(block.timestamp >= startTime, "Challenge has not started yet");
        _;
    }

    /**
     * @dev Action should be called after challenge finish.
     */
    modifier afterFinish() {
        require(block.timestamp > endTime.add(2 days), "Challenge has not finished yet");
        _;
    }

    /**
     * @dev Action should be called when challenge is running.
     */
    modifier available() {
        require(!isFinished, "Challenge was finished");
        _;
    }

    /**
     * @dev Action should be called when challenge was allowed give up.
     */
    modifier canGiveUp() {
        require(allowGiveUp, "Can not give up");
        _;
    }

    /**
     * @dev Value send to contract should be equal with `amount`.
     */
    modifier validateAward(uint256 _amount) {
        require(msg.value == _amount, "Invalid award");
        _;
    }

    /**
     * @dev Action only called from sever or sponsor.
     */
    modifier onlyServerOrSponsor() {
        require(msg.sender == serverAddress || msg.sender == sponsor, "You do not have right");
        _;
    }

    /**
     * @dev User only call give up one time.
     */
    modifier notSelectGiveUp() {
        require(!selectGiveUpStatus, "This challenge was give up");
        _;
    }

    /**
     * @dev Action only called from stakeholders.
     */
    modifier onlyStakeHolders() {
        require(msg.sender == challenger || msg.sender == sponsor, "Only stakeholders can call this function");
        _;
    }

    /**
     * @dev Action only called from challenger.
     */
    modifier onlyChallenger() {
        require(msg.sender == challenger, "Only challenger can call this function");
        _;
    }

    /**
     * @dev verify app signature.
     */
    modifier verifySignature(string memory message, uint8 v, bytes32 r, bytes32 s) {
        require(securityAddress == verifyString(message, v, r, s), "Cant send");
        _;
    }

    /**
     * @dev verify double sending message.
     */
    modifier rejectDoubleMessage(string memory message) {
        require(!verifyMessage[message], "Cant send");
        _;
    }

    /**
     * @dev verify challenge success or not before close.
     */
    modifier availableForClose() {
        require(!isSuccess && !isFinished, "Cant call");
        _;
    }

    ChallengeState stateInstance;

    /**
     * @dev The Challenge constructor.
     * @param _stakeHolders : 0-sponsor, 1-challenger, 2-sever address
     * @param _primaryRequired : 0-duration, 1-start, 2-end, 3-goal
     * @param _totalReward : total amount send to challenge
     * @param _awardReceivers : list receivers address
     * @param _awardReceiversApprovals : list award for receiver address
     * @param _index : index slpit receiver array
     * @param _allowGiveUp : challenge allow give up or not
     * @param _gasData : 0-gas for sever success, 1-gas for sever fail, 2-eth for challenger transaction fee
     * @param _allAwardToSponsorWhenGiveUp : transfer all award back to sponsor or not
     */
    constructor(
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
    validateAward(_totalReward)
    {
        uint256 i;
        require(_index > 0, "Invalid value");
        require(_awardReceivers.length == _awardReceiversApprovals.length, "Invalid lists");

        for (i = 0; i < _index; i++) {
            require(_awardReceiversApprovals[i] > 0, "Invalid value0");
            approvalSuccessOf[_awardReceivers[i]] = _awardReceiversApprovals[i];
            sumAwardSuccess = sumAwardSuccess.add(_awardReceiversApprovals[i]);
        }
        //require(sumAwardSuccess.add(_gasData[2].add(_gasData[0])) == msg.value, "Invalid value1");

        for (i = _index; i < _awardReceivers.length; i++) {
            require(_awardReceiversApprovals[i] > 0, "Invalid value1");
            approvalFailOf[_awardReceivers[i]] = _awardReceiversApprovals[i];
            sumAwardFail = sumAwardFail.add(_awardReceiversApprovals[i]);
        }
        // require(sumAwardFail.add(_gasData[2].add(_gasData[1])) == msg.value, "Invalid value");

        sponsor = _stakeHolders[0];
        challenger = _stakeHolders[1];
        serverAddress = _stakeHolders[2];
        duration = _primaryRequired[0];
        startTime = _primaryRequired[1];
        endTime = _primaryRequired[2];
        goal = _primaryRequired[3];
        dayRequired = _primaryRequired[4];
        stateInstance = ChallengeState.PROCESSING;
        awardReceivers = _awardReceivers;
        awardReceiversApprovals = _awardReceiversApprovals;
        index = _index;
        serverSuccessFee = _gasData[0];
        serverFailureFee = _gasData[1];
        gasFee = _gasData[2];
        challenger.transfer(gasFee);
        emit FundTransfer(challenger, gasFee);
        totalReward = _totalReward.sub(gasFee);
        allowGiveUp = _allowGiveUp;
        if (_allowGiveUp && _allAwardToSponsorWhenGiveUp) choiceAwardToSponsor = true;
    }

    /**
     * @dev Send daily result to challenge with security message and signature app.
     */
    function sendDailyResult(uint256[] memory _day, uint256[] memory _stepIndex, string memory message, uint8 v, bytes32 r, bytes32 s)
    public
    available
    onTimeSendResult
    onlyChallenger
    verifySignature(message, v, r, s)
    rejectDoubleMessage(message)
    {
        verifyMessage[message] = true;
        for (uint256 i = 0; i < _day.length; i++) {
            require(stepOn[_day[i]] == 0, "This day's data had already updated");
            stepOn[_day[i]] = _stepIndex[i];
            historyDate.push(_day[i]);
            historyData.push(_stepIndex[i]);
            if (_stepIndex[i] >= goal && currentStatus < dayRequired) {
                currentStatus = currentStatus.add(1);
            }
        }
        sequence = sequence.add(_day.length);
        if (sequence.sub(currentStatus) > duration.sub(dayRequired)){
            stateInstance = ChallengeState.FAILED;
            transferToListReceiverFail();
        } else {
            if (currentStatus >= dayRequired) {
                stateInstance = ChallengeState.SUCCESS;
                transferToListReceiverSuccess();
            }
        }
        emit SendDailyResult(currentStatus);
    }

    /**
     * @dev private funtion for verify message and singer.
     */
    function verifyString(string memory message, uint8 v, bytes32 r, bytes32 s) private pure returns(address signer)
    {
        string memory header = "\x19Ethereum Signed Message:\n000000";
        uint256 lengthOffset;
        uint256 length;
        assembly {
            length:= mload(message)
            lengthOffset:= add(header, 57)
        }
        require(length <= 999999, "Not provided");
        uint256 lengthLength = 0;
        uint256 divisor = 100000;
        while (divisor != 0) {
            uint256 digit = length / divisor;
            if (digit == 0) {
                if (lengthLength == 0) {
                    divisor /= 10;
                    continue;
                }
            }
            lengthLength++;
            length -= digit * divisor;
            divisor /= 10;
            digit += 0x30;
            lengthOffset++;
            assembly {
                mstore8(lengthOffset, digit)
            }
        }
        if (lengthLength == 0) {
            lengthLength = 1 + 0x19 + 1;
        } else {
            lengthLength += 1 + 0x19;
        }
        assembly {
            mstore(header, lengthLength)
        }
        bytes32 check = keccak256(abi.encodePacked(header, message));
        return ecrecover(check, v, r, s);
    }

    /**
     * @dev give up challenge.
     */
    function giveUp() external canGiveUp notSelectGiveUp onTime available onlyStakeHolders {
        uint256 amount = totalReward.sub(serverFailureFee);
        if (choiceAwardToSponsor) {
            sponsor.transfer(amount);
            emit FundTransfer(sponsor, amount);
        }
        else {
            uint256 amountToReceiverList = amount.mul(currentStatus).div(dayRequired);
            uint256 amountToSponsor = amount.sub(amountToReceiverList);
            sponsor.transfer(amountToSponsor);
            emit FundTransfer(sponsor, amountToSponsor);
            for (uint256 i = 0; i < index; i++) {
                uint256 amountTmp = approvalSuccessOf[awardReceivers[i]].mul(amountToReceiverList).div(amount);
                awardReceivers[i].transfer(amountTmp);
                emit FundTransfer(awardReceivers[i], amountTmp);
            }
        }
        serverAddress.transfer(serverFailureFee);
        emit FundTransfer(serverAddress, serverFailureFee);
        isFinished = true;
        selectGiveUpStatus = true;
        stateInstance = ChallengeState.GAVE_UP;
        emit GiveUp(msg.sender);
    }

    /**
     * @dev Close challenge.
     */
    function closeChallenge() external onlyStakeHolders afterFinish availableForClose
    {
        stateInstance = ChallengeState.CLOSED;
        transferToListReceiverFail();
    }

    /**
     * @dev Destroy challenge.
     */
    function destroyChallenge() external onlyServerOrSponsor {
        if (getContractBalance() > serverFailureFee) {
           serverAddress.transfer(serverFailureFee);
        }
        selfdestruct(sponsor);
    }

    /**
     * @dev Private function for transfer all award to receivers when challenge success.
     */
    function transferToListReceiverSuccess() private {
        serverAddress.transfer(serverSuccessFee);
        emit FundTransfer(serverAddress, serverSuccessFee);
        for (uint256 i = 0; i < index; i++) {
            awardReceivers[i].transfer(approvalSuccessOf[awardReceivers[i]]);
            emit FundTransfer(awardReceivers[i], approvalSuccessOf[awardReceivers[i]]);
        }
        isSuccess = true;
        isFinished = true;
    }

    /**
     * @dev Private function for transfer all award to receivers when challenge fail.
     */
    function transferToListReceiverFail() private {
        serverAddress.transfer(serverFailureFee);
        emit FundTransfer(serverAddress, serverFailureFee);
        for (uint256 i = index; i < awardReceivers.length; i++) {
            awardReceivers[i].transfer(approvalFailOf[awardReceivers[i]]);
            emit FundTransfer(awardReceivers[i], approvalFailOf[awardReceivers[i]]);
        }
        isFinished = true;
        emit CloseChallenge(false);
    }

    /**
     * @dev get balance of challenge.
     */
    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }

    /**
     * @dev get information of challenge.
     */
    function getChallengeInfo() external view returns(uint256 challengeCleared, uint256 challengeDayRequired, uint256 daysRemained) {
        return (
            currentStatus,
            dayRequired,
            dayRequired.sub(currentStatus)
        );
    }

    /**
     * @dev get history of challenge.
     */
    function getChallengeHistory() external view returns(uint256[] memory date, uint256[] memory data) {
        return (historyDate, historyData);
    }

    /**
     * @dev get state of challenge.
     */
    function getState() external view returns (ChallengeState) {
        return stateInstance;
    }

}

/**
 * @dev Interface of the ERC20 sCTOtandard as defined in the EIP.
 */
contract ChallengeDetails {
    using SafeMath for uint256;

    /** @param ChallengeState currentState of challenge:
         1 : in processs
         2 : success
         3 : failed
         4 : gave up
         5 : closed
    */
    enum ChallengeState{
        PROCESSING,
        SUCCESS,
        FAILED,
        GAVE_UP,
        CLOSED
    }

    /** @dev securityAddress address to verify app signature.
    */
    address constant private securityAddress = 0x547d99b46B58C313F95A09913C517dB4E42437aB;
    
    /** @dev tokenAddress address of erc-20 contract.
    */
    address private tokenAddress;

    /** @dev sponsor sponsor of challenge.
    */
    address payable public sponsor;

    /** @dev challenger challenger of challenge.
    */
    address payable public challenger;

    /** @dev serverAddress serverAddress of challenge.
    */
    address payable serverAddress;

    /** @dev awardReceivers list of receivers when challenge success and fail, start by success list.
    */
    address payable[] public awardReceivers;

    /** @dev awardReceiversApprovals list of award for receivers when challenge success and fail, start by success list.
    */
    uint256[] public awardReceiversApprovals;

    /** @dev historyData number of steps each day in challenge.
    */
    uint256[] historyData;

    /** @dev historyDate date in challenge.
    */
    uint256[] historyDate;

    /** @dev index index to split array receivers.
    */
    uint256 public index;

    /** @dev totalReward total reward receiver can receive in challenge.
    */
    uint256 public totalReward;

    /** @dev gasFee ETH for challenger transaction fee. Transfer for challenger when create challenge.
    */
    uint256 public gasFee;

    /** @dev serverSuccessFee ETH for sever when challenge success.
    */
    uint256 public serverSuccessFee;

    /** @dev serverFailureFee ETH for sever when challenge fail.
    */
    uint256 public serverFailureFee;

    /** @dev duration duration of challenge from start to end time.
    */
    uint256 public duration;

    /** @dev startTime startTime of challenge.
    */
    uint256 public startTime;

    /** @dev endTime endTime of challenge.
    */
    uint256 public endTime;

    /** @dev dayRequired number of day which challenger need to finish challenge.
    */
    uint256 public dayRequired;

    /** @dev goal number of steps which challenger need to finish in day.
    */
    uint256 public goal;

    /** @dev currentStatus currentStatus of challenge.
    */
    uint256 currentStatus;

    /** @dev sumAwardSuccess sumAwardSuccess of challenge.
    */
    uint256 sumAwardSuccess;

    /** @dev sumAwardFail sumAwardFail of challenge.
    */
    uint256 sumAwardFail;

    /** @dev sequence submit daily result count number of challenger.
    */
    uint256 sequence;

    /** @dev allowGiveUp challenge allow give up or not.
    */
    bool public allowGiveUp;

    /** @dev isFinished challenge finish or not.
    */
    bool public isFinished;

    /** @dev isSuccess challenge success or not.
    */
    bool public isSuccess;

    /** @dev choiceAwardToSponsor all award will go to sponsor wallet when challenger give up or not.
    */
    bool public choiceAwardToSponsor;

    /** @dev selectGiveUpStatus challenge need be give up one time.
    */
    bool selectGiveUpStatus;

    /** @dev approvalSuccessOf get amount of ETH an `address` can receive when ckhallenge success.
    */
    mapping(address => uint256) public approvalSuccessOf;

    /** @dev approvalFailOf get amount of ETH an `address` can receive when challenge fail.
    */
    mapping(address => uint256) public approvalFailOf;

    /** @dev stepOn get step on a day.
    */
    mapping(uint256 => uint256) public stepOn;

    /** @dev verifyMessage keep track and reject double secure message.
    */
    mapping(string => bool) public verifyMessage;

    event SendDailyResult(uint256 indexed currentStatus);
    event FundTransfer(address indexed to, uint256 indexed valueSend);
    event GiveUp(address indexed from);
    event CloseChallenge(bool indexed challengeStatus);

    /**
     * @dev Action should be called in challenge time.
     */
    modifier onTime() {
        require(block.timestamp >= startTime, "Challenge has not started yet");
        require(block.timestamp <= endTime, "Challenge was finished");
        _;
    }

    /**
     * @dev Action should be called in required time.
     */
    modifier onTimeSendResult() {
        require(block.timestamp <= endTime.add(2 days), "Challenge was finished");
        require(block.timestamp >= startTime, "Challenge has not started yet");
        _;
    }

    /**
     * @dev Action should be called after challenge start.
     */
    modifier mustStart() {
        require(block.timestamp >= startTime, "Challenge has not started yet");
        _;
    }

    /**
     * @dev Action should be called after challenge finish.
     */
    modifier afterFinish() {
        require(block.timestamp > endTime.add(2 days), "Challenge has not finished yet");
        _;
    }

    /**
     * @dev Action should be called when challenge is running.
     */
    modifier available() {
        require(!isFinished, "Challenge was finished");
        _;
    }

    /**
     * @dev Action should be called when challenge was allowed give up.
     */
    modifier canGiveUp() {
        require(allowGiveUp, "Can not give up");
        _;
    }

    /**
     * @dev Action only called from sever or sponsor.
     */
    modifier onlyServerOrSponsor() {
        require(msg.sender == serverAddress || msg.sender == sponsor, "You do not have right");
        _;
    }

    /**
     * @dev User only call give up one time.
     */
    modifier notSelectGiveUp() {
        require(!selectGiveUpStatus, "This challenge was give up");
        _;
    }

    /**
     * @dev Action only called from stakeholders.
     */
    modifier onlyStakeHolders() {
        require(msg.sender == challenger || msg.sender == sponsor, "Only stakeholders can call this function");
        _;
    }

    /**
     * @dev Action only called from challenger.
     */
    modifier onlyChallenger() {
        require(msg.sender == challenger, "Only challenger can call this function");
        _;
    }

    /**
     * @dev verify app signature.
     */
    modifier verifySignature(string memory message, uint8 v, bytes32 r, bytes32 s) {
        require(securityAddress == verifyString(message, v, r, s), "Cant send");
        _;
    }

    /**
     * @dev verify double sending message.
     */
    modifier rejectDoubleMessage(string memory message) {
        require(!verifyMessage[message], "Cant send");
        _;
    }

    /**
     * @dev verify challenge success or not before close.
     */
    modifier availableForClose() {
        require(!isSuccess && !isFinished, "Cant call");
        _;
    }

    ChallengeState stateInstance;

     /**
     * @dev The Challenge constructor.
     * @param _stakeHolders : 0-sponsor, 1-challenger, 2-sever address, 3-token address
     * @param _primaryRequired : 0-duration, 1-start, 2-end, 3-goal, 4-day require
     * @param _totalToken : total token send to challenge
     * @param _awardReceivers : list receivers address
     * @param _awardReceiversApprovals : list award token for receiver address index slpit receiver array
     * @param _index : index slpit receiver array
     * @param _allowGiveUp : challenge allow give up or not
     * @param _gasData : 0-token for sever success, 1-token for sever fail, 2-eth for challenger transaction fee
     * @param _allAwardToSponsorWhenGiveUp : transfer all award back to sponsor or not
     */
    constructor(
        address payable[] memory _stakeHolders,
        uint256[] memory _primaryRequired,
        uint256 _totalToken,
        address payable[] memory _awardReceivers,
        uint256[] memory _awardReceiversApprovals,
        uint256 _index,
        bool _allowGiveUp,
        uint256[] memory _gasData,
        bool _allAwardToSponsorWhenGiveUp
    )
    public
    payable
    {
        uint256 i;
        require(_index > 0, "Invalid value");
        require(_awardReceivers.length == _awardReceiversApprovals.length, "Invalid lists");

        for (i = 0; i < _index; i++) {
            require(_awardReceiversApprovals[i] > 0, "Invalid value");
            approvalSuccessOf[_awardReceivers[i]] = _awardReceiversApprovals[i];
            sumAwardSuccess = sumAwardSuccess.add(_awardReceiversApprovals[i]);
        }
        //require(sumAwardSuccess == _totalToken, "Invalid token value");

        for (i = _index; i < _awardReceivers.length; i++) {
            require(_awardReceiversApprovals[i] > 0, "Invalid value");
            approvalFailOf[_awardReceivers[i]] = _awardReceiversApprovals[i];
            sumAwardFail = sumAwardFail.add(_awardReceiversApprovals[i]);
        }
        //require(sumAwardFail == _totalToken, "Invalid token value");

        sponsor = _stakeHolders[0];
        challenger = _stakeHolders[1];
        serverAddress = _stakeHolders[2];
        tokenAddress = _stakeHolders[3];
        duration = _primaryRequired[0];
        startTime = _primaryRequired[1];
        endTime = _primaryRequired[2];
        goal = _primaryRequired[3];
        dayRequired = _primaryRequired[4];
        stateInstance = ChallengeState.PROCESSING;
        awardReceivers = _awardReceivers;
        awardReceiversApprovals = _awardReceiversApprovals;
        index = _index;
        serverSuccessFee = _gasData[0];
        serverFailureFee = _gasData[1];
        gasFee = _gasData[2];
        challenger.transfer(gasFee);
        emit FundTransfer(challenger, gasFee);
        totalReward = _totalToken;
        allowGiveUp = _allowGiveUp;
        if (allowGiveUp && _allAwardToSponsorWhenGiveUp) choiceAwardToSponsor = true;
    }

    /**
     * @dev Send daily result to challenge with security message and signature app.
     */
    function sendDailyResult(uint256[] memory _day, uint256[] memory _stepIndex, string memory message, uint8 v, bytes32 r, bytes32 s)
    public
    available
    onTimeSendResult
    onlyChallenger
    verifySignature(message, v, r, s)
    rejectDoubleMessage(message)
    {
        verifyMessage[message] = true;
        for (uint256 i = 0; i < _day.length; i++) {
            require(stepOn[_day[i]] == 0, "This day's data had already updated");
            stepOn[_day[i]] = _stepIndex[i];
            historyDate.push(_day[i]);
            historyData.push(_stepIndex[i]);
            if (_stepIndex[i] >= goal && currentStatus < dayRequired) {
                currentStatus = currentStatus.add(1);
            }
        }
        sequence = sequence.add(_day.length);
        if (sequence.sub(currentStatus) > duration.sub(dayRequired)){
            stateInstance = ChallengeState.FAILED;
            transferToListReceiverFail();
        } else {
            if (currentStatus >= dayRequired) {
                stateInstance = ChallengeState.SUCCESS;
                transferToListReceiverSuccess();
            }
        }
        emit SendDailyResult(currentStatus);
    }

    /**
     * @dev private funtion for verify message and singer.
     */
    function verifyString(string memory message, uint8 v, bytes32 r, bytes32 s) private pure returns(address signer)
    {
        string memory header = "\x19Ethereum Signed Message:\n000000";
        uint256 lengthOffset;
        uint256 length;
        assembly {
            length:= mload(message)
            lengthOffset:= add(header, 57)
        }
        require(length <= 999999, "Not provided");
        uint256 lengthLength = 0;
        uint256 divisor = 100000;
        while (divisor != 0) {
            uint256 digit = length / divisor;
            if (digit == 0) {
                if (lengthLength == 0) {
                    divisor /= 10;
                    continue;
                }
            }
            lengthLength++;
            length -= digit * divisor;
            divisor /= 10;
            digit += 0x30;
            lengthOffset++;
            assembly {
                mstore8(lengthOffset, digit)
            }
        }
        if (lengthLength == 0) {
            lengthLength = 1 + 0x19 + 1;
        } else {
            lengthLength += 1 + 0x19;
        }
        assembly {
            mstore(header, lengthLength)
        }
        bytes32 check = keccak256(abi.encodePacked(header, message));
        return ecrecover(check, v, r, s);
    }

    /**
     * @dev give up challenge.
     */
    function giveUp() external canGiveUp notSelectGiveUp onTime available onlyStakeHolders {
        if (choiceAwardToSponsor) {
            TanimoToken(tokenAddress).transfer(sponsor, totalReward);
        }
        else {
            uint256 amountToReceiverList = totalReward.mul(currentStatus).div(dayRequired);
            uint256 amountToSponsor = totalReward.sub(amountToReceiverList);
            TanimoToken(tokenAddress).transfer(sponsor, amountToSponsor);
            for (uint256 i = 0; i < index; i++) {
                uint256 amountTmp = approvalSuccessOf[awardReceivers[i]].mul(amountToReceiverList).div(totalReward);
                TanimoToken(tokenAddress).transfer(awardReceivers[i], amountTmp);
            }
        }
        TanimoToken(tokenAddress).transfer(serverAddress, serverFailureFee);
        isFinished = true;
        selectGiveUpStatus = true;
        stateInstance = ChallengeState.GAVE_UP;
        emit GiveUp(msg.sender);
    }

    /**
     * @dev Close challenge.
     */
    function closeChallenge() external onlyStakeHolders afterFinish availableForClose
    {
        stateInstance = ChallengeState.CLOSED;
        transferToListReceiverFail();
    }

    /**
     * @dev Destroy challenge.
     */
    function destroyChallenge() external onlyServerOrSponsor {
        TanimoToken(tokenAddress).transfer(serverAddress, serverFailureFee);
        selfdestruct(sponsor);
    }

    /**
     * @dev Private function for transfer all award to receivers when challenge success.
     */
    function transferToListReceiverSuccess() private {
        TanimoToken(tokenAddress).transfer(serverAddress, serverSuccessFee);
        for (uint256 i = 0; i < index; i++) {
            TanimoToken(tokenAddress).transfer(awardReceivers[i], approvalSuccessOf[awardReceivers[i]]);
        }
        isSuccess = true;
        isFinished = true;
    }

    /**
     * @dev Private function for transfer all award to receivers when challenge fail.
     */
    function transferToListReceiverFail() private {
        TanimoToken(tokenAddress).transfer(serverAddress, serverFailureFee);
        for (uint256 i = index; i < awardReceivers.length; i++) {
            TanimoToken(tokenAddress).transfer(awardReceivers[i], approvalFailOf[awardReceivers[i]]);
        }
        isFinished = true;
        emit CloseChallenge(false);
    }

    function() payable external {}

    /**
     * @dev get balance of challenge.
     */
    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }

    /**
     * @dev get information of challenge.
     */
    function getChallengeInfo() external view returns(uint256 challengeCleared, uint256 challengeDayRequired, uint256 daysRemained) {
        return (
            currentStatus,
            dayRequired,
            dayRequired.sub(currentStatus)
        );
    }

    /**
     * @dev get history of challenge.
     */
    function getChallengeHistory() external view returns(uint256[] memory date, uint256[] memory data) {
        return (historyDate, historyData);
    }

    /**
     * @dev get state of challenge.
     */
    function getState() external view returns (ChallengeState) {
        return stateInstance;
    }

}