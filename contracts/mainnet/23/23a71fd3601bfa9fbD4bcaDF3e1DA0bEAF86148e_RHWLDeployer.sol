// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./RHWhitelist.sol";
import "./interfaces/IRHAssetDeployer.sol";
import "./interfaces/IRHWLDeployer.sol";

contract RHWLDeployer is Ownable, IRHWLDeployer {
    using SafeMath for uint256;

    address private deplFacAddress;
    uint256 private wlCounter;

    IRHAssetDeployer private assetDeplContract;

    mapping(uint256 => address) internal _whitelists;
    mapping(address => bool) internal _whitelistDeployed;
    mapping(address => bool) private _allowedContracts;

    /**
     * @dev new whitelist deployed event
     * @param newWhitelist new whitelist address
     * @param _refContract fund address
     */
    event WLCreated(
        address indexed newWhitelist,
        address _refContract);

    // event NewDeployerFacility(address newDeplFaciltiy);

    /**
     * @dev whitelist deployer contract contructor
     */
    constructor() { }

    /** @notice check if msg.sender is an allowed contract */
    modifier onlyAllowedContracts() {
        require(_allowedContracts[msg.sender], "Address not allowed to create Whitelist!");
        _;
    }

    /** @notice check if msg.sender is the deployer facility contract */
    modifier onlyDeplFacility() {
        require(msg.sender == deplFacAddress, "Caller is not a Deployer Facility!");
        _;
    }

    /**
    * @dev set deployer facility contract address (onlyOwner)
    * @param _deplFacAddr deployer facility contract address to add
    */
    function setDeployerFacility(address _deplFacAddr) external override onlyOwner {
        require(_deplFacAddr != address(0), "Address not allowed");
        deplFacAddress = _deplFacAddr;
        // emit NewDeployerFacility(deplFacAddress);
    }

    /**
    * @dev set asset deployer contract address (onlyDeplFacility)
    * @param _secAddr asset deployer contract address to add
    */
    function setAssetDeployerContract(address _secAddr) external override onlyDeplFacility {
        require(_secAddr != address(0), "Address not allowed");
        assetDeplContract = IRHAssetDeployer(_secAddr);
    }

    /**
    * @dev get asset deployer contract address
    * @return assetDeplContract asset deployer contract address
    */
    function getAssetDeployerContract() external override view returns(address) {
        return address(assetDeplContract);
    }

    /**
    * @dev add a contract address to allowed contracts (onlyDeplFacility)
    * @param _newContract contract address to add
    */
    function addAllowedContractByFacility(address _newContract) external override onlyDeplFacility {
        require(_newContract != address(0), "Address not allowed");
        _allowedContracts[_newContract] = true;
    }

    /**
    * @dev add an asset address to allowed contracts, checking if it was deployed by asset deployer
    * @param _asset asset contract address to add
    */
    function addAllowedContractByAsset(address _asset) external override {
        require(_asset != address(0), "Address not allowed");
        require(assetDeplContract.isAssetDeployed(_asset), "Caller is not a asset");
        require(!_allowedContracts[_asset], "Asset address already added");
        _allowedContracts[_asset] = true;
    }

    /**
    * @dev check if a contract address is allowed on this deployer
    * @param _address address to check
    * @return _allowedContracts[_address] true if token address was allowed, otherwise false
    */
    function isAllowedContract(address _address) external override view returns (bool) {
        return _allowedContracts[_address];
    }

    /**
    * @dev get deployed WL contract counter
    * @return wlCounter number of deployed WL contracts
    */
    function getWLCounter() external override view returns (uint256) {
        return wlCounter;
    }

    /**
    * @dev check if a WL contract address was deployed by this deployer
    * @param _wlAddr address to check
    * @return _whitelistDeployed[_wlAddr] true if whitelist address was deployed, otherwise false
    */
    function isWLDeployed(address _wlAddr) external override view returns (bool) {
        return _whitelistDeployed[_wlAddr];
    }

    /**
    * @dev get deployed WL contract address as an item of an array
    * @param idx whitelist index
    * @return _whitelists[idx] idx-th whitelist contract address
    */
    function getDeployedWLAddress(uint256 idx) external override view returns(address) {
        return _whitelists[idx];
    }

    /**
    * @dev add deployed WL contract address to internal variables
    * @param newWLToAdd WL contract address to add
    */
    function addWLContractAddress(address newWLToAdd) internal {
        _whitelists[wlCounter] = newWLToAdd;
        wlCounter = wlCounter.add(1);
        _whitelistDeployed[newWLToAdd] = true;
    }

    /**
    * @dev deploy a new WL contract, add its address to internal variables and change the ownership to ref contract address (onlyAllowedContracts)
    * @param _refContract ref contract address (fund or asset contract)
    * @return newWhitelist the deployed WL contract address
    */
    function deployWhitelist(address _refContract) external override onlyAllowedContracts returns (address) {
        RHWhitelist newWhitelist = new RHWhitelist(_refContract);
        addWLContractAddress(address(newWhitelist));
        newWhitelist.transferOwnership(msg.sender);
        emit WLCreated(address(newWhitelist), _refContract);
        return address(newWhitelist);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IRHWhitelist {
    function isWhitelisted(address) external view returns(bool);
    function getWLLength() external view returns(uint256);
    function addToWhitelist(address) external;
    function addToWhitelistMassive(address[] calldata) external returns (bool);
    function removeFromWhitelist(address) external;
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

interface IRHFund {
    function setPhysicalAddressOfOperation(string calldata _newPhysicalAddressOfOperation) external;

    function isAdmin(address account) external view returns (bool);
    function addAdmin(address account) external;
    function removeAdmin(address account) external;
    function renounceAdmin() external;

    function addWLManagers(address) external;
    function removeWLManagers(address) external;
    function isWLManager(address) external view returns (bool);
    function renounceWLManager() external;

    function getAdminCounter() external view returns (uint256);
    function getWLManagerCounter() external view returns (uint256);

    function deployFundWL() external returns (address);
    function getFundWLAddress() external view returns (address);
    function deployNewAsset(string calldata _assetID,
            string calldata _name,
            string calldata _type) external returns (address);
    function getDeployedAssets(uint256 index) external view returns (address, bool, address);
    function getTotalDeployedAssets() external view returns (uint256);
    function addNewDocument(string calldata uri, bytes32 documentHash) external;
    function getDocInfos(uint256 _num) external view returns (string memory, bytes32, uint256);
    function getDocsCount() external view returns (uint256);
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
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRHFund.sol";
import "./interfaces/IRHWhitelist.sol";

contract RHWhitelist is Ownable, IRHWhitelist {
    using SafeMath for uint256;

    uint256 private whitelistLength;
    IRHFund public fundContract;

    mapping (address => bool) private whitelist;

    /**
     * @dev Whitelist address added event
     * @param addedAddress added whitelist address
     */
    event WLAddressAdded(address addedAddress);

    /**
     * @dev Whitelist massive addresses added event
     */
    event WLMassiveAddressesAdded();

    /**
     * @dev Whitelist address remove event
     * @param removedAddress removed whitelist address
     */
    event WLAddressRemoved(address removedAddress);

    /**
     * @dev whitelist contract contructor
     * @param _fundContract fund contract address
     */
    constructor(address _fundContract) {
        fundContract = IRHFund(_fundContract);
    }

    /** @notice check if msg.sender is a whitelist manager */
    modifier onlyWLManagers() {
        require(fundContract.isWLManager(msg.sender), "Not a Whitelist Manager!");
        _;
    }

    /*  Whitelisting  Mngmt  */
    /**
     * @dev check if an address is whitelisted
     * @param _subscriber address to be checked
     * @return whitelist[_subscriber] true if subscriber is whitelisted, false otherwise
     */
    function isWhitelisted(address _subscriber) external override view returns(bool) {
        return whitelist[_subscriber];
    }

    /**
     * @dev length of the whitelisted accounts
     * @return whitelistLength number of whitelisted addresses
     */
    function getWLLength() external override view returns(uint256) {
        return whitelistLength;
    }

    /**
     * @dev Add a subscriber address to the whitelist (onlyWLManagers)
     * @param _subscriber subscriber address to be added to the whitelist
     */
    function addToWhitelist(address _subscriber) external override onlyWLManagers {
        require(_subscriber != address(0), "_subscriber is zero");
        require(!whitelist[_subscriber], "already whitelisted");

        whitelist[_subscriber] = true;
        whitelistLength = whitelistLength.add(1);
        emit WLAddressAdded(_subscriber);
    }

    /**
     * @dev Add the subscriber list to the whitelist (max 100) (onlyWLManagers)
     * @param _subscribers subscriber address list to be added to the whitelist
     * @return _success true or fale
     */
    function addToWhitelistMassive(address[] calldata _subscribers) external override onlyWLManagers returns (bool _success) {
        require(_subscribers.length <= 100, "Too long list of addresses!");

        for (uint8 i = 0; i < _subscribers.length; i++) {
            require(_subscribers[i] != address(0), "subscriber address is zero");
            require(!whitelist[_subscribers[i]], "already whitelisted");

            whitelist[_subscribers[i]] = true;
            whitelistLength = whitelistLength.add(1);
        }

        emit WLMassiveAddressesAdded();
        return true;
    }

    /**
     * @dev Remove a subscriber address from the whitelist (onlyWLManagers)
     * @param _subscriber subscriber address to be remove from the whitelist.
     */
    function removeFromWhitelist(address _subscriber) external override onlyWLManagers {
        require(_subscriber != address(0), "_subscriber is zero");
        require(whitelist[_subscriber], "not whitelisted");

        whitelist[_subscriber] = false;
        whitelistLength = whitelistLength.sub(1);
        emit WLAddressRemoved(_subscriber);
    }

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