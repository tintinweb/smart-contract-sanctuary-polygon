// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./IERC721Receiver.sol";
import "./IExerciseSupplementNFT.sol";
import "./TransferHelper.sol";
import "./IERC1155.sol";
import "./IGacha.sol";
import "./IChallengeFee.sol";
import "./SignatureChecker.sol";

contract ChallengeDetail is IERC721Receiver {
    using SafeMath for uint256;

    /** @param ChallengeState currentState of challenge:
         1 : in processs
         2 : success
         3 : failed
         4 : gave up
         5 : closed
    */
    enum ChallengeState {
        PROCESSING,
        SUCCESS,
        FAILED,
        GAVE_UP,
        CLOSED
    }

    address private constant securityAddress =
        0x9A266044a5e5010C101169766F9cC7BE18bB111e;

    /** @dev returnedNFTWallet received NFT when Success
     */
    address private returnedNFTWallet;

    /** @dev erc20ListAddress list address of erc-20 contract.
     */
    address[] private erc20ListAddress;

    /** @dev erc721Address address of erc-721 contract.
     */
    address[] public erc721Address;

    /** @dev authorizedERC721Contracts address of erc-721 receive contract.
     */
    address[] private authorizedERC721Contracts;

    /** @dev sponsor sponsor of challenge.
     */
    address payable public sponsor;

    /** @dev challenger challenger of challenge.
     */
    address payable public challenger;

    /** @dev feeAddress feeAddress of challenge.
     */
    address payable private feeAddress;

    /** @dev awardReceivers list of receivers when challenge success and fail, start by success list.
     */
    address payable[] private awardReceivers;

    /** @dev awardReceiversApprovals list of award for receivers when challenge success and fail, start by success list.
     */
    uint256[] private awardReceiversApprovals;

    /** @dev historyData number of steps each day in challenge.
     */
    uint256[] historyData;

    /** @dev historyDate date in challenge.
     */
    uint256[] historyDate;

    /** @dev index index to split array receivers.
     */
    uint256 private index;

    uint256 public indexNft;

    /** @dev totalReward total reward receiver can receive in challenge.
     */
    uint256 public totalReward;

    /** @dev gasFee coin for challenger transaction fee. Transfer for challenger when create challenge.
     */
    uint256 private gasFee;

    /** @dev serverSuccessFee coin for sever when challenge success.
     */
    uint256 private serverSuccessFee;

    /** @dev serverFailureFee coin for sever when challenge fail.
     */
    uint256 private serverFailureFee;

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
    bool[] public allowGiveUp;

    /** @dev isFinished challenge finish or not.
     */
    bool public isFinished;

    /** @dev isSuccess challenge success or not.
     */
    bool public isSuccess;

    /** @dev choiceAwardToSponsor all award will go to sponsor wallet when challenger give up or not.
     */
    bool private choiceAwardToSponsor;

    /** @dev selectGiveUpStatus challenge need be give up one time.
     */
    bool selectGiveUpStatus;

    /** @dev approvalSuccessOf get amount of coin an `address` can receive when ckhallenge success.
     */
    mapping(address => uint256) private approvalSuccessOf;

    /** @dev approvalFailOf get amount of coin an `address` can receive when challenge fail.
     */
    mapping(address => uint256) private approvalFailOf;

    /** @dev stepOn get step on a day.
     */
    mapping(uint256 => uint256) private stepOn;

    /** @dev verifyMessage keep track and reject double secure message.
     */
    mapping(string => bool) private verifyMessage;

    // Instance of the ChallengeState contract
    ChallengeState private stateInstance;

    // Array of percentages for award receivers
    uint256[] private awardReceiversPercent;

    // Mapping of award receivers to the index of their awarded tokens
    mapping(address => uint256[]) private awardTokenReceivers;

    // Array of balances of all tokens
    uint256[] private listBalanceAllToken;

    // Array of amounts of tokens to be received by each token receiver
    uint256[] private amountTokenToReceiverList;

    // Total balance of the base token
    uint256 public totalBalanceBaseToken;

    // Address of the creator of the token
    address public createByToken;

    // Base fee for the admin
    uint256 public baseFeeForAdmin;

    /**
     * @dev Emitted when the daily result is sent.
     * @param currentStatus The current status of the daily result.
     */
    event SendDailyResult(uint256 indexed currentStatus);

    /**
     * @dev Event emitted when a transfer of tokens is executed.
     * @param to Address of the receiver of the tokens.
     * @param valueSend Amount of tokens transferred.
     */
    event FundTransfer(address indexed to, uint256 indexed valueSend);

    /**
     * @dev Emitted when a participant gives up on the challenge.
     * @param from The address of the participant who gave up.
     */
    event GiveUp(address indexed from);

    /**
     * @dev Emitted when a challenge is closed, indicating whether the challenge was successful or not.
     * @param challengeStatus A boolean flag indicating whether the challenge was successful or not.
     */
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
        require(
            block.timestamp <= endTime.add(2 days),
            "Challenge was finished"
        );
        require(block.timestamp >= startTime, "Challenge has not started yet");
        _;
    }

    /**
     * @dev Action should be called after challenge finish.
     */
    modifier afterFinish() {
        require(
            block.timestamp > endTime.add(2 days),
            "Challenge has not finished yet"
        );
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
        require(allowGiveUp[0], "Can not give up");
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
        require(
            msg.sender == challenger || msg.sender == sponsor,
            "Only stakeholders can call this function"
        );
        _;
    }

    /**
     * @dev Action only called from challenger.
     */
    modifier onlyChallenger() {
        require(
            msg.sender == challenger,
            "Only challenger can call this function"
        );
        _;
    }

    /**
     * @dev verify challenge success or not before close.
     */
    modifier availableForClose() {
        require(!isSuccess && !isFinished, "Cant call");
        _;
    }

    /**
     * @dev Constructor function for creating a new challenge.
     * @param _stakeHolders Array of addresses of the stakeholders participating in the challenge.
     * @param _createByToken The address of the token used to create this challenge.
     * @param _erc721Address Array of addresses of the ERC721 tokens used in the challenge.
     * @param _primaryRequired Array of values representing the primary requirements for each ERC721 token in the challenge.
     * @param _awardReceivers Array of addresses of the receivers who will receive awards if the challenge succeeds.
     * @param _index The index of the current award receiver.
     * @param _allowGiveUp Array of boolean values indicating whether each stakeholder can give up the challenge or not.
     * @param _gasData Array of gas data values for executing the smart contract functions in the challenge.
     * @param _allAwardToSponsorWhenGiveUp A boolean value indicating whether all awards should be given to the sponsor when the challenge is given up.
     * @param _awardReceiversPercent Array of percentage values representing the percentage of awards that each award receiver will receive.
     * @param _totalAmount The total amount of tokens locked in the challenge.
     */
    constructor(
        address payable[] memory _stakeHolders,
        address _createByToken,
        address[] memory _erc721Address,
        uint256[] memory _primaryRequired,
        address payable[] memory _awardReceivers,
        uint256 _index,
        bool[] memory _allowGiveUp,
        uint256[] memory _gasData,
        bool _allAwardToSponsorWhenGiveUp,
        uint256[] memory _awardReceiversPercent,
        uint256 _totalAmount
    ) payable {
        require(_allowGiveUp.length == 3, "Invalid allow give up"); // Checking if _allowGiveUp array length is 3.

        if (_allowGiveUp[1]) {
            require(msg.value == _totalAmount, "Invalid award"); // Checking if msg.value is equal to _totalAmount when _allowGiveUp[1] is true.
        }

        uint256 i;

        require(_index > 0, "Invalid value"); // Checking if _index is greater than 0.

        _totalAmount = _totalAmount.sub(_gasData[2]); // Subtracting _gasData[2] from _totalAmount.

        uint256[] memory awardReceiversApprovalsTamp = new uint256[](
            _awardReceiversPercent.length
        ); // Creating a new array with length equal to _awardReceiversPercent length.

        for (uint256 j = 0; j < _awardReceiversPercent.length; j++) {
            awardReceiversApprovalsTamp[j] = _awardReceiversPercent[j]
                .mul(_totalAmount)
                .div(100); // Calculating the award amount for each receiver.
        }

        require(
            _awardReceivers.length == awardReceiversApprovalsTamp.length,
            "Invalid lists"
        ); // Checking if _awardReceivers length is equal to awardReceiversApprovalsTamp length.

        for (i = 0; i < _index; i++) {
            require(awardReceiversApprovalsTamp[i] > 0, "Invalid value0"); // Checking if the award amount for each receiver is greater than 0.
            approvalSuccessOf[_awardReceivers[i]] = awardReceiversApprovalsTamp[
                i
            ]; // Setting the award amount for successful participants.
            sumAwardSuccess = sumAwardSuccess.add(
                awardReceiversApprovalsTamp[i]
            ); // Summing up the award amounts for successful participants.
        }

        for (i = _index; i < _awardReceivers.length; i++) {
            require(awardReceiversApprovalsTamp[i] > 0, "Invalid value1"); // Checking if the award amount for each receiver is greater than 0.
            approvalFailOf[_awardReceivers[i]] = awardReceiversApprovalsTamp[i]; // Setting the award amount for failed participants.
            sumAwardFail = sumAwardFail.add(awardReceiversApprovalsTamp[i]); // Summing up the award amounts for failed participants.
        }

        sponsor = _stakeHolders[0]; // Setting the sponsor address.
        challenger = _stakeHolders[1]; // Setting the challenger address.
        feeAddress = _stakeHolders[2]; // Setting the fee address.
        erc721Address = _erc721Address; // Setting the ERC721 contract address.
        erc20ListAddress = IExerciseSupplementNFT(_erc721Address[0])
            .getErc20ListAddress(); // Getting the ERC20 list address from the ERC721 contract.
        returnedNFTWallet = IExerciseSupplementNFT(_erc721Address[0])
            .returnedNFTWallet(); // Get the address of the returned NFT wallet from the ExerciseSupplementNFT contract
        authorizedERC721Contracts = IExerciseSupplementNFT(_erc721Address[0])
            .getNftListAddress(); // Get the list of authorized ERC721 contracts for this Challenge contract instance.
        duration = _primaryRequired[0]; // Setting the duration of the challenge.
        startTime = _primaryRequired[1]; // Setting the start time of the challenge.
        endTime = _primaryRequired[2]; // Setting the end time of the challenge.
        goal = _primaryRequired[3]; // Setting the goal of the challenge.
        dayRequired = _primaryRequired[4]; // Setting the required number of days for the challenge.
        stateInstance = ChallengeState.PROCESSING; // Setting the challenge state to PROCESSING.
        awardReceivers = _awardReceivers; // Setting the list of award receivers.
        awardReceiversApprovals = awardReceiversApprovalsTamp; // Setting the awardReceiversApprovals
        awardReceiversPercent = _awardReceiversPercent; // Assigning the award percentage to the contract variable
        index = _index; // Assigning the index value to the contract variable
        gasFee = _gasData[2]; // Assigning the gas fee to the contract variable
        createByToken = _createByToken; // Assigning the create by token value to the contract variable

        // get amoutn base fee
        baseFeeForAdmin = IChallengeFee(
            IExerciseSupplementNFT(_erc721Address[0]).feeSettingAddress()
        ).getBaseFee();

        totalReward = _totalAmount; // Assigning the total reward to the contract variable
        allowGiveUp = _allowGiveUp; // Assigning the allow give up value to the contract variable

        // Checking if give up is allowed and all awards should be given to the sponsor, then set the choiceAwardToSponsor variable to true
        if (_allowGiveUp[0] && _allAwardToSponsorWhenGiveUp)
            choiceAwardToSponsor = true;

        // Transferring the gas fee from the challenger to the contract and emitting an event
        tranferCoinNative(challenger, gasFee);
        emit FundTransfer(challenger, gasFee);
    }

    /**
     * @dev This function allows the contract to receive native currency of the network.
     * It checks if the sale is finished, and if it is, it transfers the native coins to the sender.
     * @notice This function is triggered automatically when native coins are sent to the contract address.
     */
    receive() external payable {
        if (isFinished) {
            // Check if the sale is finished
            tranferCoinNative(payable(msg.sender), msg.value); // Transfer the native coins to the sender
        }
    }

    /**
     * @dev Send daily result function to update step count data for multiple days at once.
     * @param _day An array of days to update step count data.
     * @param _stepIndex An array of step counts for each day to update.
     * @param _message The message for signature verification.
     * @param _signature The signature provided by the challenger.
     * @param _listGachaAddress An array of addresses for gacha instances to invoke random rewards.
     * @param _listNFTAddress An array of NFT contract addresses.
     * @param _listIndexNFT An array of arrays containing indices of NFTs to transfer.
     * @param _listSenderAddress An array of arrays containing sender addresses for each NFT.
     * @param _statusTypeNft An array indicating the status type of each NFT.
     */
    function sendDailyResult(
        uint256[] memory _day,
        uint256[] memory _stepIndex,
        string memory _message,
        bytes calldata _signature,
        address[] memory _listGachaAddress,
        address[] memory _listNFTAddress,
        uint256[][] memory _listIndexNFT,
        address[][] memory _listSenderAddress,
        bool[] memory _statusTypeNft
    ) public available onTimeSendResult onlyChallenger {
        // Mark the message as verified and processed
        checkValidSignature(_message, securityAddress, _signature);

        // Loop through each day and update the step count data
        for (uint256 i = 0; i < _day.length; i++) {
            // Check if the step count data for this day has already been updated
            require(
                stepOn[_day[i]] == 0,
                "This day's data had already updated"
            );
            // Update the step count data for this day
            stepOn[_day[i]] = _stepIndex[i];
            // Add the updated step count data to the history
            historyDate.push(_day[i]);
            historyData.push(_stepIndex[i]);
            // Check if the step count for this day meets the goal and the challenge has not been completed yet
            if (_stepIndex[i] >= goal && currentStatus < dayRequired) {
                // Increment the current status of the challenge
                currentStatus = currentStatus.add(1);
            }
        }

        // Increment the sequence of updates
        sequence = sequence.add(_day.length);

        // Check if the challenge has failed due to too many missed days
        if (sequence.sub(currentStatus) > duration.sub(dayRequired)) {
            stateInstance = ChallengeState.FAILED;
            // Transfer funds to the receiver addresses for the failed challenge
            transferToListReceiverFail(
                _listNFTAddress,
                _listIndexNFT,
                _listSenderAddress,
                _statusTypeNft
            );
        } else {
            // Check if the challenge has been completed successfully
            if (currentStatus >= dayRequired) {
                stateInstance = ChallengeState.SUCCESS;
                // Transfer funds to the receiver addresses for the successful challenge
                transferToListReceiverSuccess(
                    _listNFTAddress,
                    _listIndexNFT,
                    _statusTypeNft
                );
            }
        }

        // Loop through each gacha instance and invoke random rewards
        for (uint256 i = 0; i < _listGachaAddress.length; i++) {
            IGacha(_listGachaAddress[i]).randomRewards(
                address(this),
                _stepIndex
            );
        }

        // Emit an event for the current status of the challenge
        emit SendDailyResult(currentStatus);
    }

    /**
     * @dev Give up function to handle NFT transfers when a user decides to give up.
     * @param _listNFTAddress An array of NFT contract addresses.
     * @param _listIndexNFT An array of arrays containing indices of NFTs to transfer.
     * @param _listSenderAddress An array of arrays containing sender addresses for each NFT.
     * @param _statusTypeNft An array indicating the status type of each NFT.
     */
    function giveUp(
        address[] memory _listNFTAddress,
        uint256[][] memory _listIndexNFT,
        address[][] memory _listSenderAddress,
        bool[] memory _statusTypeNft
    ) external canGiveUp notSelectGiveUp onTime available onlyStakeHolders {
        updateRewardSuccessAndfail();

        uint256 remainningAmountFee = uint256(100).sub(baseFeeForAdmin);

        uint256 amount = address(this).balance.mul(remainningAmountFee).div(
            100
        );

        if (choiceAwardToSponsor) {
            tranferCoinNative(sponsor, amount);
            for (uint256 i = 0; i < erc20ListAddress.length; i++) {
                if (
                    getBalanceTokenOfContract(
                        erc20ListAddress[i],
                        address(this)
                    ) > 0
                ) {
                    TransferHelper.safeTransfer(
                        erc20ListAddress[i],
                        sponsor,
                        listBalanceAllToken[i].mul(remainningAmountFee).div(100)
                    );
                }
            }

            emit FundTransfer(sponsor, amount);
        } else {
            uint256 amountToReceiverList = amount.mul(currentStatus).div(
                dayRequired
            );

            tranferCoinNative(sponsor, amount.sub(amountToReceiverList));

            for (uint256 i = 0; i < erc20ListAddress.length; i++) {
                uint256 amountTokenToReceiver;
                uint256 totalTokenRewardSubtractFee = listBalanceAllToken[i]
                    .mul(remainningAmountFee)
                    .div(100);

                if (
                    getBalanceTokenOfContract(
                        erc20ListAddress[i],
                        address(this)
                    ) > 0
                ) {
                    amountTokenToReceiver = totalTokenRewardSubtractFee
                        .mul(currentStatus)
                        .div(dayRequired);
                    uint256 amountNativeToSponsor = totalTokenRewardSubtractFee
                        .sub(amountTokenToReceiver);
                    TransferHelper.safeTransfer(
                        erc20ListAddress[i],
                        sponsor,
                        amountNativeToSponsor
                    );
                    amountTokenToReceiverList.push(amountTokenToReceiver);
                }
            }

            for (uint256 i = 0; i < index; i++) {
                tranferCoinNative(
                    awardReceivers[i],
                    approvalSuccessOf[awardReceivers[i]]
                        .mul(amountToReceiverList)
                        .div(amount)
                );

                for (uint256 j = 0; j < erc20ListAddress.length; j++) {
                    if (
                        getBalanceTokenOfContract(
                            erc20ListAddress[j],
                            address(this)
                        ) > 0
                    ) {
                        uint256 amountTokenTmp = awardTokenReceivers[
                            erc20ListAddress[j]
                        ][i].mul(amountTokenToReceiverList[j]).div(
                                listBalanceAllToken[j]
                                    .mul(remainningAmountFee)
                                    .div(100)
                            );

                        TransferHelper.safeTransfer(
                            erc20ListAddress[j],
                            awardReceivers[i],
                            amountTokenTmp
                        );
                    }
                }
            }
        }

        transferNFTForSenderWhenFailed(
            _listNFTAddress,
            _listIndexNFT,
            _listSenderAddress,
            _statusTypeNft
        );

        tranferCoinNative(feeAddress, serverFailureFee);
        // emit FundTransfer(feeAddress, serverFailureFee);

        isFinished = true;
        selectGiveUpStatus = true;
        stateInstance = ChallengeState.GAVE_UP;
        emit GiveUp(msg.sender);
    }

    /**
     * @dev Close challenge function to handle the closing of a challenge and associated NFT transfers.
     * @param _listNFTAddress An array of NFT contract addresses.
     * @param _listIndexNFT An array of arrays containing indices of NFTs to transfer.
     * @param _listSenderAddress An array of arrays containing sender addresses for each NFT.
     * @param _statusTypeNft An array indicating the status type of each NFT.
     */
    function closeChallenge(
        address[] memory _listNFTAddress,
        uint256[][] memory _listIndexNFT,
        address[][] memory _listSenderAddress,
        bool[] memory _statusTypeNft
    ) external onlyStakeHolders afterFinish availableForClose {
        stateInstance = ChallengeState.CLOSED;
        transferToListReceiverFail(
            _listNFTAddress,
            _listIndexNFT,
            _listSenderAddress,
            _statusTypeNft
        );
        emit CloseChallenge(false);
    }

    /**
     * @dev Withdraw tokens on completion function to handle the withdrawal of tokens and NFTs on completion of a task.
     * @param _listTokenErc20 An array of ERC20 token contract addresses.
     * @param _listNFTAddress An array of NFT contract addresses.
     * @param _listIndexNFT An array of arrays containing indices of NFTs to transfer.
     * @param _statusTypeNft An array indicating the status type of each NFT.
     */
    function withdrawTokensOnCompletion(
        address[] memory _listTokenErc20,
        address[] memory _listNFTAddress,
        uint256[][] memory _listIndexNFT,
        bool[] memory _statusTypeNft
    ) external {
        require(isFinished, "The challenge has not yet been finished");
        require(
            returnedNFTWallet == msg.sender,
            "Only returned nft wallet address"
        );

        // Transfer ERC20 tokens
        for (uint256 i = 0; i < _listTokenErc20.length; i++) {
            address tokenErc20 = _listTokenErc20[i];
            uint256 balanceErc20 = IERC20(tokenErc20).balanceOf(address(this));

            TransferHelper.safeTransfer(
                tokenErc20,
                returnedNFTWallet,
                balanceErc20
            );
        }

        transferNFTForSenderWhenFinish(
            _listNFTAddress,
            _listIndexNFT,
            _statusTypeNft,
            returnedNFTWallet
        );
    }

    /**
     * @dev Transfer NFTs to a list of receivers successfully.
     * @param _listNFTAddress An array of NFT contract addresses.
     * @param _listIndexNFT An array of arrays containing indices of NFTs to transfer.
     * @param _statusTypeNft An array indicating the status type of each NFT.
     */
    function transferToListReceiverSuccess(
        address[] memory _listNFTAddress,
        uint256[][] memory _listIndexNFT,
        bool[] memory _statusTypeNft
    ) private {
        updateRewardSuccessAndfail();

        tranferCoinNative(feeAddress, serverSuccessFee);

        emit FundTransfer(feeAddress, serverSuccessFee);

        for (uint256 i = 0; i < index; i++) {
            tranferCoinNative(
                awardReceivers[i],
                approvalSuccessOf[awardReceivers[i]]
            );

            for (uint256 j = 0; j < erc20ListAddress.length; j++) {
                if (
                    getBalanceTokenOfContract(
                        erc20ListAddress[j],
                        address(this)
                    ) > 0
                ) {
                    TransferHelper.safeTransfer(
                        erc20ListAddress[j],
                        awardReceivers[i],
                        awardTokenReceivers[erc20ListAddress[j]][i]
                    );
                }
            }
        }

        if (allowGiveUp[2]) {
            address currentAddressNftUse;
            (currentAddressNftUse, indexNft) = IExerciseSupplementNFT(
                erc721Address[0]
            ).safeMintNFT(
                    goal,
                    duration,
                    dayRequired,
                    createByToken,
                    totalReward,
                    awardReceiversPercent[0],
                    address(awardReceivers[0]),
                    address(challenger)
                );
            erc721Address.push(currentAddressNftUse);
        }

        transferNFTForSenderWhenFinish(
            _listNFTAddress,
            _listIndexNFT,
            _statusTypeNft,
            challenger
        );

        isSuccess = true;
        isFinished = true;
    }

    /**
     * @dev Transfer NFTs to a list of receivers when the transfer fails.
     * @param _listNFTAddress An array of NFT contract addresses.
     * @param _listIndexNFT An array of arrays containing indices of NFTs to transfer.
     * @param _listSenderAddress An array of arrays containing sender addresses for each NFT.
     * @param _statusTypeNft An array indicating the status type of each NFT.
     */
    function transferToListReceiverFail(
        address[] memory _listNFTAddress,
        uint256[][] memory _listIndexNFT,
        address[][] memory _listSenderAddress,
        bool[] memory _statusTypeNft
    ) private {
        updateRewardSuccessAndfail();

        // Transfer server failure fee to fee address
        tranferCoinNative(feeAddress, serverFailureFee);

        emit FundTransfer(feeAddress, serverFailureFee);

        // Transfer rewards and tokens to all receivers
        for (uint256 i = index; i < awardReceivers.length; i++) {
            // Transfer ETH rewards to receiver
            tranferCoinNative(
                awardReceivers[i],
                approvalFailOf[awardReceivers[i]]
            );

            // Transfer ERC20 token rewards to receiver
            for (uint256 j = 0; j < erc20ListAddress.length; j++) {
                if (
                    getBalanceTokenOfContract(
                        erc20ListAddress[j],
                        address(this)
                    ) > 0
                ) {
                    TransferHelper.safeTransfer(
                        erc20ListAddress[j],
                        awardReceivers[i],
                        awardTokenReceivers[erc20ListAddress[j]][i]
                    );
                }
            }
        }

        // Transfer NFTs to their original owners
        transferNFTForSenderWhenFailed(
            _listNFTAddress,
            _listIndexNFT,
            _listSenderAddress,
            _statusTypeNft
        );

        // Emit event and mark challenge as finished
        emit CloseChallenge(false);
        isFinished = true;
    }

    /**
     * @dev Check the validity of a signature for a given message and address.
     * @param _message The message for signature verification.
     * @param _address The address to verify against the signature.
     * @param _signature The signature to verify.
     */
    function checkValidSignature(
        string memory _message,
        address _address,
        bytes calldata _signature
    ) private {
        require(!verifyMessage[_message], "Message was used");
        bytes32 message = keccak256(abi.encodePacked(_message));
        require(
            SignatureChecker.isValidSignatureNow(
                _address,
                ECDSA.toEthSignedMessageHash(message),
                _signature
            ),
            "Signature data is invalid"
        );
        verifyMessage[_message] = true;
    }

    /**
     * @dev Transfer NFTs back to the sender when the task is finished.
     * @param _listNFTAddress An array of NFT contract addresses.
     * @param _listIndexNFT An array of arrays containing indices of NFTs to transfer.
     * @param _statusTypeNft An array indicating the status type of each NFT.
     * @param _receiveAddress The address to receive the transferred NFTs.
     */
    function transferNFTForSenderWhenFinish(
        address[] memory _listNFTAddress,
        uint256[][] memory _listIndexNFT,
        bool[] memory _statusTypeNft,
        address _receiveAddress
    ) private {
        // Iterate through the list of ERC721 contracts
        for (uint256 i = 0; i < _listNFTAddress.length; i++) {
            if (_statusTypeNft[i]) {
                for (uint256 j = 0; j < _listIndexNFT[i].length; j++) {
                    // Transfer the NFT to the sender
                    TransferHelper.safeTransferFrom(
                        _listNFTAddress[i],
                        address(this),
                        _receiveAddress,
                        _listIndexNFT[i][j]
                    );
                }
            } else {
                for (uint256 j = 0; j < _listIndexNFT[i].length; j++) {
                    uint256 balanceTokenERC1155 = IERC1155(_listNFTAddress[i])
                        .balanceOf(address(this), _listIndexNFT[i][j]);
                    // Encode data transfer token
                    bytes memory extraData = abi.encode(
                        address(this),
                        _receiveAddress,
                        _listIndexNFT[i][j],
                        balanceTokenERC1155
                    );

                    // Transfer the NFT to the sender
                    TransferHelper.safeTransferNFT1155(
                        _listNFTAddress[i],
                        address(this),
                        _receiveAddress,
                        _listIndexNFT[i][j],
                        balanceTokenERC1155,
                        extraData
                    );
                }
            }
        }
    }

    /**
     * @dev Transfer NFTs back to the sender when the task fails.
     * @param _listNFTAddress An array of NFT contract addresses.
     * @param _listIndexNFT An array of arrays containing indices of NFTs to transfer.
     * @param _listSenderAddress An array of arrays containing sender addresses for each NFT.
     * @param _statusTypeNft An array indicating the status type of each NFT.
     */
    function transferNFTForSenderWhenFailed(
        address[] memory _listNFTAddress,
        uint256[][] memory _listIndexNFT,
        address[][] memory _listSenderAddress,
        bool[] memory _statusTypeNft
    ) private {
        // Iterate through the list of ERC721 contracts
        for (uint256 i = 0; i < _listNFTAddress.length; i++) {
            if (_statusTypeNft[i]) {
                for (uint256 j = 0; j < _listIndexNFT[i].length; j++) {
                    // Transfer the NFT to the sender
                    TransferHelper.safeTransferFrom(
                        _listNFTAddress[i],
                        address(this),
                        _listSenderAddress[i][j],
                        _listIndexNFT[i][j]
                    );
                }
            } else {
                for (uint256 j = 0; j < _listIndexNFT[i].length; j++) {
                    uint256 balanceTokenERC1155 = IERC1155(_listNFTAddress[i])
                        .balanceOf(address(this), _listIndexNFT[i][j]);
                    // Encode data transfer token
                    bytes memory extraData = abi.encode(
                        address(this),
                        _listSenderAddress[i][j],
                        _listIndexNFT[i][j],
                        balanceTokenERC1155
                    );

                    // Transfer the NFT to the sender
                    TransferHelper.safeTransferNFT1155(
                        _listNFTAddress[i],
                        address(this),
                        _listSenderAddress[i][j],
                        _listIndexNFT[i][j],
                        balanceTokenERC1155,
                        extraData
                    );
                }
            }
        }
    }

    // Update reward for successful and failed challenges
    function updateRewardSuccessAndfail() private {
        // Update balance Matic and token
        uint256 coinNativeBalance = address(this).balance;

        if (coinNativeBalance > 0) {
            serverSuccessFee = coinNativeBalance.mul(baseFeeForAdmin).div(100);
            serverFailureFee = coinNativeBalance.mul(baseFeeForAdmin).div(100);

            for (uint256 i = 0; i < awardReceivers.length; i++) {
                approvalSuccessOf[awardReceivers[i]] = awardReceiversPercent[i]
                    .mul(coinNativeBalance)
                    .div(100);
                sumAwardSuccess = awardReceiversPercent[i]
                    .mul(coinNativeBalance)
                    .div(100);
            }

            for (uint256 i = index; i < awardReceivers.length; i++) {
                approvalFailOf[awardReceivers[i]] = awardReceiversPercent[i]
                    .mul(coinNativeBalance)
                    .div(100);
                sumAwardFail = awardReceiversPercent[i]
                    .mul(coinNativeBalance)
                    .div(100);
            }
        }
        // Get total balance of base token in contract
        totalBalanceBaseToken = getContractBalance();

        // Loop through all ERC20 tokens in list
        for (uint256 i = 0; i < erc20ListAddress.length; i++) {
            // Get balance of current ERC20 token
            listBalanceAllToken.push(
                IERC20(erc20ListAddress[i]).balanceOf(address(this))
            );

            // Check if contract holds any balance of current ERC20 token
            if (
                getBalanceTokenOfContract(erc20ListAddress[i], address(this)) >
                0
            ) {
                // Loop through all award receivers percentage
                for (uint256 j = 0; j < awardReceiversPercent.length; j++) {
                    // Calculate the amount of ERC20 token to award to current receiver
                    uint256 awardAmount = awardReceiversPercent[j]
                        .mul(
                            IERC20(erc20ListAddress[i]).balanceOf(address(this))
                        )
                        .div(100);
                    // Add the award amount to receiver's balance for current ERC20 token
                    awardTokenReceivers[erc20ListAddress[i]].push(awardAmount);
                }

                // Transfer 2% of current ERC20 token to fee address as fee
                TransferHelper.safeTransfer(
                    erc20ListAddress[i],
                    feeAddress,
                    listBalanceAllToken[i].mul(baseFeeForAdmin).div(100)
                );
            }
        }
    }

    // Returns the owner of the specified ERC721 token.
    function getOwnerOfNft(
        address _erc721Address,
        uint256 _index
    ) private view returns (address) {
        return IExerciseSupplementNFT(_erc721Address).ownerOf(_index);
    }

    // Returns the balance of the contract in the native currency (ether).
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Returns the history of the challenge as an array of dates and corresponding data values.
    function getChallengeHistory()
        external
        view
        returns (uint256[] memory date, uint256[] memory data)
    {
        return (historyDate, historyData);
    }

    // Returns the current state of the challenge as an enumerated value.
    function getState() external view returns (ChallengeState) {
        return stateInstance;
    }

    // Check if the contract has enough balance to transfer
    function tranferCoinNative(address payable from, uint256 value) private {
        if (getContractBalance() >= value) {
            // If the contract has enough balance, transfer the ETH to the 'from' address
            TransferHelper.saveTransferEth(from, value);
        }
    }

    // Private function to get balance of a specific ERC20 token in the contract
    function getBalanceTokenOfContract(
        address _erc20Address,
        address _fromAddress
    ) private view returns (uint256) {
        return IERC20(_erc20Address).balanceOf(_fromAddress);
    }

    // Private function to compare two strings
    function compareStrings(
        string memory a,
        string memory b
    ) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    // Public function to return all ERC20 token contract addresses
    function allContractERC20() external view returns (address[] memory) {
        return erc20ListAddress;
    }

    // Return information about the current challenge
    function getChallengeInfo()
        external
        view
        returns (
            uint256 challengeCleared,
            uint256 challengeDayRequired,
            uint256 daysRemained
        )
    {
        return (
            currentStatus, // The current status of the challenge
            dayRequired, // The number of days required to complete the challenge
            dayRequired.sub(currentStatus) // The number of days remaining in the challenge
        );
    }

    // Return the array of award receiver percentages
    function getAwardReceiversPercent() public view returns (uint256[] memory) {
        return (awardReceiversPercent);
    }

    // Return the array of token balances for each token in the contract
    function getBalanceToken() public view returns (uint256[] memory) {
        return listBalanceAllToken;
    }

    /**
     * This function returns the address of an award receiver at the specified index.
     * If _isAddressSuccess is false, it returns the address of the award receiver who did not approve the transaction.
     * If _isAddressSuccess is true, it returns the address of the award receiver who approved the transaction.
     */
    function getAwardReceiversAtIndex(
        uint256 _index,
        bool _isAddressSuccess
    ) public view returns (address) {
        // If _isAddressSuccess is false, return the address of the award receiver who did not approve the transaction.
        if (!_isAddressSuccess) {
            return awardReceivers[_index.add(index)];
        }
        // If _isAddressSuccess is true, return the address of the award receiver who approved the transaction.
        return awardReceivers[_index];
    }

    /**
     * @dev onERC721Received.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev onERC1155Received.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}