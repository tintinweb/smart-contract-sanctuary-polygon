// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISurveyConfig.sol";

contract SurveyConfig is ISurveyConfig, Ownable {

    address public override surveyFactory;
    address public override surveyValidator;

    // Storage settings
    uint256 public override surveyMaxPerRequest = 100;
    uint256 public override questionMaxPerRequest = 100;
    uint256 public override responseMaxPerRequest = 100;
    uint256 public override participantMaxPerRequest = 100;
    uint256 public override participationMaxPerRequest = 100;
    uint256 public override txGasMaxPerRequest = 100;

    // Engine settings
    uint256 public override fee = 10000000000000000; // 0.01 per participation during survey creation
    address public override feeTo;

    constructor(address _factory, address _validator) {
        require(_factory != address(0), "SurveyEngine: invalid factory address");
        require(_validator != address(0), "SurveyEngine: invalid validator address");

        surveyFactory = _factory;
        surveyValidator = _validator;
        feeTo = _msgSender();
    }

    // ### Owner functions ###

    function setSurveyFactory(address newFactory) external override onlyOwner {
        address oldFactory = surveyFactory;
        surveyFactory = newFactory;
        emit SurveyFactoryChanged(oldFactory, newFactory);
    }

    function setSurveyValidator(address newValidator) external override onlyOwner {
        address oldValidator = surveyValidator;
        surveyValidator = newValidator;
        emit SurveyValidatorChanged(oldValidator, newValidator);
    }

    function setSurveyMaxPerRequest(uint256 _surveyMaxPerRequest) external override onlyOwner {
        surveyMaxPerRequest = _surveyMaxPerRequest;
    }

    function setQuestionMaxPerRequest(uint256 _questionMaxPerRequest) external override onlyOwner {
        questionMaxPerRequest = _questionMaxPerRequest;
    }

    function setResponseMaxPerRequest(uint256 _responseMaxPerRequest) external override onlyOwner {
        responseMaxPerRequest = _responseMaxPerRequest;
    }

    function setParticipantMaxPerRequest(uint256 _participantMaxPerRequest) external override onlyOwner {
        participantMaxPerRequest = _participantMaxPerRequest;
    }

    function setParticipationMaxPerRequest(uint256 _participationMaxPerRequest) external override onlyOwner {
        participationMaxPerRequest = _participationMaxPerRequest;
    }

    function setTxGasMaxPerRequest(uint256 _txGasMaxPerRequest) external override onlyOwner {
        txGasMaxPerRequest = _txGasMaxPerRequest;
    }

    function setFee(uint256 _fee) external override onlyOwner {
        fee = _fee;
    }

    function setFeeTo(address _feeTo) external override onlyOwner {
        feeTo = _feeTo;
    }
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