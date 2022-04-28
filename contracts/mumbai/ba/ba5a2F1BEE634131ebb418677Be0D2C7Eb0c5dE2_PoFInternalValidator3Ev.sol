/**
 *Submitted for verification at polygonscan.com on 2022-04-27
*/

// Sources flattened with hardhat v2.9.1 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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


// File contracts/PoFInternalValidator3Ev.sol


pragma solidity ^0.8.12;
interface IPoFRegulator {
    function reward(
        address payable,
        address,
        uint256
    ) external;
}

/**
@title PoF Internal Validator Node 
@author Javier Ortin
@notice Proof of Feedback node in charge of selecting the jurors and sending the final decision to the regulator node
@dev First draft.
*/
contract PoFInternalValidator3Ev is Ownable {
    ///Events of the contract.

    event AddedJuror(address jurorAdress);
    event RemovedJuror(address jurorAdress);
    event UpdatedMaxEvaluation(uint256 newMaxEvaluation);
    event FeedbackRegistered(address feedbackID);
    event FeedbackEvaluated(
        address feedbackID,
        address juror,
        uint256 originality,
        uint256 usefulness,
        uint256 execution,
        uint256 alreadyEvaluated
    );

    /// Data of the contract

    /// @dev Map used to whitelist jurors
    mapping(address => bool) public isJuror;

    /// @dev Array containing the addresses of the jurors
    address[] private jurors;

    /// @dev total amount of jurors in the internal validator
    uint256 totalJurors = 0;

    /** 
    @notice Structure for given feedback
    @dev customer is a payable address
    @param evaluated how many jurors have already evaluated
    */
    struct Feedback {
        address customer;
        address juror1;
        address juror2;
        address juror3;
        mapping(address => uint256) evaluations;
        bool registered;
        uint256 evaluated;
        uint256 finalEvaluation;
    }

    /// @dev mapp for given feedbacks
    /// TODO! Decide if this should be public
    mapping(address => Feedback) public feedbacks;

    /// @dev minimum amount of jurors that the internal validator must have
    ///      to have a fair random selection of jurors
    uint256 public minJurors = 7;

    /// @notice PoF Regulator node to which this validator connects
    address public pofRegulator;

    /// @notice Maximum points that a feedback can get
    /// @dev TODO! Syncronization mechanism with the regulator node
    uint256 public maxEvaluation;

    /// @notice Code of the country (ISO 3166) where this validator operates
    /// @dev Code should follow the ISO 3166 standard
    ///      TODO! Check if is needed (in that case also sync with regulator)
    string public countryCode;

    constructor(
        address _pofRegulator,
        uint256 _maxEvaluation,
        string memory _countryCode
    ) {
        pofRegulator = _pofRegulator;
        maxEvaluation = _maxEvaluation;
        countryCode = _countryCode;
    }

    /// Modifiers

    /**
     * @dev Throws if called by any account that is the PoF regulator.
     */
    modifier onlyRegulator() {
        require(
            pofRegulator == _msgSender(),
            "Regulator: caller is not PoF Regulator"
        );
        _;
    }

    /**
     * @dev Throws if called by any account that is not a juror.
     */
    modifier onlyJuror() {
        require(
            isJuror[_msgSender()],
            "Juror: caller is not a PoF Internal node juror"
        );
        _;
    }

    /// Functions

    /**
    @param juror new address to be added as a juror
    @dev adds a new juror address to the map and array of jurors
    */
    function addJuror(address juror) public onlyOwner {
        require(juror != address(0x0), "Zero address cannot be an juror");
        require(!isJuror[juror], "Address is already a juror");
        jurors.push(juror);
        isJuror[juror] = true;
        totalJurors++;
        emit AddedJuror(juror);
    }

    /**
    @param juror address to be removed 
    @dev removes a juror address from the map and array of jurors
    */
    function removeJuror(address juror) public onlyOwner {
        require(isJuror[juror], "Address must be a juror");
        for (uint256 i = 0; i < jurors.length; i++) {
            if (jurors[i] == juror) {
                jurors[i] = jurors[jurors.length - 1];
                jurors.pop();
                isJuror[juror] = false;
                totalJurors--;
                emit RemovedJuror(juror);
            }
        }
    }

    /**
    Set new maximum evaluation that a feedback can have 
    @param _maxEvaluation new maximum evaluation points 
    @dev stores the new value in maxEvaluation
    */
    function setMaxEvaluation(uint256 _maxEvaluation) public onlyRegulator {
        maxEvaluation = _maxEvaluation;
        emit UpdatedMaxEvaluation(_maxEvaluation);
    }

    /**
    Insertion of the feedback in to the blockchain
    @param feedbackID id of the given feedback in the form of a valid address. 
    @dev TODO! Check if there should be a better way for the requirement. 
               rn if no one has evaluated the feedback can be reinserted. 
               We could say that so far nobody has evaluated the customer 
               can edit the submission.
         TODO! How to prevent feedback flooding. Adding an id verification node.
               Whitelisting

    */
    function askFeedbackEvaluation(address feedbackID) public {
        require(
            totalJurors >= minJurors,
            "There are not enough jurors to use the PoF"
        );
        require(!feedbacks[feedbackID].registered, "Feedback must be new.");
        feedbacks[feedbackID].customer = _msgSender();
        address juror1;
        address juror2;
        address juror3;
        (juror1, juror2, juror3) = randomJurors(feedbackID);
        feedbacks[feedbackID].juror1 = juror1;
        feedbacks[feedbackID].juror2 = juror2;
        feedbacks[feedbackID].juror3 = juror3;
        feedbacks[feedbackID].registered = true;
        emit FeedbackRegistered(feedbackID);
    }

    function evaluateFeedback(
        address feedbackID,
        uint256 originality,
        uint256 usefulness,
        uint256 execution
    ) public onlyJuror {
        require(
            _msgSender() == feedbacks[feedbackID].juror1 ||
                _msgSender() == feedbacks[feedbackID].juror2 ||
                _msgSender() == feedbacks[feedbackID].juror3,
            "The juror must have the feedback assigned for evaluation"
        );
        require(
            originality <= maxEvaluation &&
                usefulness <= maxEvaluation &&
                execution <= maxEvaluation,
            "Evaluation cannot be more than the maximum"
        );
        feedbacks[feedbackID].evaluations[_msgSender()] =
            (originality + usefulness + execution) /
            3;
        feedbacks[feedbackID].evaluated++;
        emit FeedbackEvaluated(
            feedbackID,
            _msgSender(),
            originality,
            usefulness,
            execution,
            feedbacks[feedbackID].evaluated
        );
        if (feedbacks[feedbackID].evaluated == 3) {
            finalEvaluation(feedbackID);
        }
    }

    /**
    Calculation of the final evaluation. Arithmetic mean.
    @param feedbackID id of the given feedback in the form of a valid address. 
    @dev TODO! Discuss if it should not be a geometric mean. 
               That way jurors would have veto power by giving a zero evaluation

    */
    function finalEvaluation(address feedbackID) private {
        uint256 evaluation = (
            feedbacks[feedbackID].evaluations[feedbacks[feedbackID].juror1] +
            feedbacks[feedbackID].evaluations[feedbacks[feedbackID].juror2] +
            feedbacks[feedbackID].evaluations[feedbacks[feedbackID].juror3]) /
            3;
        IPoFRegulator(pofRegulator).reward(
            payable(feedbacks[feedbackID].customer),
            feedbackID,
            evaluation
        );
    }

    function randomJurors(address feedbackID)
        private
        view
        returns (
            address,
            address,
            address
        )
    {
        uint256 index = uint256(uint160(address(feedbackID)));
        uint256 i1 = index % totalJurors;
        uint256 i2 = (index / totalJurors) % totalJurors;
        uint256 i3;
        if (i2 == i1) i2 = (i2 + 1) % totalJurors;
        if (i1 != 0 && i2 != 0) i3 = (i1 + i2) % totalJurors;
        else {
            i3 = (i1 + i2 + 1) % totalJurors;
            if (i3 == 0) ++i3;
        }
        return (jurors[i1], jurors[i2], jurors[i3]);
    }
}