// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./interfaces/ISurveyStorage.sol";
import "./interfaces/ISurveyImpl.sol";
import "./interfaces/ISurveyConfig.sol";
import "../abstractions/Manageable.sol";

contract SurveyStorage is ISurveyStorage, Manageable {

    ISurveyConfig internal configCnt;
    
    address[] internal _surveys;
    uint256[10000] internal _txGasSamples;// samples to calculate the average meta-transaction gas

    mapping(address => bool) internal _surveyFlags;// survey address => flag
    mapping(address => address[]) internal _ownSurveys;// survey owner => survey addresses

    mapping(uint256 => PartID) internal _participations;// index => (survey address, part owner)
    mapping(address => address[]) internal _ownParticipations;// part owner => survey addresses

    uint256 public override totalGasReserve;// total gas reserve for all surveys
    uint256 internal _partIndex;
    uint256 internal _txSampleIndex;
    uint256 internal _txSampleLength;

    constructor(address _config) {
        require(_config != address(0), "SurveyStorage: invalid config address");
        configCnt = ISurveyConfig(_config);
    }

    function surveyConfig() external view virtual override returns (address) {
        return address(configCnt);
    }

    function txGasSamples(uint256 maxLength) external view override returns (uint256[] memory) {
        require(maxLength > 0 && maxLength <= configCnt.txGasMaxPerRequest(), "SurveyStorage: oversized length of tx gas samples");
        uint256 length = (maxLength <= _txSampleLength)? maxLength: _txSampleLength;
        uint256[] memory array = new uint256[](length);
        uint256 cursor;
        uint256 count;

        if(length > _txSampleIndex) {
            cursor = _txSampleLength - (length - _txSampleIndex);

            for(uint i = cursor; i < _txSampleLength; i++) {
                array[count++] = _txGasSamples[i];
            }
        }

        cursor = (length < _txSampleIndex)? _txSampleIndex - length: 0;

        for(uint i = cursor; i < _txSampleIndex; i++) {
            array[count++] = _txGasSamples[i];
        }

        return array;
    }

    function remainingBudgetOf(address surveyAddr) external view override returns (uint256) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).remainingBudget();
    }

    function remainingGasReserveOf(address surveyAddr) external view override returns (uint256) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).remainingGasReserve();
    }

    function amountsOf(address surveyAddr) external view override returns (uint256, uint256, uint256) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).amounts();
    }

    // ### Surveys ###

    function exists(address surveyAddr) external view override returns (bool) {
        require(surveyAddr != address(0), "SurveyStorage: invalid survey address");
        return _surveyFlags[surveyAddr];
    }

    function getSurveysLength() external view override returns (uint256) {
        return _surveys.length;
    }

    function getAddresses(uint256 cursor, uint256 length) external view override returns (address[] memory) {
        require(cursor < _surveys.length, "SurveyStorage: cursor out of range");
        require(length > 0 && cursor+length <= _surveys.length, "SurveyStorage: invalid length from current position");
        require(length <= configCnt.surveyMaxPerRequest(), "SurveyStorage: oversized length of surveys");

        address[] memory array = new address[](length);

        for (uint i = cursor; i < cursor+length; i++) {
            array[i-cursor] = _surveys[i];
        }

        return array;
    }

    function getSurveys(uint256 cursor, uint256 length) external view override returns (Survey[] memory) {
        require(cursor < _surveys.length, "SurveyStorage: cursor out of range");
        require(length > 0 && cursor+length <= _surveys.length, "SurveyStorage: invalid length from current position");
        require(length <= configCnt.surveyMaxPerRequest(), "SurveyStorage: oversized length of surveys");

        Survey[] memory array = new Survey[](length);

        for (uint i = cursor; i < cursor+length; i++) {
            array[i-cursor] = ISurveyImpl(_surveys[i]).data();
        }

        return array;
    }

    function findSurvey(address surveyAddr) external view override returns (Survey memory) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).data();
    }

    function isOpenedSurvey(address surveyAddr, uint256 offset) external view override returns (bool) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).isOpened(offset);
    }

    // ### Own Surveys ###

    function getOwnSurveysLength() external view override returns (uint256) {
        return _ownSurveys[_msgSender()].length;
    }

    function getOwnSurveys(uint256 cursor, uint256 length) external view override returns (Survey[] memory) {
        address[] memory senderSurveys = _ownSurveys[_msgSender()];
        require(cursor < senderSurveys.length, "SurveyStorage: cursor out of range");
        require(length > 0 && cursor+length <= senderSurveys.length, "SurveyStorage: invalid length from current position");
        require(length <= configCnt.surveyMaxPerRequest(), "SurveyStorage: oversized length of surveys");

        Survey[] memory array = new Survey[](length);
        for (uint i = cursor; i < cursor+length; i++) {
            array[i-cursor] = ISurveyImpl(senderSurveys[i]).data();
        }
        return array;
    }

    // ### Questions ###

    function getQuestionsLength(address surveyAddr) external view override returns (uint256) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).getQuestionsLength();
    }

    function getQuestions(address surveyAddr, uint256 cursor, uint256 length) external view override returns (Question[] memory) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).getQuestions(cursor, length);
    }

    // ### Validators ###

    function getValidatorsLength(address surveyAddr, uint256 questionIndex) external view override returns (uint256) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).getValidatorsLength(questionIndex);
    }

    function getValidators(address surveyAddr, uint256 questionIndex) external view override returns (Validator[] memory) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).getValidators(questionIndex);
    }

    // ### Participants ###

    function getParticipantsLength(address surveyAddr) external view override returns (uint256) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).getParticipantsLength();
    }

    function getParticipants(address surveyAddr, uint256 cursor, uint256 length) external view override returns (address[] memory) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).getParticipants(cursor, length);
    }

    function isParticipant(address surveyAddr, address account) external view override returns (bool) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).isParticipant(account);
    }

    // ### Participations ###

    function getParticipationsTotal() external view override returns (uint256) {
        return _partIndex;
    }

    function getGlobalParticipations(uint256 cursor, uint256 length) external view override returns (Participation[] memory) {
        require(cursor < _partIndex, "SurveyStorage: cursor out of range");
        require(length > 0 && cursor+length <= _partIndex, "SurveyStorage: invalid length from current position");
        require(length <= configCnt.participationMaxPerRequest(), "SurveyStorage: oversized length of participations");

        Participation[] memory array = new Participation[](length);
        PartID memory partID;

        for (uint i = cursor; i < cursor+length; i++) {
            partID = _participations[i];
            array[i-cursor] = ISurveyImpl(partID.surveyAddr).findParticipation(partID.partOwner);
        }

        return array;
    }

    function getParticipations(address surveyAddr, uint256 cursor, uint256 length) external view override returns (Participation[] memory) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).getParticipations(cursor, length);
    }

    function findParticipation(address surveyAddr, address account) external view override returns (Participation memory) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).findParticipation(account);
    }

    // ### Own Participations ###

    function getOwnParticipationsLength() external view override returns (uint256) {
        return _ownParticipations[_msgSender()].length;
    }

    function getOwnParticipations(uint256 cursor, uint256 length) external view override returns (Participation[] memory) {
        address[] memory senderParticipations = _ownParticipations[_msgSender()];
        require(cursor < senderParticipations.length, "SurveyStorage: cursor out of range");
        require(length > 0 && cursor+length <= senderParticipations.length, "SurveyStorage: invalid length from current position");
        require(length <= configCnt.participationMaxPerRequest(), "SurveyStorage: oversized length of participations");

        Participation[] memory array = new Participation[](length);
        for (uint i = cursor; i < cursor+length; i++) {
            array[i-cursor] = ISurveyImpl(senderParticipations[i]).findParticipation(_msgSender());
        }
        return array;
    }

    function findOwnParticipation(address surveyAddr) external view override returns (Participation memory) {
        verify(surveyAddr);
       return ISurveyImpl(surveyAddr).findParticipation(_msgSender());
    }

    // ### Responses ###

    function getResponses(address surveyAddr, uint256 questionIndex, uint256 cursor, uint256 length) external view override returns (string[] memory) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).getResponses(questionIndex, cursor, length);
    }

    function getResponseCounts(address surveyAddr, uint256 questionIndex) external view override returns (ResponseCount[] memory) {
        verify(surveyAddr);
        return ISurveyImpl(surveyAddr).getResponseCounts(questionIndex);
    }

    // ### Manager functions ###

    function saveSurvey(address senderAddr, address surveyAddr, uint256 gasReserve) external override onlyManager returns (address) {
        _surveys.push(surveyAddr);
        _surveyFlags[surveyAddr] = true;
        _ownSurveys[senderAddr].push(surveyAddr);
        totalGasReserve += gasReserve;
        return surveyAddr;
    }

    function addParticipation(Participation calldata participation, string calldata key) external override onlyManager {
        ISurveyImpl(participation.surveyAddr).addParticipation(participation, key);

        PartID memory partID;
        partID.surveyAddr = participation.surveyAddr;
        partID.partOwner = participation.partOwner;

        _participations[_partIndex++] = partID;
        _ownParticipations[participation.partOwner].push(participation.surveyAddr);

        if(participation.txGas > 0) {
            uint256 txPrice = tx.gasprice * participation.txGas;
            totalGasReserve -= txPrice;
            // Save sample to calculate the following costs
            _txGasSamples[_txSampleIndex++] = participation.txGas;

            if(_txSampleIndex == _txGasSamples.length) {
                _txSampleIndex = 0;
            }

            if(_txSampleLength < _txGasSamples.length) {
                _txSampleLength++;
            }
        }
    }

    function solveSurvey(address surveyAddr) external override onlyManager {
        uint256 withdrawnGasReserve = ISurveyImpl(surveyAddr).solveSurvey();
        totalGasReserve -= withdrawnGasReserve;
    }

    function increaseGasReserve(address surveyAddr, uint256 amount) external override onlyManager {
        ISurveyImpl(surveyAddr).increaseGasReserve(amount);
        totalGasReserve += amount;
    }

    // ### Internal functions ###

    function verify(address surveyAddr) internal view  {
        require(_surveyFlags[surveyAddr], "SurveyStorage: survey not found");
    }
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Contract to assign access to specific functions to the management contract.
 */
abstract contract Manageable is Ownable {

    address private _manager;
    event ManagementTransferred(address indexed previousManager, address indexed newManager);

    /**
     * @dev Initializes the contract setting the deployer as the initial manager.
     */
    constructor() {
        setManager(_msgSender());
    }

    /**
     * @dev Returns the address of the current manager.
     */
    function manager() public view virtual returns (address) {
        return _manager;
    }

    /**
     * @dev Only the owner can change the manager.
     */
    function setManager(address newManager) public virtual onlyOwner {
        address oldManager = _manager;
        _manager = newManager;
        emit ManagementTransferred(oldManager, newManager);
    }

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        require(manager() == _msgSender(), "Manageable: caller is not the manager");
        _;
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