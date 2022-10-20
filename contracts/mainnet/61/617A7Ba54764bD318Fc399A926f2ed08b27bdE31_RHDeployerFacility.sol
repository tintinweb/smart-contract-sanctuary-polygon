// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IRHFundDeployer.sol";
import "./interfaces/IRHAssetDeployer.sol";
import "./interfaces/IRHTokenDeployer.sol";
import "./interfaces/IRHWLDeployer.sol";
import "./interfaces/IRHInvestorFactory.sol";

contract RHDeployerFacility is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    IRHFundDeployer private fundDeplContract;
    IRHAssetDeployer private assetDeplContract;
    IRHWLDeployer private wlDeplContract;
    IRHTokenDeployer private tokenDeplContract;
    IRHInvestorFactory private investorFactContract;

    /**
     * @dev new fund contract deployed
     * @param newFund new fund address
     * @param name new fund name
     */
    event FundContractAdded(address indexed newFund, string name);

    /**
     * @dev new investor smart contract deployed
     * @param newInvSC new investor smart contract address
     * @param invData new investor smart contract data
     */
    event InvestorSCAdded(address indexed newInvSC, string invData);

    /**
     * @dev deployer facility contract constructor
     * @param _fundAddr fund deployer address
     * @param _secAddr asset deployer address
     * @param _wlAddr WL deployer address
     * @param _tokenAddr token deployer address
     * @param _invFactAddress investor smart contract factory address
     */
    constructor(address _fundAddr,
            address _secAddr,
            address _wlAddr,
            address _tokenAddr,
            address _invFactAddress) {
        fundDeplContract = IRHFundDeployer(_fundAddr);
        assetDeplContract = IRHAssetDeployer(_secAddr);
        wlDeplContract = IRHWLDeployer(_wlAddr);
        tokenDeplContract = IRHTokenDeployer(_tokenAddr);
        investorFactContract = IRHInvestorFactory(_invFactAddress);
    }

    /**
    * @dev set fund deployer contract address (onlyOwner)
    * @param _fundAddr address of fund deployer contract to add
    */
    function setFundDeployerContract(address _fundAddr) external onlyOwner {
        require(_fundAddr != address(0), "address not allowed!");
        fundDeplContract = IRHFundDeployer(_fundAddr);
    }

    /**
    * @dev set WL deployer contract address (onlyOwner)
    * @param _wlAddr address of WL deployer contract to add
    */
    function setWLDeployerContract(address _wlAddr) external onlyOwner {
        require(_wlAddr != address(0), "address not allowed!");
        wlDeplContract = IRHWLDeployer(_wlAddr);
    }

    /**
    * @dev set asset deployer contract address (onlyOwner)
    * @param _secAddr address of asset deployer contract to add
    */
    function setAssetDeployerContract(address _secAddr) external onlyOwner {
        require(_secAddr != address(0), "address not allowed!");
        assetDeplContract = IRHAssetDeployer(_secAddr);
    }

    /**
    * @dev set token deployer contract address (onlyOwner)
    * @param _tokenAddr address of token deployer contract to add
    */
    function setTokenDeployerContract(address _tokenAddr) external onlyOwner {
        require(_tokenAddr != address(0), "Address not allowed");
        tokenDeplContract = IRHTokenDeployer(_tokenAddr);
    }

    /**
    * @dev set investor factory contract address (onlyOwner)
    * @param _invFactAddr address of investor factory contract to add
    */
    function setInvestorFactoryContract(address _invFactAddr) external onlyOwner {
        require(_invFactAddr != address(0), "Address not allowed");
        investorFactContract = IRHInvestorFactory(_invFactAddr);
    }

    /**
    * @dev initialize all deployers settings addresses (onlyOwner)
    */
    function initializeDeployers() external onlyOwner{
        fundDeplContract.setAssetDeployerContract(address(assetDeplContract));
        fundDeplContract.setWLDeployerContract(address(wlDeplContract));
        wlDeplContract.setAssetDeployerContract(address(assetDeplContract));
        assetDeplContract.setFundDeployerContract(address(fundDeplContract));
        assetDeplContract.setWLDeployerContract(address(wlDeplContract));
        assetDeplContract.setTokenDeployerContract(address(tokenDeplContract));
        tokenDeplContract.setAssetDeployerContract(address(assetDeplContract));
    }

    /**
    * @dev add new deployed fund contract address to asset and whitelist deployers (onlyOwner)
    * @param _fund address of fund contract to add
    */
    function addFundToDeployers(address _fund) public onlyOwner {
        require(_fund != address(0), "address not allowed!");
        assetDeplContract.addAllowedFundContract(_fund);
        wlDeplContract.addAllowedContractByFacility(_fund);
    }

    /**
    * @dev add a contract address to whitelist deployer (onlyOwner)
    * @param _contract address of the contract to add
    */
    function addContractToWLDepl(address _contract) external onlyOwner {
        require(_contract != address(0), "address not allowed!");
        wlDeplContract.addAllowedContractByFacility(_contract);
    }

    /**
    * @dev call the fund deployer to deploy a new fund contract, adding its address to all other deployers (onlyOwner)
    * @param _initialOwner address of the contract owner
    * @param _name name of the fund
    * @param _vatNumber fund VAT number
    * @param _companyRegNumber fund company registration number
    * @param _stateOfIncorporation nation where the fund is placed
    * @param _physicalAddressOfOperation physical address of the fund
    * @return newFund address of the deployed fund contract
    */
    function createFund(address _initialOwner,
            string memory _name,
            string memory _vatNumber,
            string memory _companyRegNumber,
            string memory _stateOfIncorporation,
            string memory _physicalAddressOfOperation) external nonReentrant onlyOwner returns (address) {
        address newFund = fundDeplContract.deployFund(_initialOwner, _name, _vatNumber,
                        _companyRegNumber, _stateOfIncorporation, _physicalAddressOfOperation);
        addFundToDeployers(newFund);
        emit FundContractAdded(newFund, _name);
        return newFund;
    }

    /**
     * @dev call the investor factory to deploy a new investor contract (onlyOwner)
     * @param _invData string to identify investor
     */
    function createNewInvestorSC(string memory _invData) external onlyOwner returns (address) {
        address newInvSC = investorFactContract.deployNewInvestor(_invData);
        emit InvestorSCAdded(newInvSC, _invData);
        return newInvSC;
    }

    /**
    * @dev add a contract address to whitelist deployer (onlyOwner)
    * @return last deployed fund contract address
    */
    function getLastFundContractAddress() external view onlyOwner returns (address) {
        uint256 counter = fundDeplContract.getDeployedFundCounter();
        require(counter > 0, "No fund contract deployed");
        return fundDeplContract.getDeployedFundsAddress(counter - 1);
    }

    /**
    * @dev get environment contracts
    * @return fd fundDeplContract address
    * @return wd wlDeplContract address
    * @return ad assetDeplContract address
    * @return td tokenDeplContract address
    * @return invF investorFactContract address
    */
    function getEnvironmentContracts() external view returns(address fd, address wd, address ad, address td, address invF) {
        return (address(fundDeplContract), address(wlDeplContract), address(assetDeplContract),
                address(tokenDeplContract), address(investorFactContract));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IRHWLDeployer {
    function deployWhitelist(address _refContract) external returns (address);
    function getWLCounter() external view returns (uint256);
    function setDeployerFacility(address _deplFacAddr) external;
    function setAssetDeployerContract(address _secAddr) external;
    function getAssetDeployerContract() external view returns(address);
    function addAllowedContractByFacility(address _newContract) external;
    function addAllowedContractByAsset(address _asset) external;
    function isAllowedContract(address _address) external view returns (bool);
    function isWLDeployed(address _wlAddr) external view returns (bool);
    function getDeployedWLAddress(uint256 idx) external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IRHTokenDeployer {
    function getDeployedTokensCounter() external view returns (uint256);
    function isTokenDeployed(address _tokenAddr) external view returns (bool);
    function getDeployedTokenAddress(uint256 idx) external view returns(address);
    function getAllowedAsset(address _addr) external view returns (bool);
    function deployToken(address _fund,
            address _asset,
            address _wlAddress,
            string calldata name,
            string calldata ticker,
            string calldata tokenType,
            string calldata couponType,
            uint8 decimals,
            uint256 tokenRoi,
            uint256 hardCap,
            uint256 _issuanceNumber) external returns (address);
    function setDeployerFacility(address _deplFacAddr) external;
    function setAssetDeployerContract(address _secAddr) external;
    function getAssetDeployerContract() external view returns(address);
    function addAssetAllowedContract(address _asset) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IRHInvestorFactory {
    function setDeployerFacility(address _deplFacAddr) external;
    function deployNewInvestor(string memory _invData) external returns (address);
    function changeInvestorContractOwnership(address payable _investorContract, address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IRHFundDeployer {
    function setFundCounter(uint256 _newValue) external;
    function getDeployedFundCounter() external view returns(uint256);
    function getDeployedFundsAddress(uint256 idx) external view returns(address);
    function isFundDeployed(address _fundAddr) external view returns (bool);
    function deployFund(address _initialOwner,
        string calldata _name,
        string calldata _vatNumber,
        string calldata _companyRegNumber,
        string calldata _stateOfIncorporation,
        string calldata _physicalAddressOfOperation) external returns (address);
    function setDeployerFacility(address _deplFacAddr) external;
    function setAssetDeployerContract(address _secAddr) external;
    function getAssetDeployerContract() external view returns(address);
    function setWLDeployerContract(address _wlAddr) external;
    function getWLDeployerContract() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IRHAssetDeployer {
    function deployAsset(address refContract,
        address _assetWLAddr,
        string calldata _assetID,
        string calldata _name,
        string calldata _type) external returns (address);
    function addAllowedFundContract(address _newFundContract) external;
    function isAssetDeployed(address _assetAddress) external view returns (bool);
    function getAllowedFund(address _addr) external view returns (bool);
    function getDeployedAssetCounter() external view returns (uint256);
    function getDeployedAssetAddress(uint256 idx) external view returns(address);
    function getWLDeployerContract() external view returns(address);
    function setWLDeployerContract(address _wlDeplAddr) external;
    function getTokenDeployerContract() external view returns(address);
    function setTokenDeployerContract(address _tokenDeplAddr) external;
    function setFundDeployerContract(address _fundAddr) external;
    function getFundDeployerContract() external view returns(address);
    function setDeployerFacility(address _deplFacAddr) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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