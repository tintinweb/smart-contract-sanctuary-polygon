// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "opium-protocol-v2/contracts/interfaces/IDerivativeLogic.sol";

import "../utils/ThirdPartyExecutionSyntheticId.sol";

/**
    Error codes:
    - S1 = CAN_NOT_BE_ZERO_ADDRESS
 */
contract OptionPutSyntheticId is IDerivativeLogic, ThirdPartyExecutionSyntheticId, Ownable {
    address private author;
    uint256 private commission;

    uint256 public constant BASE = 1e18;

    constructor(address _author, uint256 _commission) {
        /*
        {
            "author": "Opium.Team",
            "type": "option",
            "subtype": "put",
            "description": "Option Put logic contract"
        }
        */
        emit LogMetadataSet("{\"author\":\"Opium.Team\",\"type\":\"option\",\"subtype\":\"put\",\"description\":\"Option Put logic contract\"}");

        author = _author;
        commission = _commission;

        // Transfer contract's ownership to author on deployment
        transferOwnership(_author);
    }

    // margin - reference value for option nominal
    // params[0] - strikePrice - denominated in E18
    // params[1] - collateralization
    // params[2] - fixedPremium - (optional)
    function validateInput(LibDerivative.Derivative calldata _derivative) external override pure returns (bool) {
        return (
            // Derivative
            _derivative.margin > 0 && // nominal > 0
            _derivative.params.length == 3 &&

            _derivative.params[0] > 0 && // Strike price > 0
            _derivative.params[1] <= BASE && _derivative.params[1] > 0 // 100% >= Collateralization > 0
        );
    }

    function getSyntheticIdName() external override pure returns (string memory) {
        return "OPT-P";
    }

    function getMargin(LibDerivative.Derivative calldata _derivative) external override pure returns (uint256 buyerMargin, uint256 sellerMargin) {
        uint256 collateralization = _derivative.params[1];
        uint256 fixedPremium = _derivative.params[2];
        buyerMargin = fixedPremium;

        uint256 nominal = _derivative.margin;
        sellerMargin = nominal * collateralization / BASE;
    }

    function getExecutionPayout(LibDerivative.Derivative calldata _derivative, uint256 _result) external override pure returns (uint256 buyerPayout, uint256 sellerPayout) {
        uint256 strikePrice = _derivative.params[0];
        uint256 collateralization = _derivative.params[1];
        uint256 fixedPremium = _derivative.params[2];
        uint256 nominal = _derivative.margin;
        uint256 sellerMargin = nominal * collateralization / BASE;

        // If result price is less than strike price, buyer is being paid out
        if (_result < strikePrice) {
            // Buyer payout is calculated as nominal multiplied by underlying result price depreciation from strike price
            buyerPayout = nominal * (strikePrice - _result) / strikePrice;

            // If Buyer payout exceeds the initial seller margin, then it's being capped (limited) by it
            if (buyerPayout > sellerMargin) {
                buyerPayout = sellerMargin;
            }

            // Seller payout is calculated as a reminder from seller margin and buyer payout
            sellerPayout = sellerMargin - buyerPayout;
        } else {
            // If result price is lower or equal to strike price, buyer is not being paid out
            buyerPayout = 0;
            
            // Seller receives its margin back as a payout
            sellerPayout = sellerMargin;
        }

        // Seller payout is always increased by fixed premium if specified
        sellerPayout = sellerPayout + fixedPremium;
    }

    /** COMMISSION */
    /// @notice Getter for syntheticId author address
    /// @return address syntheticId author address
    function getAuthorAddress() external override view returns (address) {
        return author;
    }

    /// @notice Getter for syntheticId author commission
    /// @return uint256 syntheticId author commission
    function getAuthorCommission() external override view returns (uint256) {
        return commission;
    }

    /** THIRDPARTY EXECUTION */
    function thirdpartyExecutionAllowed(address _derivativeOwner) external override view returns (bool) {
        return isThirdPartyExecutionAllowed[_derivativeOwner];
    }

    function allowThirdpartyExecution(bool _allow) external override {
        _allowThirdpartyExecution(msg.sender, _allow);
    }

    /** GOVERNANCE */
    function setAuthorAddress(address _author) external onlyOwner {
        require(_author != address(0), "S1");
        author = _author;
    }

    function setAuthorCommission(uint256 _commission) external onlyOwner {
        commission = _commission;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

import "../libs/LibDerivative.sol";

/// @title Opium.Interface.IDerivativeLogic is an interface that every syntheticId should implement
interface IDerivativeLogic {
    // Event with syntheticId metadata JSON string (for DIB.ONE derivative explorer)
    event LogMetadataSet(string metadata);

    /// @notice Validates ticker
    /// @param _derivative Derivative Instance of derivative to validate
    /// @return Returns boolean whether ticker is valid
    function validateInput(LibDerivative.Derivative memory _derivative) external view returns (bool);

    /// @return Returns the custom name of a derivative ticker which will be used as part of the name of its positions
    function getSyntheticIdName() external view returns (string memory);

    /// @notice Calculates margin required for derivative creation
    /// @param _derivative Derivative Instance of derivative
    /// @return buyerMargin uint256 Margin needed from buyer (LONG position)
    /// @return sellerMargin uint256 Margin needed from seller (SHORT position)
    function getMargin(LibDerivative.Derivative memory _derivative)
        external
        view
        returns (uint256 buyerMargin, uint256 sellerMargin);

    /// @notice Calculates payout for derivative execution
    /// @param _derivative Derivative Instance of derivative
    /// @param _result uint256 Data retrieved from oracleId on the maturity
    /// @return buyerPayout uint256 Payout in ratio for buyer (LONG position holder)
    /// @return sellerPayout uint256 Payout in ratio for seller (SHORT position holder)
    function getExecutionPayout(LibDerivative.Derivative memory _derivative, uint256 _result)
        external
        view
        returns (uint256 buyerPayout, uint256 sellerPayout);

    /// @notice Returns syntheticId author address for Opium commissions
    /// @return authorAddress address The address of syntheticId address
    function getAuthorAddress() external view returns (address authorAddress);

    /// @notice Returns syntheticId author commission in base of COMMISSION_BASE
    /// @return commission uint256 Author commission
    function getAuthorCommission() external view returns (uint256 commission);

    /// @notice Returns whether thirdparty could execute on derivative's owner's behalf
    /// @param _derivativeOwner address Derivative owner address
    /// @return Returns boolean whether _derivativeOwner allowed third party execution
    function thirdpartyExecutionAllowed(address _derivativeOwner) external view returns (bool);

    /// @notice Sets whether thirds parties are allowed or not to execute derivative's on msg.sender's behalf
    /// @param _allow bool Flag for execution allowance
    function allowThirdpartyExecution(bool _allow) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

contract ThirdPartyExecutionSyntheticId {
    // Mapping containing whether msg.sender allowed his positions to be executed by third party
    mapping (address => bool) internal isThirdPartyExecutionAllowed;

    function _allowThirdpartyExecution(address _user, bool _allow) internal {
        isThirdPartyExecutionAllowed[_user] = _allow;
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

/// @title Opium.Lib.LibDerivative contract should be inherited by contracts that use Derivative structure and calculate derivativeHash
library LibDerivative {
    enum PositionType {
        SHORT,
        LONG
    }

    // Opium derivative structure (ticker) definition
    struct Derivative {
        // Margin parameter for syntheticId
        uint256 margin;
        // Maturity of derivative
        uint256 endTime;
        // Additional parameters for syntheticId
        uint256[] params;
        // oracleId of derivative
        address oracleId;
        // Margin token address of derivative
        address token;
        // syntheticId of derivative
        address syntheticId;
    }

    /// @notice Calculates hash of provided Derivative
    /// @param _derivative Derivative Instance of derivative to hash
    /// @return derivativeHash bytes32 Derivative hash
    function getDerivativeHash(Derivative memory _derivative) internal pure returns (bytes32 derivativeHash) {
        derivativeHash = keccak256(
            abi.encodePacked(
                _derivative.margin,
                _derivative.endTime,
                _derivative.params,
                _derivative.oracleId,
                _derivative.token,
                _derivative.syntheticId
            )
        );
    }
}