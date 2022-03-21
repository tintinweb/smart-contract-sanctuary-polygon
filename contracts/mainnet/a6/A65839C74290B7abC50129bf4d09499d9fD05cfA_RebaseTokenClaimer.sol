// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "./interfaces/IAddressRegistry.sol";
import "./interfaces/IOutputReceiverV3.sol";
import "./interfaces/ITokenVault.sol";
import "./interfaces/IRevest.sol";
import "./interfaces/IFNFTHandler.sol";
import "./interfaces/ILockManager.sol";
import "./interfaces/IRewardsHandler.sol";
import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IFeeReporter.sol";
import "./interfaces/IDistributor.sol";
import "./SmartWallet.sol";
import "./SmartWalletWhitelistV2.sol";

// OZ imports
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

interface IWETH {
    function deposit() external payable;
}

/**
 * @title POKT <> Revest integration for splitting off the interest from rebase tokens via smartwallets
 * @author RobAnon
 * @dev 
 */
contract RebaseTokenClaimer is IOutputReceiverV3, Ownable, ERC165, IFeeReporter {
    
    using SafeERC20 for IERC20;

    struct DepositReciept {
        address asset;
        uint balance;
    }

    // Allows proxy functions to be called
    bool public proxyEnabled;

    // Where to find the Revest address registry that contains info about what contracts live where
    address public addressRegistry;

    // Template address for VE wallets
    address public immutable TEMPLATE;

    // The file which tells our frontend how to visually represent such an FNFT
    string public METADATA = "https://revest.mypinata.cloud/ipfs/QmbC58q8UTov9NxNo644mYpUHihVd89yL9przLvJEW5iAD";

    // Constant used for approval
    uint private constant MAX_INT = 2 ** 256 - 1;

    // Fee tracker
    uint private weiFee = 0 ether;

    // For tracking if a given contract has approval for asset
    mapping (address => mapping (address => bool)) private approvedContracts;

    // WMATIC contract
    address private constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    mapping (uint => DepositReciept) public deposits;

    // Initialize the contract with the needed valeus
    constructor(address _provider) {
        addressRegistry = _provider;
        SmartWallet wallet = new SmartWallet();
        TEMPLATE = address(wallet);
    }

    modifier onlyRevestController() {
        require(msg.sender == IAddressRegistry(addressRegistry).getRevest(), 'Unauthorized Access!');
        _;
    }

    modifier onlyTokenHolder(uint fnftId) {
        IAddressRegistry reg = IAddressRegistry(addressRegistry);
        require(IFNFTHandler(reg.getRevestFNFT()).getBalance(msg.sender, fnftId) > 0, 'E064');
        _;
    }

    // Allows core Revest contracts to make sure this contract can do what is needed
    // Mandatory method
    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IOutputReceiver).interfaceId
            || interfaceId == type(IOutputReceiverV2).interfaceId
            || interfaceId == type(IOutputReceiverV3).interfaceId
            || super.supportsInterface(interfaceId);
    }


    function createLock(
        uint endTime,
        uint amountToLock,
        address asset
    ) external payable returns (uint fnftId) {    
        require(msg.value >= weiFee, 'Insufficient fee!');

        // Transfer the tokens from the user to this contract
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amountToLock);
        
        // Pay fee: this is dependent on this contract being whitelisted to allow it to pay
        // nothing via the typical method
        {
            uint wethFee = msg.value;
            address rewards = IAddressRegistry(addressRegistry).getRewardsHandler();
            IWETH(WMATIC).deposit{value: msg.value}();
            if(!approvedContracts[rewards][WMATIC]) {
                IERC20(WMATIC).approve(rewards, MAX_INT);
                approvedContracts[rewards][WMATIC] = true;
            }
            IRewardsHandler(rewards).receiveFee(WMATIC, wethFee);
        }
        
        {
            // Initialize the Revest config object
            IRevest.FNFTConfig memory fnftConfig;

            // Use address zero because we're using TokenVault as placeholder storage
            // Use a zero amount for convenience of access

            // Want FNFT to support multiple deposits
            fnftConfig.isMulti = true;

            // Will result in the asset being sent back to this contract upon withdrawal
            // Results solely in a callback
            fnftConfig.pipeToContract = address(this);  

            // Set these two arrays according to Revest specifications to say
            // Who gets these FNFTs and how many copies of them we should create
            address[] memory recipients = new address[](1);
            recipients[0] = _msgSender();

            uint[] memory quantities = new uint[](1);
            quantities[0] = 1;

            address revest = IAddressRegistry(addressRegistry).getRevest();
            
            fnftId = IRevest(revest).mintTimeLock(endTime, recipients, quantities, fnftConfig);
        }

        address smartWallAdd;
        {
            // We deploy the smart wallet
            smartWallAdd = Clones.cloneDeterministic(TEMPLATE, keccak256(abi.encode(asset, fnftId)));
            SmartWallet wallet = SmartWallet(smartWallAdd);
            
            // Here, check if the smart wallet has approval to spend tokens out of this entry point contract
            if(!approvedContracts[smartWallAdd][asset]) {
                // If it doesn't, approve it
                IERC20(asset).approve(smartWallAdd, MAX_INT);
                approvedContracts[smartWallAdd][asset] = true;
            }

            // We deposit our funds into the wallet
            wallet.depositTokens(amountToLock, asset);
        }

        deposits[fnftId] = DepositReciept(asset, amountToLock);
    }


    function receiveRevestOutput(
        uint fnftId,
        address,
        address payable payee,
        uint
    ) external override  {
        
        // Security check to make sure the Revest vault is the only contract that can call this method
        address vault = IAddressRegistry(addressRegistry).getTokenVault();
        require(_msgSender() == vault, 'E016');
        
        address asset = deposits[fnftId].asset;

        address smartWallAdd = Clones.cloneDeterministic(TEMPLATE, keccak256(abi.encode(asset, fnftId)));
        SmartWallet wallet = SmartWallet(smartWallAdd);
        uint bal = IERC20(asset).balanceOf(smartWallAdd);

        wallet.withdrawTokens(bal, asset, payee);

        // Memory cleanup 
        delete deposits[fnftId];
    }

    // Not applicable, as these cannot be split
    // Why not? We don't enable it in IRevest.FNFTConfig
    function handleFNFTRemaps(uint, uint[] memory, address, bool) external pure override {
        require(false, 'Not applicable');
    }

    // Allows custom parameters to be passed during withdrawals
    // This and the proceeding method are both parts of the V2 output receiver interface
    // and not typically necessary. For the sake of demonstration, they are included
    function receiveSecondaryCallback(
        uint fnftId,
        address payable owner,
        uint quantity,
        IRevest.FNFTConfig memory config,
        bytes memory args
    ) external payable override {}

    // Callback from Revest.sol to extend maturity
    function handleTimelockExtensions(uint fnftId, uint expiration, address) external override onlyRevestController {}

    function handleSplitOperation(uint fnftId, uint[] memory proportions, uint quantity, address caller) external override onlyRevestController {}

    /// Prerequisite: User has approved this contract to spend tokens on their behalf
    function handleAdditionalDeposit(uint fnftId, uint amountToDeposit, uint, address caller) external override onlyRevestController {
        address asset = deposits[fnftId].asset;
        IERC20(asset).safeTransferFrom(caller, address(this), amountToDeposit);
        address smartWallAdd = Clones.cloneDeterministic(TEMPLATE, keccak256(abi.encode(asset, fnftId)));
        SmartWallet wallet = SmartWallet(smartWallAdd);
        wallet.depositTokens(amountToDeposit, asset);
        deposits[fnftId].balance += amountToDeposit;
    }

    // Claims rewards on user's behalf
    function triggerOutputReceiverUpdate(
        uint fnftId,
        bytes memory
    ) external override onlyTokenHolder(fnftId) {
        address asset = deposits[fnftId].asset;
        address smartWallAdd = Clones.cloneDeterministic(TEMPLATE, keccak256(abi.encode(asset, fnftId)));
        uint interest = IERC20(asset).balanceOf(smartWallAdd) - deposits[fnftId].balance;
        SmartWallet wallet = SmartWallet(smartWallAdd);
        wallet.withdrawTokens(interest, asset, msg.sender);
    }       

    function proxyExecute(
        uint fnftId,
        address destination,
        bytes memory data
    ) external onlyTokenHolder(fnftId) returns (bytes memory dataOut) {
        require(proxyEnabled, 'Proxy disabled!');
        address smartWallAdd = Clones.cloneDeterministic(TEMPLATE, keccak256(abi.encode(deposits[fnftId].asset, fnftId)));
        SmartWallet wallet = SmartWallet(smartWallAdd);
        dataOut = wallet.proxyExecute(destination, data);
        wallet.cleanMemory();
    }

    /// Admin Functions

    function setAddressRegistry(address addressRegistry_) external override onlyOwner {
        addressRegistry = addressRegistry_;
    }

    function setWeiFee(uint _fee) external onlyOwner {
        weiFee = _fee;
    }

    function setMetadata(string memory _meta) external onlyOwner {
        METADATA = _meta;
    }

    function setProxyEnabled(bool _enable) external onlyOwner {
        proxyEnabled = _enable;
    }

    /// View Functions

    function getCustomMetadata(uint) external view override returns (string memory) {
        return METADATA;
    }

    // Will give balance in xLQDR
    function getValue(uint fnftId) public view override returns (uint) {
        return deposits[fnftId].balance;
    }

    // Must always be in native asset
    function getAsset(uint fnftId) external view override returns (address) {
        return deposits[fnftId].asset;
    }

    function getOutputDisplayValues(uint fnftId) external view override returns (bytes memory displayData) {
        uint interest = IERC20(deposits[fnftId].asset).balanceOf(getAddressForFNFT(fnftId)) - deposits[fnftId].balance;
        address wallet = getAddressForFNFT(fnftId);
        address asset = deposits[fnftId].asset;
        displayData = abi.encode(interest, wallet, asset, asset);
    }

    function getAddressRegistry() external view override returns (address) {
        return addressRegistry;
    }

    function getRevest() internal view returns (IRevest) {
        return IRevest(IAddressRegistry(addressRegistry).getRevest());
    }

    function getFlatWeiFee(address) external view override returns (uint) {
        return weiFee;
    }

    function getERC20Fee(address) external pure override returns (uint) {
        return 0;
    }

    function getAddressForFNFT(uint fnftId) public view returns (address smartWallAdd) {
        smartWallAdd = Clones.predictDeterministicAddress(TEMPLATE, keccak256(abi.encode(deposits[fnftId].asset, fnftId)));
    }
    
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

/**
 * @title Provider interface for Revest FNFTs
 * @dev
 *
 */
interface IAddressRegistry {

    function initialize(
        address lock_manager_,
        address liquidity_,
        address revest_token_,
        address token_vault_,
        address revest_,
        address fnft_,
        address metadata_,
        address admin_,
        address rewards_
    ) external;

    function getAdmin() external view returns (address);

    function setAdmin(address admin) external;

    function getLockManager() external view returns (address);

    function setLockManager(address manager) external;

    function getTokenVault() external view returns (address);

    function setTokenVault(address vault) external;

    function getRevestFNFT() external view returns (address);

    function setRevestFNFT(address fnft) external;

    function getMetadataHandler() external view returns (address);

    function setMetadataHandler(address metadata) external;

    function getRevest() external view returns (address);

    function setRevest(address revest) external;

    function getDEX(uint index) external view returns (address);

    function setDex(address dex) external;

    function getRevestToken() external view returns (address);

    function setRevestToken(address token) external;

    function getRewardsHandler() external view returns(address);

    function setRewardsHandler(address esc) external;

    function getAddress(bytes32 id) external view returns (address);

    function getLPs() external view returns (address);

    function setLPs(address liquidToken) external;

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IOutputReceiverV2.sol";


/**
 * @title Provider interface for Revest FNFTs
 */
interface IOutputReceiverV3 is IOutputReceiverV2 {

    event DepositERC20OutputReceiver(address indexed mintTo, address indexed token, uint amountTokens, uint indexed fnftId, bytes extraData);

    event DepositERC721OutputReceiver(address indexed mintTo, address indexed token, uint[] tokenIds, uint indexed fnftId, bytes extraData);

    event DepositERC1155OutputReceiver(address indexed mintTo, address indexed token, uint tokenId, uint amountTokens, uint indexed fnftId, bytes extraData);

    event WithdrawERC20OutputReceiver(address indexed caller, address indexed token, uint amountTokens, uint indexed fnftId, bytes extraData);

    event WithdrawERC721OutputReceiver(address indexed caller, address indexed token, uint[] tokenIds, uint indexed fnftId, bytes extraData);

    event WithdrawERC1155OutputReceiver(address indexed caller, address indexed token, uint tokenId, uint amountTokens, uint indexed fnftId, bytes extraData);

    function handleTimelockExtensions(uint fnftId, uint expiration, address caller) external;

    function handleAdditionalDeposit(uint fnftId, uint amountToDeposit, uint quantity, address caller) external;

    function handleSplitOperation(uint fnftId, uint[] memory proportions, uint quantity, address caller) external;

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IRevest.sol";

interface ITokenVault {

    function createFNFT(
        uint fnftId,
        IRevest.FNFTConfig memory fnftConfig,
        uint quantity,
        address from
    ) external;

    function withdrawToken(
        uint fnftId,
        uint quantity,
        address user
    ) external;

    function depositToken(
        uint fnftId,
        uint amount,
        uint quantity
    ) external;

    function cloneFNFTConfig(IRevest.FNFTConfig memory old) external returns (IRevest.FNFTConfig memory);

    function mapFNFTToToken(
        uint fnftId,
        IRevest.FNFTConfig memory fnftConfig
    ) external;

    function handleMultipleDeposits(
        uint fnftId,
        uint newFNFTId,
        uint amount
    ) external;

    function splitFNFT(
        uint fnftId,
        uint[] memory newFNFTIds,
        uint[] memory proportions,
        uint quantity
    ) external;

    function getFNFT(uint fnftId) external view returns (IRevest.FNFTConfig memory);
    function getFNFTCurrentValue(uint fnftId) external view returns (uint);
    function getNontransferable(uint fnftId) external view returns (bool);
    function getSplitsRemaining(uint fnftId) external view returns (uint);
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

interface IRevest {
    event FNFTTimeLockMinted(
        address indexed asset,
        address indexed from,
        uint indexed fnftId,
        uint endTime,
        uint[] quantities,
        FNFTConfig fnftConfig
    );

    event FNFTValueLockMinted(
        address indexed asset,
        address indexed from,
        uint indexed fnftId,
        address compareTo,
        address oracleDispatch,
        uint[] quantities,
        FNFTConfig fnftConfig
    );

    event FNFTAddressLockMinted(
        address indexed asset,
        address indexed from,
        uint indexed fnftId,
        address trigger,
        uint[] quantities,
        FNFTConfig fnftConfig
    );

    event FNFTWithdrawn(
        address indexed from,
        uint indexed fnftId,
        uint indexed quantity
    );

    event FNFTSplit(
        address indexed from,
        uint[] indexed newFNFTId,
        uint[] indexed proportions,
        uint quantity
    );

    event FNFTUnlocked(
        address indexed from,
        uint indexed fnftId
    );

    event FNFTMaturityExtended(
        address indexed from,
        uint indexed fnftId,
        uint indexed newExtendedTime
    );

    event FNFTAddionalDeposited(
        address indexed from,
        uint indexed newFNFTId,
        uint indexed quantity,
        uint amount
    );

    struct FNFTConfig {
        address asset; // The token being stored
        address pipeToContract; // Indicates if FNFT will pipe to another contract
        uint depositAmount; // How many tokens
        uint depositMul; // Deposit multiplier
        uint split; // Number of splits remaining
        uint depositStopTime; //
        bool maturityExtension; // Maturity extensions remaining
        bool isMulti; //
        bool nontransferrable; // False by default (transferrable) //
    }

    // Refers to the global balance for an ERC20, encompassing possibly many FNFTs
    struct TokenTracker {
        uint lastBalance;
        uint lastMul;
    }

    enum LockType {
        DoesNotExist,
        TimeLock,
        ValueLock,
        AddressLock
    }

    struct LockParam {
        address addressLock;
        uint timeLockExpiry;
        LockType lockType;
        ValueLock valueLock;
    }

    struct Lock {
        address addressLock;
        LockType lockType;
        ValueLock valueLock;
        uint timeLockExpiry;
        uint creationTime;
        bool unlocked;
    }

    struct ValueLock {
        address asset;
        address compareTo;
        address oracle;
        uint unlockValue;
        bool unlockRisingEdge;
    }

    function mintTimeLock(
        uint endTime,
        address[] memory recipients,
        uint[] memory quantities,
        IRevest.FNFTConfig memory fnftConfig
    ) external payable returns (uint);

    function mintValueLock(
        address primaryAsset,
        address compareTo,
        uint unlockValue,
        bool unlockRisingEdge,
        address oracleDispatch,
        address[] memory recipients,
        uint[] memory quantities,
        IRevest.FNFTConfig memory fnftConfig
    ) external payable returns (uint);

    function mintAddressLock(
        address trigger,
        bytes memory arguments,
        address[] memory recipients,
        uint[] memory quantities,
        IRevest.FNFTConfig memory fnftConfig
    ) external payable returns (uint);

    function withdrawFNFT(uint tokenUID, uint quantity) external;

    function unlockFNFT(uint tokenUID) external;

    function splitFNFT(
        uint fnftId,
        uint[] memory proportions,
        uint quantity
    ) external returns (uint[] memory newFNFTIds);

    function depositAdditionalToFNFT(
        uint fnftId,
        uint amount,
        uint quantity
    ) external returns (uint);

    function extendFNFTMaturity(
        uint fnftId,
        uint endTime
    ) external returns (uint);

    function setFlatWeiFee(uint wethFee) external;

    function setERC20Fee(uint erc20) external;

    function getFlatWeiFee() external view returns (uint);

    function getERC20Fee() external view returns (uint);


}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;


interface IFNFTHandler  {
    function mint(address account, uint id, uint amount, bytes memory data) external;

    function mintBatchRec(address[] memory recipients, uint[] memory quantities, uint id, uint newSupply, bytes memory data) external;

    function mintBatch(address to, uint[] memory ids, uint[] memory amounts, bytes memory data) external;

    function setURI(string memory newuri) external;

    function burn(address account, uint id, uint amount) external;

    function burnBatch(address account, uint[] memory ids, uint[] memory amounts) external;

    function getBalance(address tokenHolder, uint id) external view returns (uint);

    function getSupply(uint fnftId) external view returns (uint);

    function getNextId() external view returns (uint);
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IRevest.sol";

interface ILockManager {

    function createLock(uint fnftId, IRevest.LockParam memory lock) external returns (uint);

    function getLock(uint lockId) external view returns (IRevest.Lock memory);

    function fnftIdToLockId(uint fnftId) external view returns (uint);

    function fnftIdToLock(uint fnftId) external view returns (IRevest.Lock memory);

    function pointFNFTToLock(uint fnftId, uint lockId) external;

    function lockTypes(uint tokenId) external view returns (IRevest.LockType);

    function unlockFNFT(uint fnftId, address sender) external returns (bool);

    function getLockMaturity(uint fnftId) external view returns (bool);
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

interface IRewardsHandler {

    struct UserBalance {
        uint allocPoint; // Allocation points
        uint lastMul;
    }

    function receiveFee(address token, uint amount) external;

    function updateLPShares(uint fnftId, uint newShares) external;

    function updateBasicShares(uint fnftId, uint newShares) external;

    function getAllocPoint(uint fnftId, address token, bool isBasic) external view returns (uint);

    function claimRewards(uint fnftId, address caller) external returns (uint);

    function setStakingContract(address stake) external;

    function getRewards(uint fnftId, address token) external view returns (uint);
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IRegistryProvider.sol";
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

/**
 * @title Provider interface for Revest FNFTs
 */
interface IVotingEscrow {

    struct Point {
        int128 bias;
        int128 slope;
        uint ts;
        uint blk;
    }

    function create_lock(uint _value, uint _unlock_time) external;

    function increase_amount(uint _value) external;

    function increase_unlock_time(uint _unlock_time) external;

    function withdraw() external;

    function smart_wallet_checker() external view returns (address walletCheck);

    function token() external view returns (address tok);

    function locked__end(address _addr) external view returns (uint lockEnd);

    function balanceOf(address _addr) external view returns (uint balance);

    function user_point_epoch(address _addr) external view returns (uint epoch);

    function user_point_history(address _addr, uint index) external view returns (Point memory pt);

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;


interface IFeeReporter {

    function getFlatWeiFee(address asset) external view returns (uint);

    function getERC20Fee(address asset) external view returns (uint);

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IRegistryProvider.sol";
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

/**
 * @title Provider interface for Revest FNFTs
 */
interface IDistributor {

    function claim() external returns (uint amountTransferred);

    function N_COINS() external view returns (uint n);

    function tokens(uint index) external view returns (address token);

    function user_epoch_of(address _addr) external view returns (uint epoch);

    function tokens_per_day(uint index, uint index2) external view returns (uint tokensPerDay);

    function start_time() external view returns (uint startTime);

    function last_token_times(uint index) external view returns (uint lastTime);//Call with index 0

    function time_cursor() external view returns (uint timeCursor);

    function time_cursor_of(address addr) external view returns (uint timeCursor);

    function ve_supply(uint index) external view returns (uint supply);

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IDistributor.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


pragma solidity ^0.8.0;

/// @author RobAnon
contract SmartWallet {

    using SafeERC20 for IERC20;

    uint private constant MAX_INT = 2 ** 256 - 1;

    address private immutable MASTER;

    constructor() {
        MASTER = msg.sender;
    }

    modifier onlyMaster() {
        require(msg.sender == MASTER, 'Unauthorized!');
        _;
    }

    function depositTokens(uint value, address asset) external onlyMaster {
        // Only callable from the parent contract, transfer tokens from user -> parent, parent -> VE
        // Pull value into this contract
        IERC20(asset).safeTransferFrom(MASTER, address(this), value);
        _cleanMemory();
    }

    function withdrawTokens(uint amount, address asset, address recipient) external onlyMaster {
        IERC20(asset).safeTransfer(recipient, amount);
        _cleanMemory();
    }

    /// Proxy function to send arbitrary messages. Useful for delegating votes and similar activities
    function proxyExecute(
        address destination,
        bytes memory data
    ) external payable onlyMaster returns (bytes memory dataOut) {
        (bool success, bytes memory dataTemp)= destination.call{value:msg.value}(data);
        require(success, 'Proxy call failed!');
        dataOut = dataTemp;
    }

    /// Credit to doublesharp for the brilliant gas-saving concept
    /// Self-destructing clone pattern
    function cleanMemory() external onlyMaster {
        _cleanMemory();
    }

    function _cleanMemory() internal {
        selfdestruct(payable(MASTER));
    }

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

interface SmartWalletChecker {
    function check(address) external view returns (bool);
}

/// @author RobAnon
contract SmartWalletWhitelistV2 {
    
    mapping(address => bool) public wallets;
    
    bytes32 public constant ADMIN = "ADMIN";

    mapping(address => bytes32) public roles;
    
    address public checker;
    address public future_checker;
    
    event ApproveWallet(address);
    event RevokeWallet(address);
    
    constructor(address _admin) {
        roles[_admin] = ADMIN;
    }
    
    function commitSetChecker(address _checker) external {
        require(isAdmin(msg.sender), "!admin");
        future_checker = _checker;
    }

    function changeAdmin(address _admin, bool validAdmin) external {
        require(isAdmin(msg.sender), "!admin");
        if(validAdmin) {
            roles[_admin] = ADMIN;
        } else {
            roles[_admin] = 0x0;
        }
    }
    
    function applySetChecker() external {
        require(isAdmin(msg.sender), "!admin");
        checker = future_checker;
    }
    
    function approveWallet(address _wallet) public {
        require(isAdmin(msg.sender), "!admin");
        wallets[_wallet] = true;
        
        emit ApproveWallet(_wallet);
    }
    function revokeWallet(address _wallet) external {
        require(isAdmin(msg.sender), "!admin");
        wallets[_wallet] = false;
        
        emit RevokeWallet(_wallet);
    }
    
    function check(address _wallet) external view returns (bool) {
        bool _check = wallets[_wallet];
        if (_check) {
            return _check;
        } else {
            if (checker != address(0)) {
                return SmartWalletChecker(checker).check(_wallet);
            }
        }
        return false;
    }

    function isAdmin(address checkAdd) internal view returns (bool valid) {
        valid = roles[checkAdd] == ADMIN;
    }


    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IOutputReceiver.sol";
import "./IRevest.sol";
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';


/**
 * @title Provider interface for Revest FNFTs
 */
interface IOutputReceiverV2 is IOutputReceiver {

    // Future proofing for secondary callbacks during withdrawal
    // Could just use triggerOutputReceiverUpdate and call withdrawal function
    // But deliberately using reentry is poor form and reminds me too much of OAuth 2.0 
    function receiveSecondaryCallback(
        uint fnftId,
        address payable owner,
        uint quantity,
        IRevest.FNFTConfig memory config,
        bytes memory args
    ) external payable;

    // Allows for similar function to address lock, updating state while still locked
    // Called by the user directly
    function triggerOutputReceiverUpdate(
        uint fnftId,
        bytes memory args
    ) external;

    // This function should only ever be called when a split or additional deposit has occurred 
    function handleFNFTRemaps(uint fnftId, uint[] memory newFNFTIds, address caller, bool cleanup) external;

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IRegistryProvider.sol";
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

/**
 * @title Provider interface for Revest FNFTs
 */
interface IOutputReceiver is IRegistryProvider, IERC165 {

    function receiveRevestOutput(
        uint fnftId,
        address asset,
        address payable owner,
        uint quantity
    ) external;

    function getCustomMetadata(uint fnftId) external view returns (string memory);

    function getValue(uint fnftId) external view returns (uint);

    function getAsset(uint fnftId) external view returns (address);

    function getOutputDisplayValues(uint fnftId) external view returns (bytes memory);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

interface IRegistryProvider {
    function setAddressRegistry(address revest) external;

    function getAddressRegistry() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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