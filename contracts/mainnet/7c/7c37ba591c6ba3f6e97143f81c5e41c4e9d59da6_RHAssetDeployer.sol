// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./RHAsset.sol";
import "./interfaces/IRHWLDeployer.sol";
import "./interfaces/IRHFundDeployer.sol";
import "./interfaces/IRHTokenDeployer.sol";
import "./interfaces/IRHAssetDeployer.sol";

contract RHAssetDeployer is Ownable, IRHAssetDeployer {
    using SafeMath for uint256;

    address private deplFacAddress;
    uint256 private assetCounter;

    mapping(uint256 => address) internal _assets;
    mapping(address => bool) internal _assetDeployed;
    mapping(address => bool) internal _allowedFundContracts;

    IRHFundDeployer private fundDeplContract;
    IRHWLDeployer private wlDeplContract;
    IRHTokenDeployer private tokenDeplContract;

    /**
     * @dev asset created
     * @param newAsset new asset address
     * @param name new asset name
     * @param symbol new asset symbol
     */
    event AssetCreated(
        address indexed newAsset,
        string name,
        string symbol
    );

    // event NewDeployerFacility(address newDeplFaciltiy);

    /**
     * @dev asset deployer contract constructor
     */
    constructor() { }

    /** @notice check if msg.sender is an allowed fund contract */
    modifier onlyFundContracts() {
        require(_allowedFundContracts[msg.sender], "Address not allowed to create Asset!");
        _;
    }

    /** @notice check if msg.sender is the deployer facility contract */
    modifier onlyDeplFacility() {
        require(msg.sender == deplFacAddress, "Caller is not a Deployer Facility!!");
        _;
    }

    /**
    * @dev set deployer facility contract address (onlyOwner)
     * @param _deplFacAddr address of deployer facility contract to add
    */
    function setDeployerFacility(address _deplFacAddr) external override onlyOwner {
        require(_deplFacAddr != address(0), "address not allowed!");
        deplFacAddress = _deplFacAddr;
        // emit NewDeployerFacility(deplFacAddress);
    }

    /**
    * @dev set fund deployer contract address (onlyDeplFacility)
    * @param _fundAddr address of fund deployer contract to add
    */
    function setFundDeployerContract(address _fundAddr) external override onlyDeplFacility {
        require(_fundAddr != address(0), "address not allowed!");
        fundDeplContract = IRHFundDeployer(_fundAddr);
    }

    /**
    * @dev get fund deployer contract address
    * @return fundDeplContract address of fund deployer contract
    */
    function getFundDeployerContract() external override view returns(address) {
        return address(fundDeplContract);
    }

    /**
    * @dev set WL deployer contract address (onlyDeplFacility)
    * @param _wlAddr address of WL deployer contract to add
    */
    function setWLDeployerContract(address _wlAddr) external override onlyDeplFacility {
        require(_wlAddr != address(0), "address not allowed!");
        wlDeplContract = IRHWLDeployer(_wlAddr);
    }

    /**
    * @dev get WL deployer contract address
    * @return wlDeplContract WL deployer contract address
    */
    function getWLDeployerContract() external override view returns(address) {
        return address(wlDeplContract);
    }

    /**
    * @dev set token deployer contract address (onlyDeplFacility)
    * @param _tokenAddr address of token deployer contract to add
    */
    function setTokenDeployerContract(address _tokenAddr) external override onlyDeplFacility {
        require(_tokenAddr != address(0), "Address not allowed");
        tokenDeplContract = IRHTokenDeployer(_tokenAddr);
    }

    /**
    * @dev get token deployer contract address
    * @return tokenDeplContract token deployer contract address
    */
    function getTokenDeployerContract() external override view returns(address) {
        return address(tokenDeplContract);
    }


    /**
    * @dev add allowed fund contract addresses (onlyDeplFacility)
    * @param _newFundContract address of allowed fund contract
    */
    function addAllowedFundContract(address _newFundContract) external override onlyDeplFacility {
        require(_newFundContract != address(0), "Address not allowed");
        _allowedFundContracts[_newFundContract] = true;
    }

     /**
    * @dev check if an fund contract address is allowed on this deployer
    * @param _addr address to check
    * @return _allowedFundContracts[_addr] true if fund address was allowed
    */
    function getAllowedFund(address _addr) external override view returns (bool) {
        return _allowedFundContracts[_addr];
    }

    /**
    * @dev get deployed asset contract counter
    * @return assetCounter number of deployed asset contracts
    */
    function getDeployedAssetCounter() external override view returns (uint256) {
        return assetCounter;
    }

    /**
    * @dev get deployed asset contract address as an item of an array
    * @param idx index inside the "array"
    * @return _assets[idx] idx-th asset contract address
    */
    function getDeployedAssetAddress(uint256 idx) external override view returns(address) {
        return _assets[idx];
    }

    /**
    * @dev check if a asset contract address was deployed by this deployer
    * @param _assetAddress address to check
    * @return _assetDeployed[_assetAddress] true if asset address was deployed
    */
    function isAssetDeployed(address _assetAddress) external override view returns (bool) {
        return _assetDeployed[_assetAddress];
    }

    /**
    * @dev add deployed asset contract address to internal variables
    * @param newAssetToAdd asset contract address to add
    */
    function addAssetContractAddress(address newAssetToAdd) internal {
        _assets[assetCounter] = newAssetToAdd;
        assetCounter = assetCounter.add(1);
        _assetDeployed[newAssetToAdd] = true;
    }

    /**
    * @dev add deployed asset contract address to WL and token deployers
    * @param _fundAddr fund contract address to check
    * @param _assetAddr asset contract address to add to deployers
    */
    function setAssetInDeployers(address _fundAddr, address _assetAddr) internal {
        require(fundDeplContract.isFundDeployed(_fundAddr), "Fund Contract not from deployer");
        tokenDeplContract.addAssetAllowedContract(_assetAddr);
        wlDeplContract.addAllowedContractByAsset(_assetAddr);
    }

     /**
    * @dev deploy a new asset contract, add its address to internal variables and change the ownership to fund contract address (onlyFundContracts)
    * @param refContract address of the caller contract (fund contract address)
    * @param _fundWLAddr address of the fund whitelist address
    * @param _assetID ID of asset to be deployed
    * @param _name name of the asset to be deployed
    * @param _type symbol of the asset to be deployed
    * @return newAsset address of the deployed asset contract
    */
    function deployAsset(address refContract,
            address _fundWLAddr,
            string memory _assetID,
            string memory _name,
            string memory _type) external override onlyFundContracts returns (address) {
        require(address(tokenDeplContract) != address(0), "Please insert Token Deployer contract address");
        RHAsset newAsset = new RHAsset(address(wlDeplContract), address(tokenDeplContract),
                                refContract, _fundWLAddr, _assetID, _name, _type);
        addAssetContractAddress(address(newAsset));
        setAssetInDeployers(refContract, address(newAsset));
        newAsset.transferOwnership(msg.sender);
        emit AssetCreated(address(newAsset), _name, _type);
        return address(newAsset);
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
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IRHTokenDeployer.sol";
import "./interfaces/IRHFund.sol";
import "./interfaces/IRHWhitelist.sol";
import "./interfaces/IRHWLDeployer.sol";
import "./interfaces/IRHAsset.sol";

contract RHAsset is Ownable, ReentrancyGuard, IRHAsset {
    using SafeMath for uint256;

    struct Doc {
        string docURI;          // URI of the document that exist off-chain
        bytes32 docHash;        // Hash of the document
        uint256 lastModified;   // Timestamp at which document details was last modified
    }

    string public name;
    string public assetType;
    string public assetID;
    address public assetWLAddress;
    address[] private tokens; // all asset tokens
    uint256 private _issuanceNumber;
    uint256 private docsCounter;
    string private _summary;
    uint256 private taCounter;

    IRHFund private fundContract;
    IRHWLDeployer private wlDeplContract;
    IRHTokenDeployer private tokenDeplContract;

    mapping(address => bool) private _transferAgents;
    mapping(uint256 => Doc) internal _documents;
    mapping(bytes32 => bool) internal _registeredHashes;

    /**
     * @dev new doc with hash added
     * @param num counter for document
     * @param docuri link to external document
     * @param dochash document hash
     */
    event DocHashAdded(uint256 indexed num,
        string docuri,
        bytes32 dochash);

    /**
     * @dev new token deployed
     * @param newToken cnew token address
     * @param issuanceNumber deployed token counter
     */
    event TokenDeployed(
        address indexed newToken,
        uint256 issuanceNumber
    );

    /**
    * @dev asset contract contructor
    * @param _wlDeplAddr WL deployer contract address
    * @param _tokenDeplAddr token deployer contract address
    * @param _fund fund contract address
    * @param _wlAddr fund WL contract address
    * @param _assetID asset ID
    * @param _assetName asset name
    * @param _type asset type
    */
    constructor (address _wlDeplAddr,
            address _tokenDeplAddr,
            address _fund,
            address _wlAddr,
            string memory _assetID,
            string memory _assetName,
            string memory _type) {
        require(_wlAddr != address(0), "WL address not allowed");
        fundContract = IRHFund(_fund);
        tokenDeplContract = IRHTokenDeployer(_tokenDeplAddr);
        wlDeplContract = IRHWLDeployer(_wlDeplAddr);
        assetWLAddress = _wlAddr;
        assetID = _assetID;
        name = _assetName;
        assetType = _type;
        taCounter = 0;
        _issuanceNumber = 0;
        docsCounter = 0;
    }

    /** @notice check if msg.sender is a transfer agent */
    modifier onlyTransferAgents() {
        require(isTransferAgent(msg.sender), "Not a Transfer Agent!");
        _;
    }

    /** @notice check if msg.sender is an administrator */
    modifier onlyAdmins() {
        require(fundContract.isAdmin(msg.sender), "Not an Administrator!");
        _;
    }

    /*   Transfer Agents Roles Mngmt  */
    /**
    * @dev add a transfer agent to this asset
    * @param account new transfer agent address
    */
    function _addTransferAgent(address account) internal {
        taCounter = taCounter.add(1);
        _transferAgents[account] = true;
    }

    /**
    * @dev remove a transfer agent from this asset
    * @param account transfer agent address to remove
    */
    function _removeTransferAgent(address account) internal {
        taCounter = taCounter.sub(1);
        _transferAgents[account] = false;
    }

    /**
    * @dev check if an address is a transfer agent for this asset
    * @param account transfer agent address to check
    */
    function isTransferAgent(address account) public override view returns (bool) {
        return _transferAgents[account];
    }

    /**
    * @dev add a transfer agent to this asset (onlyAdmins)
    * @param account new transfer agent address
    */
    function addTransferAgent(address account) external override onlyAdmins {
        require(account != address(0), "Not valid Transfer Agent address!");
        require(!isTransferAgent(account), "Address is already a Transfer Agent");
        _addTransferAgent(account);
    }

    /**
    * @dev remove a transfer agent from this asset (onlyAdmins)
    * @param account transfer agent address to be removed
    */
    function removeTransferAgent(address account) external override onlyAdmins {
        _removeTransferAgent(account);
    }

    /**
    * @dev transfer agent renounce (onlyTransferAgents)
    */
    function renounceTransferAgent() external override onlyTransferAgents {
        _removeTransferAgent(msg.sender);
    }

    /**
    * @dev counts how many transfer agents for this asset
    * @return TACounter transfer agent counter
    */
    function getTACounter() external override view returns (uint256){
        return taCounter;
    }

    /**
    * @dev set asset new WL contract only if no token is already deployed (onlyAdmins)
    * @return assetWLAddress new asset WL contract address
    */
    function setNewWLContract() external override nonReentrant onlyAdmins returns (address) {
        require(_issuanceNumber == 0, "Impossible to deploy dedicated WL, tokens are already deployed for this asset");
        assetWLAddress = wlDeplContract.deployWhitelist(address(this));
        return assetWLAddress;
    }

    /**
    * @dev restore asset WL contract to fund WL, disregarding tokens already deployed, and this WL can be used for deploying other tokens.
    * All tokens will be redirected to the fund WL, and previous dedicated WL will be unused in the future for no token deployed by this asset. (onlyAdmins)
    * @return assetWLAddress asset WL contract address
    */
    function restoreFundWL() external override nonReentrant onlyAdmins returns (address) {
        assetWLAddress = fundContract.getFundWLAddress();
        return assetWLAddress;
    }

    /**
    * @dev get number of token issuance
    * @return _issuanceNumber total issuance number
    */
    function getIssuanceNumber() external override view returns (uint256) {
        return _issuanceNumber;
    }

    /**
    * @dev get asset tokens contract addresses already deployed
    * @return tokens deployed token contracts addresses array
    */
    function getAllTokens() external override view returns (address[] memory) {
        return tokens;
    }

    /**
    * @dev get the WL contract for this asset contract
    * @return assetWLAddress asset WL contract address
    */
    function getWLAssetAddress() external override view returns (address) {
        return assetWLAddress;
    }

    /**
    * @dev deploy new token contract calling the token deployer, adding it to deployed token array and increasing issuance number
    * @dev assetWLAddress can be restored to fund WL if a dedicated WL was previously deployed (only once) (onlyAdmins)
    * @param _name token name
    * @param _ticker token ticker
    * @param _decimals decimals of the token to be deployed
    * @param _hardCap hard cap of the token to be deployed
    * @return newToken new token contract address
    */
    function createNewToken(string memory _name,
            string memory _ticker,
            string memory _tokenType,
            uint256 _tokenRoi,
            uint8 _decimals,
            uint256 _hardCap,
            string memory _couponType) external override nonReentrant onlyAdmins returns (address) {
        _issuanceNumber = _issuanceNumber.add(1);
        address newToken = tokenDeplContract.deployToken(address(fundContract), address(this), assetWLAddress,
                            _name, _ticker, _tokenType, _couponType, _decimals, _tokenRoi, _hardCap, _issuanceNumber);
        tokens.push(newToken);
        emit TokenDeployed(newToken, _issuanceNumber.sub(1));
        // _issuanceNumber = _issuanceNumber.add(1);
        return address(newToken);
    }

    /**
     * @dev set a new document structure to store in the list, queueing it if others exist and incremetning documents counter (onlyAdmins)
     * @param uri document URL
     * @param documentHash Hash to add to list
     */
    function addNewDocument(string memory uri, bytes32 documentHash) external override onlyAdmins{
        require(!_registeredHashes[documentHash], "Hash already registered");
        _registeredHashes[documentHash] = true;
        _documents[docsCounter] = Doc({docURI: uri, docHash: documentHash, lastModified: block.timestamp});
        docsCounter = docsCounter.add(1); //ptrepare for next doc to add
        emit DocHashAdded(docsCounter, uri, documentHash);
    }

    /**
     * @dev get a hash in the _num place
     * @param _num uint256 Place of the hash to return
     * @return docURI URI name string
     * @return docHash bytes32 hash of the notarized document
     * @return lastModified datetime
     */
    function getDocInfos(uint256 _num) external override view returns (string memory, bytes32, uint256) {
        return (_documents[_num].docURI, _documents[_num].docHash, _documents[_num].lastModified);
    }

    /**
     * @dev get the hash list length
     * @return docsCounter doc counter value
     */
    function getDocsCount() external override view returns (uint256) {
        return docsCounter;
    }

    /**
     * @dev write operation summary on blockchain (onlyAdmins)
     * @param _tmpSummary bytes with info
     * @return success true or false
     */
    function writeSummary (string calldata _tmpSummary) external override onlyAdmins returns (bool) {
        _summary = _tmpSummary;
        return true;
    }

    /**
     * @dev get summary info
     * @return _summary summary string
     */
    function getSummary () external override view returns (string memory) {
        return _summary;
    }

    /**
     * @dev get owner address
     * @return owner address of the owner
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev set new owner - callable only by the fund contract (onlyOwner)
     * @param _newOwner new owner address
     */
    function setNewOwnership(address _newOwner) external override onlyOwner {
        fundContract = IRHFund(_newOwner);
        assetWLAddress = fundContract.getFundWLAddress();
        transferOwnership(_newOwner);
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