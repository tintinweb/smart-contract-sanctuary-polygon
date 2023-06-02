//SPDX-License-Identifier:  GNU 3.0
pragma solidity ^0.7.6;

import "./AdminTools.sol";
import "./interfaces/IATDeployer.sol";

/**
 * @notice This smart contract manages the deployment of any Admin Tools in the platform
 */
contract ATDeployer is Ownable, IATDeployer {

    address private fAddress;
    event ATDeployed(uint deployedBlock);

    constructor() {}

    modifier onlyFactory() {
        require(msg.sender == fAddress, "Address not allowed to create AT Contract!");
        _;
    }

    /**
     * @notice Set the factory address
     * @param _fAddress The address of the factory
     * @dev This method can only be called by the owner of the platform
     */
    function setFactoryAddress(address _fAddress) external override onlyOwner {
        require(_fAddress != address(0), "Address not allowed");
        fAddress = _fAddress;
    }

    /**
     * @notice Get the factory address
     * @return factory address The address of the linked factory
     */
    function getFactoryAddress() external view override returns(address) {
        return fAddress;
    }

    /**
     * @notice Deploys a new AdminTools contract
     * @param _whitelistThrEmissionAmount The maximum number of Fund Tokens the contract can emit to a non whitelisted investor
     * @param _whitelistThrTransferAmount The maximum number of Fund Tokens a non whitelisted investor can transfer
     * @return newAT address The address of the deployed AdminTools contract
     */
    function newAdminTools(uint256 _whitelistThrEmissionAmount, uint256 _whitelistThrTransferAmount) external override onlyFactory returns(address) {
        AdminTools c = new AdminTools(_whitelistThrEmissionAmount, _whitelistThrTransferAmount);
        c.transferOwnership(msg.sender);
        emit ATDeployed (block.number);
        return address(c);
    }

}

//SPDX-License-Identifier:  GNU 3.0
pragma solidity ^0.7.6;

interface IFundingSinglePanel {
    function getFactoryDeployIndex() external view returns(uint _deployIndex);
    // function changeTokenExchangeRate(uint256 _newExchRate) external;
    // function changeTokenExchangeOnTopRate(uint256 _newExchRateOnTop) external;
    function getOwnerData() external view returns (string memory _docURL, bytes32 _docHash);
    function setOwnerData(string calldata _docURL, bytes32 _docHash) external;
    function setEconomicData(uint256 _exchRate, 
            uint256 _exchRateOnTop,
            address _paymentTokenAddress, 
            uint256 _paymentTokenMinSupply, 
            uint256 _paymentTokenMaxSupply,
            uint256 _minSeedToHold,
            bool _shouldDepositSeedGuarantee) external;
    function setCampaignDuration(uint _campaignDurationBlocks) external;
    function getCampaignPeriod() external returns (uint256 _campStartingBlock, uint256 _campEndingBlock);
    // function setCashbackAddress(address _cashback) external returns (address _newCashbackAddr);
    // function setNewPaymentTokenMaxSupply(uint256 _newMaxPTSupply) external returns (uint256 _ptMaxSupply);
    function holderSendPaymentToken(uint256 _amount, address _receiver) external;
    function burnFundTokens(uint256 _amount) external;
    function importOtherTokens(address _tokenAddress, uint256 _tokenAmount) external;
    function getSentTokens(address _investor) external returns (uint256);
    function getTotalSentTokens() external returns (uint256 _amount);
    function setFSPFinanceable() external;
    // function isFSPFinanceable() external returns (bool _isFinanceable);
    function isCampaignOver() external returns (bool _isOver);
    function isCampaignSuccessful() external returns (bool _isSuccessful);
    function claimExitPaymentTokens(uint256 _amount) external returns (uint);
    function campaignExitFlag() external view returns (bool);
}

//SPDX-License-Identifier:  GNU 3.0
pragma solidity ^0.7.6;

interface IFactory {
    function changeATFactoryAddress(address) external;
    function changeTDeployerAddress(address) external;
    function changeFPDeployerAddress(address) external;
    function deployPanelContracts(string calldata, string calldata, string calldata, bytes32, uint8, uint8, uint256, uint256) external;
    function isFactoryDeployer(address) external view returns(bool);
    function isFactoryATGenerated(address) external view returns(bool);
    function isFactoryTGenerated(address) external view returns(bool);
    function isFactoryWGenerated(address) external view returns(bool);
    function isFactoryFPGenerated(address) external view returns(bool);
    function getTotalDeployer() external view returns(uint256);
    function getTotalATContracts() external view returns(uint256);
    function getTotalTContracts() external view returns(uint256);
    function getTotalFPContracts() external view returns(uint256);
    function getContractsByIndex(uint256) external view returns (address, address, address, address);
    function getFSPAddressByIndex(uint256) external view returns (address);
    function getFactoryContext() external view returns (address, address, uint);
}

//SPDX-License-Identifier:  GNU 3.0
pragma solidity ^0.7.6;

interface IAdminTools {
    function setFFSPAddresses(address, address) external;
    function setMinterAddress(address) external returns(address);
    function getMinterAddress() external view returns(address);
    function getWalletOnTopAddress() external view returns (address);
    function setWalletOnTopAddress(address) external returns(address);

    function addWLManagers(address) external;
    function removeWLManagers(address) external;
    function isWLManager(address) external view returns (bool);
    function addWLOperators(address) external;
    function removeWLOperators(address) external;
    function renounceWLManager() external;
    function isWLOperator(address) external view returns (bool);
    function renounceWLOperators() external;

    function addFundingManagers(address) external;
    function removeFundingManagers(address) external;
    function isFundingManager(address) external view returns (bool);
    function addFundingOperators(address) external;
    function removeFundingOperators(address) external;
    function renounceFundingManager() external;
    function isFundingOperator(address) external view returns (bool);
    function renounceFundingOperators() external;

    function addFundsUnlockerManagers(address) external;
    function removeFundsUnlockerManagers(address) external;
    function isFundsUnlockerManager(address) external view returns (bool);
    function addFundsUnlockerOperators(address) external;
    function removeFundsUnlockerOperators(address) external;
    function renounceFundsUnlockerManager() external;
    function isFundsUnlockerOperator(address) external view returns (bool);
    function renounceFundsUnlockerOperators() external;

    function isWhitelisted(address) external view returns(bool);
    function getWLThresholdEmissionAmount() external view returns (uint256);
    function getWLThresholdTransferAmount() external view returns (uint256);
    function getMaxEmissionAmount(address) external view returns(uint256);
    function getMaxTransferAmount(address) external view returns(uint256);
    function getWLLength() external view returns(uint256);
    function setNewEmissionThreshold(uint256) external;
    function setNewTransferThreshold(uint256) external;
    function changeMaxWLAmount(address, uint256, uint256) external;
    function addToWhitelist(address, uint256, uint256) external;
    function addToWhitelistMassive(address[] calldata, uint256[] calldata,  uint256[] calldata) external returns (bool);
    function removeFromWhitelist(address, uint256) external;
}

//SPDX-License-Identifier:  GNU 3.0
pragma solidity ^0.7.6;

interface IATDeployer {
    function newAdminTools(uint256, uint256) external returns(address);
    function setFactoryAddress(address) external;
    function getFactoryAddress() external view returns(address);
}

//SPDX-License-Identifier:  GNU 3.0
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAdminTools.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IFundingSinglePanel.sol";

/**
 * @notice This smart contract provides the tools to manage permissions in each campaign smart contract
 * @dev Each campaign owner is also a manager in every possible section
 */
contract AdminTools is Ownable, IAdminTools {
    using SafeMath for uint256;

    struct wlVars {
        bool permitted;
        uint256 maxEmissionAmount;
        uint256 maxTransferAmount;
    }

    mapping (address => wlVars) private whitelist;

    uint8 private whitelistLength;

    uint256 private whitelistThrEmissionBalance;
    uint256 private whitelistThrTransferBalance;

    mapping (address => bool) private _WLManagers;
    mapping (address => bool) private _FundingManagers;
    mapping (address => bool) private _FundsUnlockerManagers;
    mapping (address => bool) private _WLOperators;
    mapping (address => bool) private _FundingOperators;
    mapping (address => bool) private _FundsUnlockerOperators;

    address private _minterAddress;

    address private _walletOnTopAddress;

    address public FSPAddress;
    IFundingSinglePanel public FSPContract;
    address public FAddress;
    IFactory public FContract;

    event WLManagersAdded();
    event WLManagersRemoved();
    event WLOperatorsAdded();
    event WLOperatorsRemoved();
    event FundingManagersAdded();
    event FundingManagersRemoved();
    event FundingOperatorsAdded();
    event FundingOperatorsRemoved();
    event FundsUnlockerManagersAdded();
    event FundsUnlockerManagersRemoved();
    event FundsUnlockerOperatorsAdded();
    event FundsUnlockerOperatorsRemoved();
    event MaxWLAmountChanged();
    event MinterOrigins();
    event MinterChanged();
    event WalletOnTopAddressChanged();
    event LogWLThrEmissionBalanceChanged();
    event LogWLThrTransferBalanceChanged();
    event LogWLAddressAdded();
    event LogWLMassiveAddressesAdded();
    event LogWLAddressRemoved();

    /**
     * @notice Initialise the Admin Tools
     * @param _whitelistThrEmissionAmount The amount from which a has to whitelisted in order to receive new minted tokens
     * @param _whitelistThrTransferAmount The amount from which a has to whitelisted in order to receive tokens from another account
     */
    constructor (uint256 _whitelistThrEmissionAmount, uint256 _whitelistThrTransferAmount) {
        whitelistThrEmissionBalance = _whitelistThrEmissionAmount;
        whitelistThrTransferBalance = _whitelistThrTransferAmount;
    }

    /**
     * @notice Set the Factory and the Funding Single Panel address relative to this Admin Tools
     * @param _factoryAddress The address of the Factory
     * @param _FSPAddress The address of the FSP
     * @dev This method can only be called by the owner of the campaign
     */
    function setFFSPAddresses(address _factoryAddress, address _FSPAddress) external override onlyOwner {
        FAddress = _factoryAddress;
        FContract = IFactory(FAddress);
        FSPAddress = _FSPAddress;
        FSPContract = IFundingSinglePanel(FSPAddress);
        emit MinterOrigins();
    }

    /**
     * @notice Returns the address of the minter
     * @return minter address The address of the minter
     */
    function getMinterAddress() external view override returns(address) {
        return _minterAddress;
    }

    /**
     * @notice Set the minter address.
     * @param _minter The address of the minter
     * @dev The minter is the only address that is able to mint and burn Fund Tokens 
     */
    function setMinterAddress(address _minter) external override onlyOwner returns(address) {
        require(_minter != address(0), "/invalid-address");
        require(_minter != _minterAddress, "/minter-not-changed");
        require(FAddress != address(0), "/invalid-factory");
        require(FSPAddress != address(0), "/invalid-fsp");
        require(FContract.getFSPAddressByIndex(FSPContract.getFactoryDeployIndex()) == _minter,
                        "/unknown-fsp");
        _minterAddress = _minter;
        emit MinterChanged();
        return _minterAddress;
    }

    /**
     * @notice Return the address of the wallet that will receive Fund Tokens without investing
     * @return The address of the wallet on top
     * @dev The wallet on top is always the Community Vault address
     */
    function getWalletOnTopAddress() external override view returns (address) {
        return _walletOnTopAddress;
    }

    /**
     * @notice Set the address that will receive Fund Tokens without investing
     * @param _wallet The address that will receive Fund Tokens without investing
     * @return onTop address The wallet on top
     * @dev This address will always be the Communit Vault address
     */
    function setWalletOnTopAddress(address _wallet) external override onlyOwner returns(address) {
        require(_wallet != address(0), "/invalid-address");
        require(_wallet != _walletOnTopAddress, "/on-top-not-changed");
        _walletOnTopAddress = _wallet;
        emit WalletOnTopAddressChanged();
        return _walletOnTopAddress;
    }


    /* Modifiers */
    modifier onlyWLManagers() {
        require(isWLManager(msg.sender), "/not-whitelist-manager");
        _;
    }

    modifier onlyWLOperators() {
        require(isWLOperator(msg.sender), "/not-whitelist-operator");
        _;
    }

    modifier onlyFundingManagers() {
        require(isFundingManager(msg.sender), "/not-funding-manager");
        _;
    }

    modifier onlyFundingOperators() {
        require(isFundingOperator(msg.sender), "/not-funding-operator");
        _;
    }

    modifier onlyFundsUnlockerManagers() {
        require(isFundsUnlockerManager(msg.sender), "/not-fund-unlocker-manager");
        _;
    }

    modifier onlyFundsUnlockerOperators() {
        require(isFundsUnlockerOperator(msg.sender), "/not-fund-unlocker-operator");
        _;
    }


    /*   WL Managers Role Mngmt  */
    /**
     * @notice Add a new whitelist manager
     * @param account The address of the new manager
     * @dev This method can only be called by the startup owner
     */
    function addWLManagers(address account) external override onlyOwner {
        _addWLManagers(account);
        _addWLOperators(account);
    }

    /**
     * @notice Remove a whitelist manager
     * @param account The address of the manager
     * @dev This method can only be called by the startup owner
     */
    function removeWLManagers(address account) external override onlyOwner {
        _removeWLManagers(account);
        _removeWLOperators(account);
    }

    /**
     * @notice Returns if an address is a whitelist manager
     * @return isManager bool True if the address is a whitelist manager.
     */
    function isWLManager(address account) public view override returns (bool) {
        return _WLManagers[account];
    }

    /**
     * @notice Add a new whitelist operator
     * @param account The address of the new operator
     * @dev This method can only be called by a whitelist manager
     */
    function addWLOperators(address account) external override onlyWLManagers {
        _addWLOperators(account);
    }

    /**
     * @notice Remove a whitelist operator
     * @param account The address of the operator
     * @dev This method can only be called by a whitelist manager
     */
    function removeWLOperators(address account) external override onlyWLManagers {
        _removeWLOperators(account);
    }

    /**
     * @notice Let a user renounce his manager position
     * @dev This method can only be called by a whitelist manager
     */
    function renounceWLManager() external override onlyWLManagers {
        _removeWLManagers(msg.sender);
        _removeWLOperators(msg.sender);
    }

    function _addWLManagers(address account) internal {
        _WLManagers[account] = true;
        emit WLManagersAdded();
    }

    function _removeWLManagers(address account) internal {
        _WLManagers[account] = false;
        emit WLManagersRemoved();
    }

    /**
     * @notice Returns if an address is a whitelist manager
     * @return isManager bool True if the address is a whitelist manager.
     */
    function isWLOperator(address account) public view override returns (bool) {
        return _WLOperators[account];
    }

    /**
     * @notice Let a user renounce his operator position
     * @dev This method can only be called by a whitelist operator
     */
    function renounceWLOperators() external override onlyWLOperators {
        _removeWLOperators(msg.sender);
    }

    function _addWLOperators(address account) internal {
        _WLOperators[account] = true;
        emit WLOperatorsAdded();
    }

    function _removeWLOperators(address account) internal {
        _WLOperators[account] = false;
        emit WLOperatorsRemoved();
    }


    /*   Funding Manager Role Mngmt  */
    /**
     * @notice Add a new funding manager
     * @param account The address of the new manager
     * @dev This method can only be called by the startup owner
     */
    function addFundingManagers(address account) external override onlyOwner {
        _addFundingManagers(account);
        _addFundingOperators(account);
    }

    /**
     * @notice Remove a funding manager
     * @param account The address of the manager
     * @dev This method can only be called by the startup owner
     */
    function removeFundingManagers(address account) external override onlyOwner {
        _removeFundingManagers(account);
        _removeFundingOperators(account);
    }

    /**
     * @notice Returns if an address is a funding manager
     * @return isManager bool True if the address is a funding manager. 
     */
    function isFundingManager(address account) public view override returns (bool) {
        return _FundingManagers[account];
    }

    /**
     * @notice Add a new funding operator
     * @param account The address of the new operator
     * @dev This method can only be called by a funding manager
     */
    function addFundingOperators(address account) external override onlyFundingManagers {
        _addFundingOperators(account);
    }

    /**
     * @notice Remove a funding operator
     * @param account The address of the operator
     * @dev This method can only be called by a funding manager
     */
    function removeFundingOperators(address account) external override onlyFundingManagers {
        _removeFundingOperators(account);
    }

    /**
     * @notice Let a manager renounce his manager position
     * @dev This method can only be called by a funding manager
     */
    function renounceFundingManager() external override onlyFundingManagers {
        _removeFundingManagers(msg.sender);
        _removeFundingOperators(msg.sender);
    }

    function _addFundingManagers(address account) internal {
        _FundingManagers[account] = true;
        emit FundingManagersAdded();
    }

    function _removeFundingManagers(address account) internal {
        _FundingManagers[account] = false;
        emit FundingManagersRemoved();
    }

    /**
     * @notice Returns if an address is a funding operator
     * @return isManager bool True if the address is a funding operator 
     */
    function isFundingOperator(address account) public view override returns (bool) {
        return _FundingOperators[account];
    }

    /**
     * @notice Let a user renounce his operator position
     * @dev This method can only be called by a whitelist operator
     */
    function renounceFundingOperators() external override onlyFundingOperators {
        _removeFundingOperators(msg.sender);
    }

    function _addFundingOperators(address account) internal {
        _FundingOperators[account] = true;
        emit FundingOperatorsAdded();
    }

    function _removeFundingOperators(address account) internal {
        _FundingOperators[account] = false;
        emit FundingOperatorsRemoved();
    }

    /*   Funds Unlocker Manager Role Mngmt  */
    /**
     * @notice Add a new fund unlocker manager
     * @param account The address of the new manager
     * @dev This method can only be called by the startup owner
     */
    function addFundsUnlockerManagers(address account) external override onlyOwner {
        _addFundsUnlockerManagers(account);
        _addFundsUnlockerOperators(account);
    }

    /**
     * @notice Remove a fund unlocker manager
     * @param account The address of the manager
     * @dev This method can only be called by the startup owner
     */
    function removeFundsUnlockerManagers(address account) external override onlyOwner {
        _removeFundsUnlockerManagers(account);
        _removeFundsUnlockerOperators(account);
    }

    /**
     * @notice Returns if an address is a fund unlocker manager
     * @return isManager bool True if the address is a fund unlocker manager
     */
    function isFundsUnlockerManager(address account) public view override returns (bool) {
        return _FundsUnlockerManagers[account];
    }

    /**
     * @notice Add a new fund unlocker operator
     * @param account The address of the new operator
     * @dev This method can only be called by a fund unlocker manager
     */
    function addFundsUnlockerOperators(address account) external override onlyFundsUnlockerManagers {
        _addFundsUnlockerOperators(account);
    }

    /**
     * @notice Remove a fund unlocker operator
     * @param account The address of the operator
     * @dev This method can only be called by a fund unlocker manager
     */
    function removeFundsUnlockerOperators(address account) external override onlyFundsUnlockerManagers {
        _removeFundsUnlockerOperators(account);
    }

    /**
     * @notice Let a user renounce his fund unlocker manager position
     * @dev This method can only be called by a fund unlocker manager
     */
    function renounceFundsUnlockerManager() external override onlyFundsUnlockerManagers {
        _removeFundsUnlockerManagers(msg.sender);
        _removeFundsUnlockerOperators(msg.sender);
    }

    function _addFundsUnlockerManagers(address account) internal {
        _FundsUnlockerManagers[account] = true;
        emit FundsUnlockerManagersAdded();
    }

    function _removeFundsUnlockerManagers(address account) internal {
        _FundsUnlockerManagers[account] = false;
        emit FundsUnlockerManagersRemoved();
    }

    /**
     * @notice Returns if an address is a fund unlocker operator
     * @return isManager bool True if the address is a fund unlocker operator
     */
    function isFundsUnlockerOperator(address account) public override view returns (bool) {
        return _FundsUnlockerOperators[account];
    }

    /**
     * @notice Let a user renounce his fund unlocker operator position
     * @dev This method can only be called by a fund unlocker operator
     */
    function renounceFundsUnlockerOperators() external override onlyFundsUnlockerOperators {
        _removeFundsUnlockerOperators(msg.sender);
    }

    function _addFundsUnlockerOperators(address account) internal {
        _FundsUnlockerOperators[account] = true;
        emit FundsUnlockerOperatorsAdded();
    }

    function _removeFundsUnlockerOperators(address account) internal {
        _FundsUnlockerOperators[account] = false;
        emit FundsUnlockerOperatorsRemoved();
    }


    /*  Whitelisting  Mngmt  */

    /**
     * @notice Returns if an address is whitelisted
     * @return isWhitelisted bool True if subscriber is whitelisted, false otherwise
     */
    function isWhitelisted(address _subscriber) public view override returns(bool) {
        return whitelist[_subscriber].permitted;
    }

    /**
     * @notice Returns the whitelist threshold emission amount
     * @return emissionThreshold uint256 The whitelist threshold emission amount
     */
    function getWLThresholdEmissionAmount() public view override returns (uint256) {
        return whitelistThrEmissionBalance;
    }

    /**
     * @notice Returns the whitelist threshold transfer amount
     * @return transferThreshold uint256 The whitelist threshold transfer amount
     */
    function getWLThresholdTransferAmount() public view override returns (uint256) {
        return whitelistThrTransferBalance;
    }
    
    /**
     * @notice Returns the maximum amount of minted tokens a user can receive
     * @return maxEmission uint256 Max emission amount for a user
     */
    function getMaxEmissionAmount(address _subscriber) external view override returns(uint256) {
        return whitelist[_subscriber].maxEmissionAmount;
    }

    /**
     * @notice Returns the maximum amount of tokens a user can receive on a transfer
     * @return maxTransfer uint256 Max transfer amount for a user
     */
    function getMaxTransferAmount(address _subscriber) external view override returns(uint256) {
        return whitelist[_subscriber].maxTransferAmount;
    }

    /**
     * @notice Returns the number of whitelisted accounts
     * @return length uint256 The number of whitelisted accounts
     */
    function getWLLength() external view override returns(uint256) {
        return whitelistLength;
    }

    /**
     * @notice Set a new anonymous threshold for emission
     * @param _newThreshold The new anonymous threshold for emission
     * @dev This method can only by called by a whitelist manager
     */
    function setNewEmissionThreshold(uint256 _newThreshold) external  override onlyWLManagers {
        require(whitelistThrEmissionBalance != _newThreshold, "/threshold-not-changed");
        whitelistThrEmissionBalance = _newThreshold;
        emit LogWLThrEmissionBalanceChanged();
    }

    /**
     * @notice Set a new anonymous threshold for transfers
     * @param _newThreshold The new anonymous threshold for transfers
     * @dev This method can only by called by a whitelist manager
     */
    function setNewTransferThreshold(uint256 _newThreshold) external  override onlyWLManagers {
        require(whitelistThrTransferBalance != _newThreshold, "/threshold-not-changed");
        whitelistThrTransferBalance = _newThreshold;
        emit LogWLThrTransferBalanceChanged();
    }

    /**
     * @notice Change emission and transfer thresholds for a user
     * @param _subscriber The whitelisted user
     * @param _newMaxEmissionAmount New maximum amount that a subscriber can hold during emission phase (in tokens).
     * @param _newMaxTransferAmount New maximum amount that a subscriber can hold during transfer phase (in tokens).
     * @dev This method can only be called by a whitelist operator
     */
    function changeMaxWLAmount(address _subscriber, uint256 _newMaxEmissionAmount, uint256 _newMaxTransferAmount) external override onlyWLOperators {
        require(isWhitelisted(_subscriber), "/investor-not-whitelisted");
        whitelist[_subscriber].maxEmissionAmount = _newMaxEmissionAmount;
        whitelist[_subscriber].maxTransferAmount = _newMaxTransferAmount;
        emit MaxWLAmountChanged();
    }

    /**
     * @notice Add a user to the whitelist
     * @param _subscriber The subscriber to add to the whitelist.
     * @param _maxEmissionAmnt max amount that a subscriber can hold during emission phase (in tokens).
     * @param _maxTransferAmnt max amount that a subscriber can hold during transfer phase (in tokens).
     * @dev This method can only be called by a whitelist operator
     */
    function addToWhitelist(address _subscriber, uint256 _maxEmissionAmnt, uint256 _maxTransferAmnt) external override onlyWLOperators {
        require(_subscriber != address(0), "/invalid-address");
        // require(!whitelist[_subscriber].permitted, "already whitelisted");

        // If already whitelisted, return
        if (whitelist[_subscriber].permitted) {
            return;
        }

        whitelistLength++;

        whitelist[_subscriber].permitted = true;
        whitelist[_subscriber].maxEmissionAmount = _maxEmissionAmnt;
        whitelist[_subscriber].maxTransferAmount = _maxTransferAmnt;

        emit LogWLAddressAdded();
    }

    /**
     * @dev Add a list of user to add to the whitelist (max 100)
     * @param _subscriber The subscriber list to add to the whitelist.
     * @param _maxEmissionAmnt Max amount that a subscriber can hold during emission phase (in tokens).
     * @param _maxTransferAmnt Max amount that a subscriber can hold during transfer phase (in tokens).
     * @dev This method can only be called by a whitelist manager
     * @return _success bool True if all the users are whitlisted
     */
    function addToWhitelistMassive(address[] calldata _subscriber, 
                uint256[] calldata _maxEmissionAmnt,
                uint256[] calldata _maxTransferAmnt) external override onlyWLOperators returns (bool _success) {
        require(_subscriber.length == _maxEmissionAmnt.length, "/invalid-array-length");
        require(_maxTransferAmnt.length == _maxEmissionAmnt.length, "/invalid-array-length");
        require(_subscriber.length <= 100, "/array-too-long");

        for (uint8 i = 0; i < _subscriber.length; i++) {
            require(_subscriber[i] != address(0), "/cannot-whitelist-zero-address");
            // require(!whitelist[_subscriber[i]].permitted, "already whitelisted");

            // If already whitelisted, skip the address
            if (whitelist[_subscriber[i]].permitted) {
                continue;
            }

            whitelistLength++;

            whitelist[_subscriber[i]].permitted = true;
            whitelist[_subscriber[i]].maxEmissionAmount = _maxEmissionAmnt[i];
            whitelist[_subscriber[i]].maxTransferAmount = _maxTransferAmnt[i];
        }

        emit LogWLMassiveAddressesAdded();
        return true;
    }

    /**
     * @notice Remove a subscriber from the whitelist.
     * @param _subscriber The subscriber remove from the whitelist.
     * @param _balance balance of a subscriber to be under the anonymous threshold, otherwise de-whilisting not permitted.
     * @dev This method can only be called by a whitelist operator
     */
    function removeFromWhitelist(address _subscriber, uint256 _balance) external override onlyWLOperators {
        require(_subscriber != address(0), "/invalid-address");
        // require(whitelist[_subscriber].permitted, "not whitelisted");
        require(_balance <= whitelistThrTransferBalance, "/balance-greater-than-whitelist-threshold");

        // if not whitelisted, return
        if (!whitelist[_subscriber].permitted) {
            return;
        }

        whitelistLength--;

        whitelist[_subscriber].permitted = false;
        whitelist[_subscriber].maxEmissionAmount = 0;
        whitelist[_subscriber].maxTransferAmount = 0;

        emit LogWLAddressRemoved();
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}