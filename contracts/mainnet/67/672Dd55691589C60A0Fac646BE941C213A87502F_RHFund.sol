// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IRHAssetDeployer.sol";
import "./interfaces/IRHWLDeployer.sol";
import "./interfaces/IRHFundDeployer.sol";
import "./interfaces/IRHAsset.sol";
import "./interfaces/IRHFund.sol";

contract RHFund is Ownable, ReentrancyGuard, IRHFund {
    using SafeMath for uint256;

    struct Asset {
        address assetAddress;
        bool isParticularWL;
        address wlAddress;
    }
    struct Doc {
        string docURI;          // URI of the document that exist off-chain
        bytes32 docHash;        // Hash of the document
        uint256 lastModified;   // Timestamp at which document details was last modified
    }

    string public name;
    string public vatNumber;
    string public companyRegNumber;
    string public stateOfIncorporation;
    string public physicalAddressOfOperation;
    uint256 private assetCounter;
    address private wlFund;
    uint256 private docsCounter;
    uint256 private adminCounter;
    uint256 private wlManCounter;

    IRHAssetDeployer private assetDeplContract;
    IRHWLDeployer private wlDeplContract;
    IRHFundDeployer private fundDeplContract;

    mapping(uint256 => Asset) internal assets;
    mapping(address => bool) internal fundAssets;
    mapping(address => bool) private _Admins;
    mapping(address => bool) private _WLManagers;
    mapping(uint256 => Doc) internal _documents;
    mapping(bytes32 => bool) internal _registeredHashes;

    /**
     * @dev new doc with hash added event
     * @param num counter for document
     * @param docuri link to external document
     * @param dochash document hash
     */
    event DocHashAdded(uint256 indexed num,
        string docuri,
        bytes32 dochash);

    /**
     * @dev change company physical address event
     * @param previousPhysicalAddressOfOperation counter for document
     * @param newPhysicalAddressOfOperation link to external document
     */
    event PhysicalAddressOfOperationUpdated(
        string previousPhysicalAddressOfOperation,
        string newPhysicalAddressOfOperation);

    /**
     * @dev new asset deployed event
     * @param newAsset new asset address
     * @param _assetID new asset ID
     * @param _name new asset name
     */
    event NewAssetDeployed(
        address indexed newAsset,
        string _assetID,
        string _name);

     /**
     * @dev asset owner changed event
     * @param assetTransferred transferred asset address
     * @param newFundAssetOwner new fund owner
     * @param blockNumber tx block number
     */
    event AssetOwnerChanged(
        address indexed assetTransferred, 
        address newFundAssetOwner,
        uint256 blockNumber);

    /**
     * @dev asset imported event
     * @param newAssetAddress transferred asset address
     * @param assetCounter new fund asset counter
     * @param blockNumber tx block number
     */
    event AssetImported(
        address indexed newAssetAddress, 
        uint256 assetCounter, 
        uint256 blockNumber);

    /**
    * @dev fund contract contructor
    * @param _initialOwner initial owner address (first admin)
    * @param _secDeployer asset deployer contract address
    * @param _wlDeployer WL deployer contract address
    * @param _name fund name
    * @param _vatNumber fund VAT number
    * @param _companyRegNumber company registration number of the fund
    * @param _stateOfIncorporation company state of incorporation
    * @param _physicalAddressOfOperation company physical address of operation
    */
    constructor (address _initialOwner,
            address _secDeployer,
            address _wlDeployer,
            string memory _name,
            string memory _vatNumber,
            string memory _companyRegNumber,
            string memory _stateOfIncorporation,
            string memory _physicalAddressOfOperation) {
        name = _name;
        vatNumber = _vatNumber;
        companyRegNumber = _companyRegNumber;
        stateOfIncorporation = _stateOfIncorporation;
        physicalAddressOfOperation = _physicalAddressOfOperation;
        adminCounter = 0;
        wlManCounter = 0;
        assetCounter = 0;
        ownerAddAdmin(_initialOwner);
        assetDeplContract = IRHAssetDeployer(_secDeployer);
        wlDeplContract = IRHWLDeployer(_wlDeployer);
        fundDeplContract = IRHFundDeployer(msg.sender);
    }

    /* Modifiers */
    /** @notice check if msg.sender is an administrator */
    modifier onlyAdmins() {
        require(isAdmin(msg.sender), "Not an Administrator!");
        _;
    }

    /** @notice check if msg.sender is a WL manager */
    modifier onlyWLManagers() {
        require(isWLManager(msg.sender), "Not a Whitelist Manager!");
        _;
    }

    /*   Admins Roles Mngmt  */
    /**
    * @dev add an admin to this fund
    * @param account new admin address
    */
    function _addAdmin(address account) internal {
        adminCounter = adminCounter.add(1); 
        _Admins[account] = true;
    }

    /**
    * @dev remove an admin from this asset
    * @param account admin address to remove, at least 1 admin has to remain in every fund contract
    */
    function _removeAdmin(address account) internal {
        require(adminCounter > 1, "Cannot remove last admin");
        adminCounter = adminCounter.sub(1); 
        _Admins[account] = false;
    }

    /**
    * @dev check if an address is an admin for this fund
    * @param account admin address to check
    * @return _Admins[account] true or false
    */
    function isAdmin(address account) public override view returns (bool) {
        return _Admins[account];
    }

    /**
    * @dev add an admin to this fund (onlyOwner). Called by the deployer facility only the first time
    * @param account new admin address
    */
    function ownerAddAdmin(address account) public onlyOwner {
        require(account != address(0), "Not a valid address!");
        require(!isAdmin(account), " Address already Administrator");
        _addAdmin(account);
    }

    /**
    * @dev add an admin to this fund (onlyAdmins)
    * @param account new admin address
    */
    function addAdmin(address account) external override onlyAdmins {
        require(account != address(0), "Not a valid address!");
        require(!isAdmin(account), " Address already Administrator");
        _addAdmin(account);
    }

    /**
    * @dev remove an admin from this fund (onlyAdmins)
    * @param account admin address to be removed
    */
    function removeAdmin(address account) external override onlyAdmins {
        _removeAdmin(account);
    }

    /**
    * @dev admin renounce (onlyAdmins)
    */
    function renounceAdmin() public override onlyAdmins {
        _removeAdmin(msg.sender);
    }

    /*   WL Roles Mngmt  */
    /**
    * @dev add a WL manager to this fund
    * @param account new WL manager address
    */
    function _addWLManagers(address account) internal {
        wlManCounter = wlManCounter.add(1);
        _WLManagers[account] = true;
    }

    /**
    * @dev remove a WL manager to this fund
    * @param account WL manager address to remove
    */
    function _removeWLManagers(address account) internal {
        wlManCounter = wlManCounter.sub(1);
        _WLManagers[account] = false;
    }

    /**
    * @dev check if an address is a WL manager for this fund
    * @param account WL manager address to check
    * @return _WLManagers[account] true or false
    */
    function isWLManager(address account) public override view returns (bool) {
        return _WLManagers[account];
    }

    /**
    * @dev add an admin to this fund (onlyAdmins)
    * @param account new admin address
    */
    function addWLManagers(address account) external override onlyAdmins {
        _addWLManagers(account);
    }

    /**
    * @dev remove a WL manager from this fund (onlyAdmins)
    * @param account admin address to be removed
    */
    function removeWLManagers(address account) external override onlyAdmins {
        _removeWLManagers(account);
    }

    /**
    * @dev WL manager renounce (onlyWLManagers)
    */
    function renounceWLManager() external override onlyWLManagers {
        _removeWLManagers(msg.sender);
    }

    /**
    * @dev set fund new physical address of operation (onlyAdmins)
    * @param _newPhysicalAddressOfOperation, new physical address
    */
    function setPhysicalAddressOfOperation(string memory _newPhysicalAddressOfOperation) external override onlyAdmins {
        emit PhysicalAddressOfOperationUpdated(physicalAddressOfOperation, _newPhysicalAddressOfOperation);
        physicalAddressOfOperation = _newPhysicalAddressOfOperation;
    }

    /**
    * @dev deploy a new WL fund contract, if it deosn't exist, calling the WL deployer (onlyAdmins)
    * @return wlFund new fund wl contract address
    */
    function deployFundWL() external override onlyAdmins returns (address) {
        require(wlFund == address(0), "Fund Whitelist already deployed!");
        wlFund = wlDeplContract.deployWhitelist(address(this));
        return wlFund;
    }

    /**
    * @dev get the admin counter
    * @return adminCounter admin nunber on the fund contract
    */
    function getAdminCounter() external override view returns (uint256) {
        return adminCounter;
    }

    /**
    * @dev get the WL manager counter
    * @return wlManCounter WL manager nunber on the fund contract
    */
    function getWLManagerCounter() external override view returns (uint256) {
        return wlManCounter;
    }

    /**
    * @dev get the WL fund contract address
    * @return wlFund address of wl contract address
    */
    function getFundWLAddress() external override view returns (address) {
        return wlFund;
    }

    /**
    * @dev deploy new asset contract calling the asset deployer (onlyAdmins)
    * @param _assetID, ID of the asset to be deployed
    * @param _name, name of the asset to be deployed
    * @param _type, symbol of the asset to be deployed
    * @return newAsset new asset contract address
    */
    function deployNewAsset(string memory _assetID,
            string memory _name,
            string memory _type) external override nonReentrant onlyAdmins returns (address) {
        require(wlFund != address(0), "Please define a fund whitelist before deploy any asset");
        address newAsset = assetDeplContract.deployAsset(address(this), wlFund, _assetID, _name, _type);
        assets[assetCounter] = Asset({assetAddress: newAsset, isParticularWL: false, wlAddress: wlFund});
        assetCounter = assetCounter.add(1);
        fundAssets[newAsset] = true;
        emit NewAssetDeployed(newAsset, _assetID, _name);
        return newAsset;
    }

    /**
    * @dev get deployed asset contract address as an item of an array
    * @param index, index inside the "array"
    * @return assetAddress index-th asset contract address
    * @return isParticularWL if the asset has its own WL contract
    * @return wlAddress the WL contract address
    */
    function getDeployedAssets(uint256 index) public override view returns (address, bool, address) {
        return (assets[index].assetAddress, assets[index].isParticularWL, assets[index].wlAddress);
    }

    /**
    * @dev get deployed asset contract counter
    * @return assetCounter number of deployed asset contract
    */
    function getTotalDeployedAssets() public override view returns (uint256) {
        return assetCounter;
    }

    /**
    * @dev get if address is a deployed asset contract by the fund
    * @param _assetAddr asset address to be checked
    * @return fundAssets[_assetAddr] true or false
    */
    function isAssetDeployed(address _assetAddr) external view returns (bool) {
        return fundAssets[_assetAddr];
    }

    /**
     * @dev set a new document to store in the list, queueing it if others exist and incremetning documents counter (onlyAdmins)
     * @param uri link to document URL
     * @param documentHash document hash
     */
    function addNewDocument(string memory uri, bytes32 documentHash) external override onlyAdmins{
        require(!_registeredHashes[documentHash], "Hash already registered");
        _registeredHashes[documentHash] = true;
        _documents[docsCounter] = Doc({docURI: uri, docHash: documentHash, lastModified: block.timestamp});
        docsCounter = docsCounter.add(1); //ptrepare for next doc to add
        emit DocHashAdded(docsCounter, uri, documentHash);
    }

    /**
     * @dev get the _num document in stored doc array
     * @param _num index of document
     * @return docURI link to the document url
     * @return docHash document hash
     * @return lastModified date & time when document was notarized
     */
    function getDocInfos(uint256 _num) external override view returns (string memory, bytes32, uint256) {
        return (_documents[_num].docURI, _documents[_num].docHash, _documents[_num].lastModified);
    }

    /**
     * @dev get the hash list length
     * @return docsCounter number of documents notarized
     */
    function getDocsCount() external override view returns (uint256) {
        return docsCounter;
    }

    /**
     * @dev transfer asset ownership to another deployed fund (onlyAdmins)
     * @param _idx asset number to be transferred to a new fund contract
     * @param _newFundAssetOwner fund address that becomes new asset owner
     * @param _newFundAdmin new fund admin
     */
    function changeAssetOwnership(uint256 _idx, address _newFundAssetOwner, address _newFundAdmin) external nonReentrant onlyAdmins {
        address assetToTransfer;
        (assetToTransfer, , ) = getDeployedAssets(_idx);
        require(fundDeplContract.isFundDeployed(_newFundAssetOwner), "Fund not available!");
        require(assetDeplContract.isAssetDeployed(assetToTransfer), "Asset not available!");
        require(IRHAsset(assetToTransfer).getOwner() == address(this), "Fund is not the Asset owner!");
        require(IRHAsset(assetToTransfer).getTACounter() == 0, "Please remove Asset Transfer Agents!");
        require(_newFundAdmin != address(0), "Address not allowed");
        assetCounter = assetCounter.sub(1);
        _addAdmin(_newFundAdmin);
        renounceAdmin();
        fundAssets[assetToTransfer] = false;
        assets[_idx] = Asset({assetAddress: address(0), isParticularWL: false, wlAddress: address(0)});
        IRHAsset(assetToTransfer).setNewOwnership(_newFundAssetOwner);
        emit AssetOwnerChanged(assetToTransfer, _newFundAssetOwner, block.number);
    }

    /**
     * @dev import transferred asset into fund assets (onlyAdmins)
     * @param _newAssetAddress asset address to be imported in this fund once ownership is transferred to this fund
     */
    function importTransferredAsset(address _newAssetAddress) external onlyAdmins {
        require(IRHAsset(_newAssetAddress).getOwner() == address(this), "Not asset owner!");
        require(!fundAssets[_newAssetAddress], "Asset already added to fund!");
        assets[assetCounter] = Asset({assetAddress: _newAssetAddress, isParticularWL: false, wlAddress: wlFund});
        fundAssets[_newAssetAddress] = true;
        assetCounter = assetCounter.add(1);
        emit AssetImported(_newAssetAddress, assetCounter, block.number);
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

interface IRHAsset {
    function getAllTokens() external view returns (address[] memory);
    function createNewToken(string memory _name,
            string memory _ticker,
            string memory _tokenType,
            uint256 _tokenRoi,
            uint8 _decimals,
            uint256 _hardCap,
            string memory _couponType) external returns (address);
    function isTransferAgent(address account) external view returns (bool);
    function addTransferAgent(address account) external;
    function removeTransferAgent(address account) external;
    function renounceTransferAgent() external;
    function getTACounter() external view returns (uint256);
    function setNewWLContract() external returns (address);
    function restoreFundWL() external returns (address);
    function getIssuanceNumber() external view returns (uint256);
    function getWLAssetAddress() external view returns (address);
    function addNewDocument(string calldata uri, bytes32 documentHash) external;
    function getDocInfos(uint256 _num) external view returns (string memory, bytes32, uint256);
    function getDocsCount() external view returns (uint256);
    function writeSummary (string calldata _tmpSummary) external returns (bool);
    function getSummary () external view returns (string memory);
    function getOwner() external view returns (address);
    function setNewOwnership(address _newOwner) external;
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