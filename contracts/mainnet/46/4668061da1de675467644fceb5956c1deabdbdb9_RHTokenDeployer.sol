// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./RHToken.sol";
import "./interfaces/IRHFundDeployer.sol";
import "./interfaces/IRHAssetDeployer.sol";
import "./interfaces/IRHWLDeployer.sol";
import "./interfaces/IRHTokenDeployer.sol";

contract RHTokenDeployer is Ownable, IRHTokenDeployer {
    using SafeMath for uint256;

    address private deplFacAddress;
    uint256 private tokenCounter;

    IRHAssetDeployer private assetDeplContract;

    mapping(uint256 => address) internal _tokens;
    mapping(address => bool) internal _tokenDeployed;
    mapping(address => bool) private _allowedAssetContracts;

    /**
     * @dev new token deployed event
     * @param newToken new token address
     * @param tokenName new token name
     */
    event TokenCreated(
        address indexed newToken,
        string tokenName);

    // event NewDeployerFacility(address newDeplFaciltiy);

    /**
     * @dev fund deployer contract contructor
     */
    constructor() { }

    /** @notice check if msg.sender is anallowed asset */
    modifier onlyAssetContract() {
        require(_allowedAssetContracts[msg.sender], "Asset not allowed to create Token!");
        _;
    }

    /** @notice check if msg.sender is a deployer facility */
    modifier onlyDeplFacility() {
        require(msg.sender == deplFacAddress, "Caller is not a Deployer Facility!");
        _;
    }

    /**
    * @dev set deployer facility contract address (onlyOwner)
    * @param _deplFacAddr deployer facility contract address to add
    */
    function setDeployerFacility(address _deplFacAddr) external override onlyOwner {
        require(_deplFacAddr != address(0), "address not allowed!");
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
    * @dev add deployed asset contract address to allowed address array, checking if it was deployed by asset deployer
    * @param _asset asset contract address to add
    */
    function addAssetAllowedContract(address _asset) external override {
        require(_asset != address(0), "Address not allowed");
        require(assetDeplContract.isAssetDeployed(_asset), "Caller is not a asset");
        require(!_allowedAssetContracts[_asset], "Asset address already added");
        _allowedAssetContracts[_asset] = true;
    }

    /**
    * @dev check if a asset contract address is allowed on this deployer
    * @param _addr address to check
    * @return _allowedAssetContracts[_addr] true if asset address was allowed, otherwise false
    */
    function getAllowedAsset(address _addr) external override view returns (bool) {
        return _allowedAssetContracts[_addr];
    }

    /**
    * @dev get deployed token contract counter
    * @return tokenCounter number of deployed token contracts
    */
    function getDeployedTokensCounter() external override view returns (uint256) {
        return tokenCounter;
    }

    /**
    * @dev check if a token contract address was deployed by this deployer
    * @param _tokenAddr address to check
    * @return _tokenDeployed[_tokenAddr] true if token address was deployed, otherwise false
    */
    function isTokenDeployed(address _tokenAddr) external override view returns (bool) {
        return _tokenDeployed[_tokenAddr];
    }

    /**
    * @dev get deployed token contract address as an item of an array
    * @return _tokens[idx] idx-th token contract address
    */
    function getDeployedTokenAddress(uint256 idx) external override view returns(address) {
        return _tokens[idx];
    }

    /**
    * @dev add deployed token contract address to internal variables
    * @param newTokenToAdd asset contract address to add
    */
    function addTokenContractAddress(address newTokenToAdd) internal {
        _tokens[tokenCounter] = newTokenToAdd;
        tokenCounter = tokenCounter.add(1);
        _tokenDeployed[newTokenToAdd] = true;
    }

    /**
    * @dev deploy a new token contract, add its address to internal variables and change the ownership to asset contract address (onlyAssetContract)
    * @param _fund fund contract address
    * @param _asset asset contract address
    * @param _wlAddress WL contract address
    * @param name token name to be deployed
    * @param ticker token ticker to be deployed
    * @param tokenType token primary typology
    * @param couponType token coupon type
    * @param decimals token decimals
    * @param tokenRoi token ROI
    * @param _issuanceNumber  specify token issuance number (starting from 0)
    * @return newToken deployed token contract address
    */
    function deployToken(address _fund,
            address _asset,
            address _wlAddress,
            string memory name,
            string memory ticker,
            string memory tokenType,
            string memory couponType,
            uint8 decimals,
            uint256 tokenRoi,
            uint256 hardCap,
            uint256 _issuanceNumber) external override onlyAssetContract returns (address) {
        RHToken newToken = new RHToken(_fund, _asset, _wlAddress,
                            name, ticker, tokenType, couponType, decimals, tokenRoi, hardCap, _issuanceNumber);
        addTokenContractAddress(address(newToken));
        newToken.transferOwnership(_asset);
        emit TokenCreated(address(newToken), name);
        return address(newToken);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface ITank {
    function setTankWLAddress(address _tankWLAddr) external;
    function getTokenTimeLock(address _token) external view returns(uint256);
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

interface IRHToken {
    function setTokenType(string calldata _newType) external returns (string memory);
    function setTokenCouponType(string calldata _newCouponType) external returns (string memory);
    function paused() external view returns (bool);
    function pause() external;
    function unpause() external;
    function getTokenRoi() external view returns (uint256);
    function setTokenRoi(uint256 _newRoi) external;
    function getCap() external view returns (uint256);
    function setCap(uint256 _newCap) external returns (uint256);
    function writeSummary (string calldata _tmpSummary) external returns (bool);
    function getSummary () external view returns (string memory);
    function setNewTank(address _newTank) external;
    function resetTank(address _tank) external;
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
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
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRHFund.sol";
import "./interfaces/IRHAsset.sol";
import "./interfaces/IRHWhitelist.sol";
import "./interfaces/IRHToken.sol";
import "./interfaces/ITank.sol";

contract RHToken is ERC20, Ownable, IRHToken {
    using SafeMath for uint256;

    string public tokenType;
    string public couponType;
    uint256 public issuanceNumber;
    // uint8 public decimals;
    bool private _paused;
    bool private _mintAllowed;
    bool private _tokenExpired;
    uint256 private _yearlyReturn;
    uint256 private _cap;
    string private _summary;
    uint8 private _decimals;

    IRHFund private fundContract;
    IRHAsset private assetContract;
    IRHWhitelist private wlContract;

    mapping (address => bool) public tankLocked;  // for future purpose

    /**
     * @dev token paused event
     * @param account pauser account
     */
    event Paused(address account);

    /**
     * @dev token unpaused event
     * @param account unpauser account
     */
    event Unpaused(address account);

    /**
     * @dev token mint allowance event
     * @param status true if mint operations allowed, false otherwise
     * @param newStatusBlock block number
     */    
    event MintAllowance(bool status, uint256 newStatusBlock);

    /**
     * @dev token expired event
     * @param expirationBlock block number
     */
    event TokenExpired(uint256 expirationBlock);

    /**
    * @dev token contract contructor
    * @param _fund fund address originating this token
    * @param _asset asset address originating this token
    * @param _wlAddress whitelist address connected to this token
    * @param _tName token name
    * @param _tSymbol token symbol
    * @param _tokenType token type
    * @param _couponType coupon token type
    * @param _decs token decimals
    * @param tokenRoi token ROI
    * @param hardCap token cap on total supply (max emission amount)
    * @param _issuanceNumber issuance number of this token emitted by associated asset
    */
    constructor (address _fund,
            address _asset,
            address _wlAddress,
            string memory _tName,
            string memory _tSymbol,
            string memory _tokenType,
            string memory _couponType,
            uint8 _decs,
            uint256 tokenRoi,
            uint256 hardCap,
            uint256 _issuanceNumber) ERC20(_tName, _tSymbol) {
        require(hardCap > 0, "Token cap is 0");
        _decimals = _decs;
        fundContract = IRHFund(_fund);
        assetContract = IRHAsset(_asset);
        wlContract = IRHWhitelist(_wlAddress);
        tokenType = _tokenType;
        couponType = _couponType;
        issuanceNumber = _issuanceNumber;
        _yearlyReturn = tokenRoi;
        _cap = hardCap;
        _paused = false;
        _mintAllowed = false;
        _tokenExpired = false;
    }

    /// The fallback function. Ether transfered into the contract is not accepted.
    receive() external payable {
        revert();
    }

    /** @notice check if msg.sender is a fund administrator */
    modifier onlyAdmins() {
        require(fundContract.isAdmin(msg.sender), "Not an Admin!");
        _;
    }

   /** @notice check if msg.sender is an asset transfer agent */
    modifier onlyTransferAgents() {
        require(assetContract.isTransferAgent(msg.sender), "Not a Transfer Agent!");
        _;
    }

    /** @notice check if mint operations are allowed */
    modifier mintAllowance() {
        require(_mintAllowed, "Mint disallowed!");
        _;
    }

   /** @notice check if token is not expired */
    modifier tokenNotExpired() {
        require(!_tokenExpired, "Token Expired!");
        _;
    }

    /** @notice check if token is not paused */
    modifier whenNotPaused() {
        require(!_paused, "Token Contract paused...");
        _;
    }

    /**
     * @dev get token decimals
     * @return _decimals token decimals number
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev get if token can be minted
     * @return _mintAllowed true or false
     */
    function getMintAllowance() external view returns (bool) {
        return _mintAllowed;
    }

    /**
     * @dev set token minting allowance (onlyAdmins)
     * @param _newVal true or false
     */
    function setMintAllowance(bool _newVal) external onlyAdmins {
        _mintAllowed = _newVal;
        emit MintAllowance(_mintAllowed, block.number);
    }

    /**
     * @dev get if token is expired
     * @return _tokenExpired true or false
     */
    function getTokenExpired() external view returns (bool) {
        return _tokenExpired;
    }

    /**
     * @dev set token expired (onlyAdmins)
     * @param _newVal true or false
     */
    function setTokenExpired(bool _newVal) external onlyAdmins {
        require(!_tokenExpired, "Token Expired!");
        _tokenExpired = _newVal;
        emit TokenExpired(block.number);
    }

    /**
     * @dev set a new type for this token if not expired (onlyAdmins)
     * @param _newType the new token type
     * @return tokenType the type of the token.
     */
    function setTokenType(string calldata _newType) external override onlyAdmins tokenNotExpired returns (string memory) {
        require(keccak256(abi.encodePacked(tokenType)) != keccak256(abi.encodePacked(_newType)),
                "The token type is not different from the old one!");
        tokenType = _newType;
        return tokenType;
    }

    /**
     * @dev set a new coupon type for this token if not expired (onlyAdmins)
     * @param _newCouponType the new token coupon type
     * @return couponType token coupon type
     */
    function setTokenCouponType(string calldata _newCouponType) external override onlyAdmins tokenNotExpired returns (string memory) {
        require(keccak256(abi.encodePacked(couponType)) != keccak256(abi.encodePacked(_newCouponType)),
                "The token coupon type is not different from the old one!");
        couponType = _newCouponType;
        return couponType;
    }

    /**
     * @dev get token in pause (onlyTransferAgents)
     * @return _paused true if the contract is paused, false otherwise.
     */
    function paused() external override tokenNotExpired view returns (bool) {
        return _paused;
    }

    /**
     * @dev set token in pause (onlyTransferAgents)
     */
    function pause() external override onlyTransferAgents whenNotPaused tokenNotExpired {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev remove token paused (onlyTransferAgents)
     */
    function unpause() external override onlyTransferAgents tokenNotExpired {
        require(_paused, "Token Contract not paused");
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev get the cap on the token's total supply.
     * @return tokenCap cap value
     */
    function getCap() external override view returns (uint256) {
        return _cap;
    }

    /**
     * @dev set a new cap on the token's total supply (onlyAdmins)
     * @param _newCap new cap value on the token's total supply.
     * @return tokenCap new cap value
     */
    function setCap(uint256 _newCap) external override onlyAdmins tokenNotExpired returns (uint256) {
        require(_newCap != _cap, "New cap is equal to the old one!");
        require(_newCap >= totalSupply(), "New cap is less than total supply!");
        _cap = _newCap;
        return _cap;
    }

    /**
     * @dev get the token ROI if not expired
     * @return _yearlyReturn token ROI
     */
    function getTokenRoi() external override tokenNotExpired view returns (uint256) {
        return _yearlyReturn;
    }

    /**
     * @dev set the token ROI inf not expired (onlyAdmins)
     * @param _newRoi new ROI to be set
     */
    function setTokenRoi(uint256 _newRoi) external override onlyAdmins tokenNotExpired {
        require(_newRoi != _yearlyReturn, "New ROI is the same as the old one");
        _yearlyReturn = _newRoi;
    }

    /**
     * @dev set a new tank where this token can be locked (onlyTransferAgents)
     * @param _newTank new tank address
     */
    function setNewTank(address _newTank) external override onlyTransferAgents {
        require(_newTank != address(0), "Tank address not allowed");
        // tankAddresses[tankCounter] = _newTank;
        tankLocked[_newTank] = true; 
        // tankCounter = tankCounter.add(1);
    }

    /**
     * @dev remove lock from a tank where this token was locked only if release date elapsed (onlyTransferAgents)
     * @param _tank tank address where tokens were locked
     */
    function resetTank(address _tank) external override onlyTransferAgents {
        require(tankLocked[_tank], "Tank address not active");
        uint256 tankRelTime = ITank(_tank).getTokenTimeLock(address(this));
        require(block.timestamp >= tankRelTime, "Token still locked in tank");
        tankLocked[_tank] = false; 
    }

    /**
     * @dev modifier to transfer function to only allow transfer for transfer agent(s)
     * @param sender from address
     * @param recipient to address
     * @param amount token amount
     * @return true or false
     */
    function transferFromTAEnabled(address sender, address recipient, uint256 amount) internal returns (bool) {
        _transfer(sender, recipient, amount);
        return true;
    }

    /**
     * @dev modified transfer function (onlyTransferAgents)
     * @param _to recipient address
     * @param _value tokens to transfer
     * @return success true or false
     */
    function transfer(address _to, uint256 _value) public override whenNotPaused onlyTransferAgents tokenNotExpired returns (bool) {
        require(_to != address(0), "Receiver can not be 0!");
        require(wlContract.isWhitelisted(_to), "Receiver not whitelisted!");
        return transferFromTAEnabled(msg.sender, _to,_value);
    }

    /**
     * @dev modified transferFrom function (onlyTransferAgents)
     * @param _from sender address
     * @param _to recipient address
     * @param _value token amount to transfer
     * @return success true or false
     */
    function transferFrom(address _from, address _to, uint256 _value) public override(ERC20, IRHToken) whenNotPaused onlyTransferAgents tokenNotExpired returns (bool) {
        require(_from != address(0), "Sender can not be 0!");
        require(_to != address(0), "Receiver can not be 0!");
        require(wlContract.isWhitelisted(_from), "Sender not whitelisted!");
        require(wlContract.isWhitelisted(_to), "Receiver not whitelisted!");
        require(!tankLocked[_from], "Sender locked!");
        return transferFromTAEnabled(_from, _to,_value);
    }

    /**
     * @dev modified mint function (onlyTransferAgents), only if mint allowed
     * @param _account recipient address
     * @param _amount amount of tokens to mint and send to recipient address
     */
    function mint(address _account, uint256 _amount) external whenNotPaused onlyTransferAgents mintAllowance tokenNotExpired {
        require(_account != address(0), "Receiver can not be 0!");
        require(totalSupply().add(_amount) <= _cap, "Token hard cap exceeded");
        require(wlContract.isWhitelisted(_account), "Receiver not whitelisted!");
        _mint(_account, _amount);
    }

    /**
     * @dev modified burn function (onlyTransferAgents)
     * @param _amount token amount to burn
     */
    function burn(uint256 _amount) external onlyTransferAgents whenNotPaused tokenNotExpired {
        _burn(msg.sender, _amount);
    }

    /**
     * @dev modified burnFrom function (onlyTransferAgents)
     * @param _account address from which transfer agent is going to burn tokens
     * @param _amount token amount to burn from the account
     */
    function burnFrom(address _account, uint256 _amount) external whenNotPaused onlyTransferAgents tokenNotExpired {
        require(wlContract.isWhitelisted(_account), "Account not whitelisted!");
        require(!tankLocked[_account], "Account locked!");
        _burn(_account, _amount);
    }

    /**
     * @dev write operation summary on blockchain (onlyAdmins)
     * @param _tmpSummary bytes with info
     * @return success true or false
     */
    function writeSummary (string calldata _tmpSummary) external override onlyAdmins tokenNotExpired returns (bool) {
        _summary = _tmpSummary;
        return true;
    }

    /**
     * @dev get summary info
     * @return summary summary text
     */
    function getSummary () external override view returns (string memory) {
        return _summary;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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