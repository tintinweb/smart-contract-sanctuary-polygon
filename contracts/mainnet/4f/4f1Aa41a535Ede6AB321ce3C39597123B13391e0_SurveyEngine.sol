// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts//security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../abstractions/Forwardable.sol";
import "../libraries/TransferHelper.sol";
import "../interfaces/IWETH.sol";
import "./interfaces/ISurveyConfig.sol";
import "./interfaces/ISurveyStorage.sol";
import "./interfaces/ISurveyFactory.sol";
import "./interfaces/ISurveyValidator.sol";
import "./interfaces/ISurveyEngine.sol";
import "./interfaces/ISurveyImpl.sol";

contract SurveyEngine is ISurveyEngine, Forwardable, ReentrancyGuard {

    IWETH internal currencyCnt;// Wrapped native currency
    ISurveyConfig internal configCnt;
    ISurveyStorage internal storageCnt;

    constructor(address _currency, address _config, address _storage, address forwarder) Forwardable(forwarder) {
        require(_currency != address(0), "SurveyEngine: invalid wrapped currency address");
        require(_config != address(0), "SurveyEngine: invalid config address");
        require(_storage != address(0), "SurveyEngine: invalid storage address");

        currencyCnt = IWETH(_currency);
        configCnt = ISurveyConfig(_config);
        storageCnt = ISurveyStorage(_storage);
    }

    receive() external payable {
        require(_msgSender() == address(currencyCnt), 'Not WETH9');
    }

    function currency() external view virtual override returns (address) {
        return address(currencyCnt);
    }

    function surveyConfig() external view virtual override returns (address) {
        return address(configCnt);
    }

    function surveyStorage() external view virtual override returns (address) {
        return address(storageCnt);
    }

    function addSurvey(SurveyRequest memory survey, Question[] memory questions, Validator[] memory validators, string[] memory hashes) 
    external payable override nonReentrant {
        require(survey.token != address(0), "SurveyEngine: invalid token address");

        uint256 balance = IERC20(survey.token).balanceOf(_msgSender());
        require(balance >= survey.budget, "SurveyEngine: balance is less than the budget");

        uint256 allowance = IERC20(survey.token).allowance(_msgSender(), address(this));
        require(allowance >= survey.budget, "SurveyEngine: allowance is less than the budget");

        ISurveyValidator(configCnt.surveyValidator()).checkSurvey(survey, questions, validators, hashes);

        uint256 partsNum = survey.budget / survey.reward;
        uint256 totalFee = partsNum * configCnt.fee();
        require(msg.value >= totalFee, "SurveyEngine: wei amount is less than the fee");

        uint256 gasReserve = msg.value - totalFee;
        SurveyWrapper memory wrapper;
        wrapper.account = _msgSender();
        wrapper.survey = survey;
        wrapper.questions = questions;
        wrapper.validators = validators;
        wrapper.hashes = hashes;
        wrapper.gasReserve = gasReserve;
        
        address surveyAddr = ISurveyFactory(configCnt.surveyFactory()).createSurvey(wrapper, address(configCnt), address(storageCnt));
        storageCnt.saveSurvey(_msgSender(), surveyAddr, gasReserve);

        // Transfer tokens to this contract
        TransferHelper.safeTransferFrom(survey.token, _msgSender(), address(this), survey.budget);

        // Transfer fee to `feeTo`
        payable(configCnt.feeTo()).transfer(totalFee);

        // Transfer reserve to `forwarder custody address` to pay for participations
        // Transfer is done at WETH to facilitate returns
        currencyCnt.deposit{value: gasReserve}(); 
        currencyCnt.transfer(forwarderCnt.custody(), gasReserve);

        emit OnSurveyAdded(_msgSender(), surveyAddr);
    }

    function solveSurvey(address surveyAddr) external override nonReentrant {
        require(storageCnt.exists(surveyAddr), "SurveyEngine: survey not found");

        ISurveyImpl surveyImpl = ISurveyImpl(surveyAddr);
        Survey memory survey = surveyImpl.data();
        require(_msgSender() == survey.surveyOwner, "SurveyEngine: you are not the survey owner");

        uint256 remainingBudget = surveyImpl.remainingBudget();
        uint256 remainingGasReserve = surveyImpl.remainingGasReserve();
        require(remainingBudget > 0 || remainingGasReserve > 0, "SurveyEngine: survey already solved");

        storageCnt.solveSurvey(surveyAddr);

        if(remainingBudget > 0) {
            // Transfer the remaining budget to the survey owner
            TransferHelper.safeTransfer(survey.token, _msgSender(), remainingBudget);
        }

        if(remainingGasReserve > 0) {
            // Transfer the remaining gas reserve to the survey owner
            currencyCnt.transferFrom(forwarderCnt.custody(), address(this), remainingGasReserve);
            currencyCnt.withdraw(remainingGasReserve);
            TransferHelper.safeTransferETH(_msgSender(), remainingGasReserve);
        }

        emit OnSurveySolved(_msgSender(), surveyAddr, remainingBudget, remainingGasReserve);
    }

    function increaseGasReserve(address surveyAddr) external payable override nonReentrant {
        require(storageCnt.exists(surveyAddr), "SurveyEngine: survey not found");
        require(msg.value > 0, "SurveyEngine: Wei amount is zero");

        ISurveyImpl surveyImpl = ISurveyImpl(surveyAddr);
        Survey memory survey = surveyImpl.data();
        require(_msgSender() == survey.surveyOwner, "SurveyEngine: you are not the survey owner");

        uint256 remainingBudget = surveyImpl.remainingBudget();
        uint256 remainingGasReserve = surveyImpl.remainingGasReserve();
        require(remainingBudget > 0, "SurveyEngine: survey without budget");
        require(block.timestamp < survey.endTime, "SurveyEngine: survey closed");

        storageCnt.increaseGasReserve(surveyAddr, msg.value);

        // Transfer reserve to `forwarder custody address` as WETH
        currencyCnt.deposit{value: msg.value}(); 
        currencyCnt.transfer(forwarderCnt.custody(), msg.value);

        emit OnGasReserveIncreased(_msgSender(), surveyAddr, msg.value, remainingGasReserve + msg.value);
    }

    function addParticipation(address surveyAddr, string[] memory responses, string memory key) external override nonReentrant {
        _addParticipation(_msgSender(), surveyAddr, responses, key, 0);
    }

    function addParticipationFromForwarder(address surveyAddr, string[] memory responses, string memory key, uint256 txGas) 
    external override onlyTrustedForwarder nonReentrant {
        _addParticipation(_fwdSender(), surveyAddr, responses, key, txGas);
    }

    // ### Internal functions ###

    function _addParticipation(address account, address surveyAddr, string[] memory responses, string memory key, uint256 txGas) internal {
        require(account != address(0), "SurveyEngine: invalid account");
        require(storageCnt.exists(surveyAddr), "SurveyEngine: survey not found");

        ISurveyImpl surveyImpl = ISurveyImpl(surveyAddr);
        Survey memory survey = surveyImpl.data();
        require(block.timestamp >= survey.startTime, "SurveyEngine: survey not yet open");
        require(block.timestamp < survey.endTime, "SurveyEngine: survey closed");

        uint256 remainingBudget = surveyImpl.remainingBudget();
        require(remainingBudget >= survey.reward, "SurveyEngine: survey without sufficient budget");

        uint256 remainingGasReserve = surveyImpl.remainingGasReserve();
        uint256 txPrice = tx.gasprice * txGas;
        require(remainingGasReserve >= txPrice, "SurveyEngine: survey without sufficient gas reserve");

        bool alreadyParticipated = surveyImpl.isParticipant(account);
        require(!alreadyParticipated, "SurveyEngine: has already participated");

        Participation memory participation;
        participation.surveyAddr = surveyAddr;
        participation.responses = responses;
        participation.txGas = txGas;
        participation.gasPrice = tx.gasprice;
        participation.partTime = block.timestamp;
        participation.partOwner = account;

        storageCnt.addParticipation(participation, key);

        // Transfer tokens from this contract to participant
        TransferHelper.safeTransfer(survey.token, account, survey.reward);
        
        emit OnParticipationAdded(account, surveyAddr, txGas);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./ISurveyModel.sol";

/**
 * @dev Interface to implement a survey validation contract
 */
interface ISurveyValidator is ISurveyModel {

    // ### Validation functions ###

    function checkSurvey(SurveyRequest memory survey, Question[] memory questions, Validator[] memory validators, string[] memory hashes) external;
    function checkResponse(Question memory question, Validator[] memory validators, string memory response) external;
    function isLimited(ResponseType responseType) external returns (bool);
    function isArray(ResponseType responseType) external returns (bool);

    // ### Owner functions `onlyOwner` ###

    function setTknSymbolMaxLength(uint256 tknSymbolMaxLength) external;
    function setTknNameMaxLength(uint256 tknNameMaxLength) external;
    function setTitleMaxLength(uint256 titleMaxLength) external;
    function setDescriptionMaxLength(uint256 descriptionMaxLength) external;
    function setUrlMaxLength(uint256 urlMaxLength) external;
    function setStartMaxTime(uint256 startMaxTime) external;
    function setRangeMinTime(uint256 rangeMinTime) external;
    function setRangeMaxTime(uint256 rangeMaxTime) external;
    function setQuestionMaxPerSurvey(uint256 questionMaxPerSurvey) external;
    function setQuestionMaxLength(uint256 questionMaxLength) external;
    function setValidatorMaxPerQuestion(uint256 validatorMaxPerQuestion) external;
    function setValidatorValueMaxLength(uint256 validatorValueMaxLength) external;
    function setHashMaxPerSurvey(uint256 hashMaxPerSurvey) external;
    function setResponseMaxLength(uint256 responseMaxLength) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./ISurveyModel.sol";

/**
 * @dev Interface to implement the survey storage
 */
interface ISurveyStorage is ISurveyModel {

    struct PartID {
        address surveyAddr;
        address partOwner;
    }

    function surveyConfig() external view returns (address);
    function totalGasReserve() external view returns (uint256);
    function txGasSamples(uint256 maxLength) external view returns (uint256[] memory);
    function remainingBudgetOf(address surveyAddr) external view returns (uint256);
    function remainingGasReserveOf(address surveyAddr) external view returns (uint256);
    function amountsOf(address surveyAddr) external view returns (uint256, uint256, uint256);

    // ### Surveys ###

    function exists(address surveyAddr) external view returns (bool);
    function getSurveysLength() external view returns (uint256);
    function getAddresses(uint256 cursor, uint256 length) external view returns (address[] memory);
    function getSurveys(uint256 cursor, uint256 length) external view returns (Survey[] memory);
    function findSurvey(address surveyAddr) external view returns (Survey memory);
    function isOpenedSurvey(address surveyAddr, uint256 offset) external view returns (bool);

    // ### Own Surveys ###

    function getOwnSurveysLength() external view returns (uint256);
    function getOwnSurveys(uint256 cursor, uint256 length) external view returns (Survey[] memory);

    // ### Questions ###

    function getQuestionsLength(address surveyAddr) external view returns (uint256) ;
    function getQuestions(address surveyAddr, uint256 cursor, uint256 length) external view returns (Question[] memory);

    // ### Validators ###

    function getValidatorsLength(address surveyAddr, uint256 questionIndex) external view returns (uint256);
    function getValidators(address surveyAddr, uint256 questionIndex) external view returns (Validator[] memory);

    // ### Participants ###

    function getParticipantsLength(address surveyAddr) external view returns (uint256);
    function getParticipants(address surveyAddr, uint256 cursor, uint256 length) external view returns (address[] memory);
    function isParticipant(address surveyAddr, address account) external view returns (bool);

    // ### Participations ###

    function getParticipationsTotal() external view returns (uint256);
    function getGlobalParticipations(uint256 cursor, uint256 length) external view returns (Participation[] memory);
    function getParticipations(address surveyAddr, uint256 cursor, uint256 length) external view returns (Participation[] memory);
    function findParticipation(address surveyAddr, address account) external view returns (Participation memory);

    // ### Own Participations ###

    function getOwnParticipationsLength() external view returns (uint256);
    function getOwnParticipations(uint256 cursor, uint256 length) external view returns (Participation[] memory);
    function findOwnParticipation(address surveyAddr) external view returns (Participation memory);

    // ### Responses ###

    function getResponses(address surveyAddr, uint256 questionIndex, uint256 cursor, uint256 length) external view returns (string[] memory);
    function getResponseCounts(address surveyAddr, uint256 questionIndex) external view returns (ResponseCount[] memory);

    // ### Manager functions ###

    function saveSurvey(address senderAddr, address surveyAddr, uint256 gasReserve) external returns (address);
    function addParticipation(Participation calldata participation, string calldata key) external;
    function solveSurvey(address surveyAddr) external;
    function increaseGasReserve(address surveyAddr, uint256 amount) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * @dev Interface containing the survey structure
 */
interface ISurveyModel {

    // ArrayText elements should not contain the separator (;)
    enum ResponseType {
        Bool, Text, Number, Percent, Date, Rating, OneOption, 
        ManyOptions, Range, DateRange,
        ArrayBool, ArrayText, ArrayNumber, ArrayDate
    }

    struct Question {
        string content;// json that represents the content of the question
        bool mandatory;
        ResponseType responseType;
    }

    struct SurveyRequest {
        string title;
        string description;
        string logoUrl;
        uint256 startTime;
        uint256 endTime;
        uint256 budget;// Total budget of INC tokens
        uint256 reward;// Reward amount for participation
        address token;// Incentive token
    }

    struct SurveyWrapper {
        address account;
        SurveyRequest survey;
        Question[] questions;
        Validator[] validators;
        string[] hashes;
        uint256 gasReserve;
    }

    struct Survey {
        string title;
        string description;
        string logoUrl;
        uint256 startTime;
        uint256 endTime;
        uint256 budget;
        uint256 reward;
        address token;
        bool keyRequired;
        uint256 surveyTime;
        address surveyOwner;
        address surveyAddr;
    }

    struct Participation {
        address surveyAddr;
        string[] responses;
        uint256 txGas;
        uint256 gasPrice;
        uint256 partTime;
        address partOwner;
    }

    enum Operator {
        None, And, Or
    }

    enum Expression {
        None,
        Empty,
        NotEmpty,
        Equals,
        NotEquals,
        Contains,
        NotContains,
        EqualsIgnoreCase,
        NotEqualsIgnoreCase,
        ContainsIgnoreCase,
        NotContainsIgnoreCase,
        Greater,
        GreaterEquals,
        Less,
        LessEquals,
        ContainsDigits,
        NotContainsDigits,
        MinLength,
        MaxLength
    }

    struct Validator {
        uint256 questionIndex;
        Operator operator;
        Expression expression;
        string value;
    }

    struct ResponseCount {
        string value;
        uint256 count;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./ISurveyBase.sol";

/**
 * @dev Interface to implement a survey contract
 */
interface ISurveyImpl is ISurveyBase {

    // ### Owner functions `factory` ###

    function initialize(Survey calldata survey, Question[] calldata questions, Validator[] calldata validators, string[] calldata hashes, uint256 gasReserve) external;

    // ### Manager functions `storage` ###

    function addParticipation(Participation calldata participation, string calldata key) external returns (uint256);
    function solveSurvey() external returns (uint256);
    function increaseGasReserve(uint256 amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./ISurveyModel.sol";

/**
 * @dev Interface to implement the survey factory
 */
interface ISurveyFactory is ISurveyModel {

    // ### Manager functions `engine` ###

    function createSurvey(SurveyWrapper calldata wrapper, address configAddr, address storageAddr) external returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./ISurveyModel.sol";

/**
 * @dev Interface to implement the survey engine
 */
 interface ISurveyEngine is ISurveyModel {

   event OnSurveyAdded(
        address indexed owner,
        address indexed surveyAddr
    );

    event OnSurveySolved(
        address indexed owner,
        address indexed surveyAddr,
        uint256 budgetRefund,
        uint256 gasRefund
    );

    event OnGasReserveIncreased(
        address indexed owner,
        address indexed surveyAddr,
        uint256 gasAdded,
        uint256 gasReserve
    );

    event OnParticipationAdded(
        address indexed participant,
        address indexed surveyAddr,
        uint256 txGas
    );

    function currency() external view returns (address);
    function surveyConfig() external view returns (address);
    function surveyStorage() external view returns (address);

    function addSurvey(SurveyRequest memory survey, Question[] memory questions, Validator[] memory validators, string[] memory hashes) external payable;
    function solveSurvey(address surveyAddr) external;
    function increaseGasReserve(address surveyAddr) external payable;
    function addParticipation(address surveyAddr, string[] memory responses, string memory key) external;
    function addParticipationFromForwarder(address surveyAddr, string[] memory responses, string memory key, uint256 txGas) external;
 }

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @dev Interface to implement the survey config
 */
 interface ISurveyConfig {

   event SurveyFactoryChanged(address indexed previousFactory, address indexed newFactory);
   event SurveyValidatorChanged(address indexed previousValidator, address indexed newValidator);

   function surveyFactory() external view returns (address);
   function surveyValidator() external view returns (address);

   // Storage settings
   function surveyMaxPerRequest() external view returns (uint256);
   function questionMaxPerRequest() external view returns (uint256);
   function responseMaxPerRequest() external view returns (uint256);
   function participantMaxPerRequest() external view returns (uint256);
   function participationMaxPerRequest() external view returns (uint256);
   function txGasMaxPerRequest() external view returns (uint256);

   // Engine settings
   function fee() external view returns (uint256);
   function feeTo() external view returns (address);

    // ### Owner functions ###

    function setSurveyFactory(address factory) external;
    function setSurveyValidator(address validator) external;
    function setSurveyMaxPerRequest(uint256 surveyMaxPerRequest) external;
    function setQuestionMaxPerRequest(uint256 questionMaxPerRequest) external;
    function setResponseMaxPerRequest(uint256 responseMaxPerRequest) external;
    function setParticipantMaxPerRequest(uint256 participantMaxPerRequest) external;
    function setParticipationMaxPerRequest(uint256 participationMaxPerRequest) external;
    function setTxGasMaxPerRequest(uint256 txGasMaxPerRequest) external;
    function setFee(uint256 fee) external;
    function setFeeTo(address feeTo) external;
 }

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./ISurveyModel.sol";

/**
 * @dev Interface to implement a survey contract
 */
interface ISurveyBase is ISurveyModel {

    function config() external view returns (address);
    function data() external view returns (Survey memory);
    function remainingBudget() external view returns (uint256);
    function remainingGasReserve() external view returns (uint256);
    function amounts() external view returns (uint256, uint256, uint256);
    function isOpened(uint256 offset) external view returns (bool);

    // ### Questions ###

    function getQuestionsLength() external view returns (uint256);
    function getQuestions(uint256 cursor, uint256 length) external view returns (Question[] memory);

    // ### Validators ###

    function getValidatorsLength(uint256 questionIndex) external view returns (uint256);
    function getValidators(uint256 questionIndex) external view returns (Validator[] memory);

    // ### Participants ###
    
    function getParticipantsLength() external view returns (uint256);
    function getParticipants(uint256 cursor, uint256 length) external view returns (address[] memory);
    function isParticipant(address account) external view returns (bool);

    // ### Participations ###

    function getParticipations(uint256 cursor, uint256 length) external view returns (Participation[] memory);
    function findParticipation(address account) external view returns (Participation memory);

    // ### Responses ###

    function getResponses(uint256 questionIndex, uint256 cursor, uint256 length) external view returns (string[] memory);
    function getResponseCounts(uint256 questionIndex) external view returns (ResponseCount[] memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {

    /// @notice Transfers tokens from the targeted address to the given destination
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: transferFrom failed');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: transfer failed');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: approve failed');
    }

    /// @notice Transfers ETH to the recipient address
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: transferETH failed');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface for wrapped native currency.
 */
interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IForwarder {

    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }

    event MetaTransactionExecuted(address indexed from, address indexed to, bytes indexed data);
    event AddressWhitelisted(address indexed sender);
    event AddressRemovedFromWhitelist(address indexed sender);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `execute`, as defined by {EIP712}.
     * See https://eips.ethereum.org/EIPS/eip-712
     */
    function DOMAIN_SEPARATOR()
    external view
    returns (bytes32);

    /**
     * @dev Returns the custody address of the gas reserve.
     */
    function custody()
    external view
    returns (address);

    /**
     * @dev Retrieves the on-chain tracked nonce of an EOA making the request.
     */
    function getNonce(address from)
    external view
    returns(uint256);

    /**
     * @dev Verify the transaction would execute.
     * Validate the signature and the nonce of the request.
     * Revert if either signature or nonce are incorrect.
     */
    function verify(
        ForwardRequest calldata forwardRequest,
        bytes calldata signature
    ) 
    external view 
    returns (bool);

    /**
     * @dev Execute a transaction
     * The transaction is verified, and then executed.
     * The `success` and `returndata` of `call` are returned.
     * This method would revert only verification errors, target errors 
     * are reported using the returned data.
     */
    function execute(
        ForwardRequest calldata forwardRequest,
        bytes calldata signature
    )
    external payable 
    returns (bool, bytes memory);

    /**
     * @dev Retrieves the information whether an address is whitelisted or not.
     */
    function isWhitelisted(address sender)
    external view
    returns (bool);

    /**
     * @dev Only whitelisted addresses are allowed to broadcast meta-transactions.
     */
    function addSenderToWhitelist(address sender)
    external;

    /**
     * @dev Removes a whitelisted address.
     */
    function removeSenderFromWhitelist(address sender)
    external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IForwarder.sol";

/**
 * @dev Contract to assign trusted forwarder with ERC2771 support
 */
abstract contract Forwardable is Ownable {

    IForwarder public forwarderCnt;

    event ForwardingTransferred(address indexed previousForwarder, address indexed newForwarder);

    /**
     * @dev Initializes the contract setting the deployer as the initial forwarder.
     */
    constructor(address forwarder) {
        require(forwarder != address(0), "Forwardable: invalid forwarder address");
        setTrustedForwarder(forwarder);
    }

    /**
     * @dev Return true if the forwarder is trusted by the recipient.
     */
    function isTrustedForwarder(address forwarder) public view virtual returns(bool) {
        return forwarder == address(forwarderCnt);
    }

    /**
     * @dev Only the owner can change the forwarder.
     */
    function setTrustedForwarder(address newForwarder) public virtual onlyOwner {
        address oldForwarder = address(forwarderCnt);
        forwarderCnt = IForwarder(newForwarder);
        emit ForwardingTransferred(oldForwarder, newForwarder);
    }

    /**
     * @dev Throws if called by any account other than the forwarder.
     */
    modifier onlyTrustedForwarder() {
        require(isTrustedForwarder(_msgSender()), "Forwardable: caller is not the forwarder");
        _;
    }

    /**
     * @dev Return the sender of this call.
     * If the call came through our trusted forwarder, return the original sender.
     * Otherwise, return `msg.sender`.
     * Should be used in the contract anywhere instead of msg.sender or _msgSender()
     */
    function _fwdSender() internal view virtual returns (address sender) {
        if (msg.data.length>=20 && isTrustedForwarder(_msgSender())) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return _msgSender();
        }
    }

    /**
     * @dev Return the data of this call.
     * If the call came through our trusted forwarder, return the original data.
     * Otherwise, return `msg.data`.
     * Should be used in the contract anywhere instead of msg.data or _msgData()
     */
    function _fwdData() internal view virtual returns (bytes calldata) {
        if (msg.data.length>=20 && isTrustedForwarder(_msgSender())) {
            return msg.data[:msg.data.length - 20];
        } else {
            return _msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}