// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "./IComponent.sol";
import "../modules/IAccess.sol";
import "../modules/IComponentEvents.sol";
import "../modules/IRegistry.sol";
import "../services/IComponentOwnerService.sol";
import "../services/IInstanceService.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/GUIDELINES.md#style-guidelines
abstract contract Component is 
    IComponent,
    IComponentEvents,
    Ownable 
{
    bytes32 private _componentName;
    uint256 private _componentId;
    IComponent.ComponentType private _componentType;

    IRegistry private _registry;
    IAccess private _access;
    IComponentOwnerService private _componentOwnerService;
    IInstanceService private _instanceService;

    modifier onlyInstanceOperatorService() {
        require(
             _msgSender() == _getContractAddress("InstanceOperatorService"),
            "ERROR:CMP-001:NOT_INSTANCE_OPERATOR_SERVICE");
        _;
    }

    modifier onlyComponent() {
        require(
             _msgSender() == _getContractAddress("Component"),
            "ERROR:CMP-002:NOT_COMPONENT");
        _;
    }

    modifier onlyComponentOwnerService() {
        require(
             _msgSender() == address(_componentOwnerService),
            "ERROR:CMP-003:NOT_COMPONENT_OWNER_SERVICE");
        _;
    }

    constructor(
        bytes32 name,
        IComponent.ComponentType componentType,
        address registry
    )
        Ownable()
    {
        require(registry != address(0), "ERROR:CMP-004:REGISTRY_ADDRESS_ZERO");

        _registry = IRegistry(registry);
        _access = _getAccess();
        _componentOwnerService = _getComponentOwnerService();
        _instanceService = _getInstanceService();

        _componentName = name;
        _componentType = componentType;

        emit LogComponentCreated(
            _componentName, 
            _componentType, 
            address(this), 
            address(_registry));
    }

    function setId(uint256 id) external override onlyComponent { _componentId = id; }

    function getName() public override view returns(bytes32) { return _componentName; }
    function getId() public override view returns(uint256) { return _componentId; }
    function getType() public override view returns(IComponent.ComponentType) { return _componentType; }
    function getState() public override view returns(IComponent.ComponentState) { return _instanceService.getComponentState(_componentId); }
    function getOwner() public override view returns(address) { return owner(); }

    function isProduct() public override view returns(bool) { return _componentType == IComponent.ComponentType.Product; }
    function isOracle() public override view returns(bool) { return _componentType == IComponent.ComponentType.Oracle; }
    function isRiskpool() public override view returns(bool) { return _componentType == IComponent.ComponentType.Riskpool; }

    function getRegistry() external override view returns(IRegistry) { return _registry; }

    function proposalCallback() public override onlyComponent { _afterPropose(); }
    function approvalCallback() public override onlyComponent { _afterApprove(); }
    function declineCallback() public override onlyComponent { _afterDecline(); }
    function suspendCallback() public override onlyComponent { _afterSuspend(); }
    function resumeCallback() public override onlyComponent { _afterResume(); }
    function pauseCallback() public override onlyComponent { _afterPause(); }
    function unpauseCallback() public override onlyComponent { _afterUnpause(); }
    function archiveCallback() public override onlyComponent { _afterArchive(); }
    
    // these functions are intended to be overwritten to implement
    // component specific notification handling
    function _afterPropose() internal virtual {}
    function _afterApprove() internal virtual {}
    function _afterDecline() internal virtual {}
    function _afterSuspend() internal virtual {}
    function _afterResume() internal virtual {}
    function _afterPause() internal virtual {}
    function _afterUnpause() internal virtual {}
    function _afterArchive() internal virtual {}

    function _getAccess() internal view returns (IAccess) {
        return IAccess(_getContractAddress("Access"));        
    }

    function _getInstanceService() internal view returns (IInstanceService) {
        return IInstanceService(_getContractAddress("InstanceService"));        
    }

    function _getComponentOwnerService() internal view returns (IComponentOwnerService) {
        return IComponentOwnerService(_getContractAddress("ComponentOwnerService"));        
    }

    function _getContractAddress(bytes32 contractName) internal view returns (address) { 
        return _registry.getContract(contractName);
    }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "../modules/IRegistry.sol";

interface IComponent {

    enum ComponentType {
        Oracle,
        Product,
        Riskpool
    }

    enum ComponentState {
        Created,
        Proposed,
        Declined,
        Active,
        Paused,
        Suspended,
        Archived
    }

    event LogComponentCreated (
        bytes32 componentName,
        IComponent.ComponentType componentType,
        address componentAddress,
        address registryAddress);

    function setId(uint256 id) external;

    function getName() external view returns(bytes32);
    function getId() external view returns(uint256);
    function getType() external view returns(ComponentType);
    function getState() external view returns(ComponentState);
    function getOwner() external view returns(address);

    function isProduct() external view returns(bool);
    function isOracle() external view returns(bool);
    function isRiskpool() external view returns(bool);

    function getRegistry() external view returns(IRegistry);

    function proposalCallback() external;
    function approvalCallback() external; 
    function declineCallback() external;
    function suspendCallback() external;
    function resumeCallback() external;
    function pauseCallback() external;
    function unpauseCallback() external;
    function archiveCallback() external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "./IComponent.sol";

interface IOracle is IComponent {
    
    event LogOracleCreated (address oracleAddress);
    event LogOracleProposed (uint256 componentId);
    event LogOracleApproved (uint256 componentId);
    event LogOracleDeclined (uint256 componentId);
    
    function request(uint256 requestId, bytes calldata input) external;
    function cancel(uint256 requestId) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "./IOracle.sol";
import "./Component.sol";
import "./IComponent.sol";
import "../services/IOracleService.sol";

abstract contract Oracle is
    IOracle, 
    Component 
{   
    IOracleService private _oracleService;

    modifier onlyQuery {
        require(
             _msgSender() == _getContractAddress("Query"),
            "ERROR:ORA-001:ACCESS_DENIED"
        );
        _;
    }

    constructor(
        bytes32 name,
        address registry
    )
        Component(name, ComponentType.Oracle, registry)
    {
        _oracleService = IOracleService(_getContractAddress("OracleService"));
        emit LogOracleCreated(address(this));
    }

    // default callback function implementations
    function _afterApprove() internal override { 
        emit LogOracleApproved(getId()); 
    }

    function _afterPropose() internal override { emit LogOracleProposed(getId()); }
    function _afterDecline() internal override { emit LogOracleDeclined(getId()); }

    function _respond(uint256 requestId, bytes memory data) internal {
        _oracleService.respond(requestId, data);
    }    
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IAccess {
    function getDefaultAdminRole() external view returns(bytes32 role);
    function getProductOwnerRole() external view returns(bytes32 role);
    function getOracleProviderRole() external view returns(bytes32 role);
    function getRiskpoolKeeperRole() external view returns(bytes32 role);
    function hasRole(bytes32 role, address principal) external view returns(bool);

    function grantRole(bytes32 role, address principal) external;
    function revokeRole(bytes32 role, address principal) external;
    function renounceRole(bytes32 role, address principal) external;
    
    function addRole(bytes32 role) external;
    function invalidateRole(bytes32 role) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IBundle {

    event LogBundleCreated(
        uint256 bundleId, 
        uint256 riskpoolId, 
        address owner,
        BundleState state,
        uint256 amount
    );

    event LogBundleStateChanged(uint256 bundleId, BundleState oldState, BundleState newState);

    event LogBundleCapitalProvided(uint256 bundleId, address sender, uint256 amount, uint256 capacity);
    event LogBundleCapitalWithdrawn(uint256 bundleId, address recipient, uint256 amount, uint256 capacity);

    event LogBundlePolicyCollateralized(uint256 bundleId, bytes32 processId, uint256 amount, uint256 capacity);
    event LogBundlePayoutProcessed(uint256 bundleId, bytes32 processId, uint256 amount);
    event LogBundlePolicyReleased(uint256 bundleId, bytes32 processId, uint256 amount, uint256 capacity);

    enum BundleState {
        Active,
        Locked,
        Closed,
        Burned
    }

    struct Bundle {
        uint256 id;
        uint256 riskpoolId;
        uint256 tokenId;
        BundleState state;
        bytes filter; // required conditions for applications to be considered for collateralization by this bundle
        uint256 capital; // net investment capital amount (<= balance)
        uint256 lockedCapital; // capital amount linked to collateralizaion of non-closed policies (<= capital)
        uint256 balance; // total amount of funds: net investment capital + net premiums - payouts
        uint256 createdAt;
        uint256 updatedAt;
    }

    function create(address owner_, uint256 riskpoolId_, bytes calldata filter_, uint256 amount_) external returns(uint256 bundleId);
    function fund(uint256 bundleId, uint256 amount) external;
    function defund(uint256 bundleId, uint256 amount) external;

    function lock(uint256 bundleId) external;
    function unlock(uint256 bundleId) external;
    function close(uint256 bundleId) external;
    function burn(uint256 bundleId) external;

    function collateralizePolicy(uint256 bundleId, bytes32 processId, uint256 collateralAmount) external;
    function processPremium(uint256 bundleId, bytes32 processId, uint256 amount) external;
    function processPayout(uint256 bundleId, bytes32 processId, uint256 amount) external;
    function releasePolicy(uint256 bundleId, bytes32 processId) external returns(uint256 collateralAmount);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "../components/IComponent.sol";

interface IComponentEvents {

    event LogComponentProposed (
        bytes32 componentName,
        IComponent.ComponentType componentType,
        address componentAddress,
        uint256 id);
    
    event LogComponentApproved (uint256 id);
    event LogComponentDeclined (uint256 id);

    event LogComponentSuspended (uint256 id);
    event LogComponentResumed (uint256 id);

    event LogComponentPaused (uint256 id);
    event LogComponentUnpaused (uint256 id);

    event LogComponentArchived (uint256 id);

    event LogComponentStateChanged (
        uint256 id, 
        IComponent.ComponentState stateOld, 
        IComponent.ComponentState stateNew);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IPolicy {

    // Events
    event LogMetadataCreated(
        address owner,
        bytes32 processId,
        uint256 productId, 
        PolicyFlowState state
    );

    event LogMetadataStateChanged(
        bytes32 processId, 
        PolicyFlowState state
    );

    event LogApplicationCreated(
        bytes32 processId, 
        uint256 premiumAmount, 
        uint256 sumInsuredAmount
    );

    event LogApplicationRevoked(bytes32 processId);
    event LogApplicationUnderwritten(bytes32 processId);
    event LogApplicationDeclined(bytes32 processId);

    event LogPolicyCreated(bytes32 processId);
    event LogPolicyExpired(bytes32 processId);
    event LogPolicyClosed(bytes32 processId);

    event LogPremiumCollected(bytes32 processId, uint256 amount);
    
    event LogApplicationSumInsuredAdjusted(bytes32 processId, uint256 sumInsuredAmountOld, uint256 sumInsuredAmount);
    event LogApplicationPremiumAdjusted(bytes32 processId, uint256 premiumAmountOld, uint256 premiumAmount);
    event LogPolicyPremiumAdjusted(bytes32 processId, uint256 premiumExpectedAmountOld, uint256 premiumExpectedAmount);

    event LogClaimCreated(bytes32 processId, uint256 claimId, uint256 claimAmount);
    event LogClaimConfirmed(bytes32 processId, uint256 claimId, uint256 confirmedAmount);
    event LogClaimDeclined(bytes32 processId, uint256 claimId);
    event LogClaimClosed(bytes32 processId, uint256 claimId);

    event LogPayoutCreated(
        bytes32 processId,
        uint256 claimId,
        uint256 payoutId,
        uint256 amount
    );

    event LogPayoutProcessed(
        bytes32 processId, 
        uint256 payoutId
    );

    // States
    enum PolicyFlowState {Started, Active, Finished}
    enum ApplicationState {Applied, Revoked, Underwritten, Declined}
    enum PolicyState {Active, Expired, Closed}
    enum ClaimState {Applied, Confirmed, Declined, Closed}
    enum PayoutState {Expected, PaidOut}

    // Objects
    struct Metadata {
        address owner;
        uint256 productId;
        PolicyFlowState state;
        bytes data;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct Application {
        ApplicationState state;
        uint256 premiumAmount;
        uint256 sumInsuredAmount;
        bytes data; 
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct Policy {
        PolicyState state;
        uint256 premiumExpectedAmount;
        uint256 premiumPaidAmount;
        uint256 claimsCount;
        uint256 openClaimsCount;
        uint256 payoutMaxAmount;
        uint256 payoutAmount;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct Claim {
        ClaimState state;
        uint256 claimAmount;
        uint256 paidAmount;
        bytes data;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct Payout {
        uint256 claimId;
        PayoutState state;
        uint256 amount;
        bytes data;
        uint256 createdAt;
        uint256 updatedAt;
    }

    function createPolicyFlow(
        address owner,
        uint256 productId, 
        bytes calldata data
    ) external returns(bytes32 processId);

    function createApplication(
        bytes32 processId, 
        uint256 premiumAmount,
        uint256 sumInsuredAmount,
        bytes calldata data
    ) external;

    function revokeApplication(bytes32 processId) external;
    function underwriteApplication(bytes32 processId) external;
    function declineApplication(bytes32 processId) external;

    function collectPremium(bytes32 processId, uint256 amount) external;

    function adjustPremiumSumInsured(
        bytes32 processId, 
        uint256 expectedPremiumAmount,
        uint256 sumInsuredAmount
    ) external;

    function createPolicy(bytes32 processId) external;
    function expirePolicy(bytes32 processId) external;
    function closePolicy(bytes32 processId) external;

    function createClaim(
        bytes32 processId, 
        uint256 claimAmount, 
        bytes calldata data
    ) external returns (uint256 claimId);

    function confirmClaim(
        bytes32 processId, 
        uint256 claimId, 
        uint256 confirmedAmount
    ) external;

    function declineClaim(bytes32 processId, uint256 claimId) external;
    function closeClaim(bytes32 processId, uint256 claimId) external;

    function createPayout(
        bytes32 processId,
        uint256 claimId,
        uint256 payoutAmount,
        bytes calldata data
    ) external returns (uint256 payoutId);

    function processPayout(
        bytes32 processId,
        uint256 payoutId
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IPool {

    event LogRiskpoolRegistered(
        uint256 riskpoolId, 
        address wallet,
        address erc20Token, 
        uint256 collateralizationLevel, 
        uint256 sumOfSumInsuredCap
    );
    
    event LogRiskpoolRequiredCollateral(bytes32 processId, uint256 sumInsured, uint256 collateral);
    event LogRiskpoolCollateralizationFailed(uint256 riskpoolId, bytes32 processId, uint256 amount);
    event LogRiskpoolCollateralizationSucceeded(uint256 riskpoolId, bytes32 processId, uint256 amount);
    event LogRiskpoolCollateralReleased(uint256 riskpoolId, bytes32 processId, uint256 amount);

    struct Pool {
        uint256 id; // matches component id of riskpool
        address wallet; // riskpool wallet
        address erc20Token; // the value token of the riskpool
        uint256 collateralizationLevel; // required collateralization level to cover new policies 
        uint256 sumOfSumInsuredCap; // max sum of sum insured the pool is allowed to secure
        uint256 sumOfSumInsuredAtRisk; // current sum of sum insured at risk in this pool
        uint256 capital; // net investment capital amount (<= balance)
        uint256 lockedCapital; // capital amount linked to collateralizaion of non-closed policies (<= capital)
        uint256 balance; // total amount of funds: net investment capital + net premiums - payouts
        uint256 createdAt;
        uint256 updatedAt;
    }

    function registerRiskpool(
        uint256 riskpoolId, 
        address wallet,
        address erc20Token,
        uint256 collateralizationLevel, 
        uint256 sumOfSumInsuredCap
    ) external;

    function setRiskpoolForProduct(uint256 productId, uint256 riskpoolId) external;

    function underwrite(bytes32 processId) external returns(bool success);
    function processPremium(bytes32 processId, uint256 amount) external;
    function processPayout(bytes32 processId, uint256 amount) external;
    function release(bytes32 processId) external; 
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IRegistry {

    event LogContractRegistered(
        bytes32 release,
        bytes32 contractName,
        address contractAddress,
        bool isNew
    );

    event LogContractDeregistered(bytes32 release, bytes32 contractName);

    event LogReleasePrepared(bytes32 release);

    function registerInRelease(
        bytes32 _release,
        bytes32 _contractName,
        address _contractAddress
    ) external;

    function register(bytes32 _contractName, address _contractAddress) external;

    function deregisterInRelease(bytes32 _release, bytes32 _contractName)
        external;

    function deregister(bytes32 _contractName) external;

    function prepareRelease(bytes32 _newRelease) external;

    function getContractInRelease(bytes32 _release, bytes32 _contractName)
        external
        view
        returns (address _contractAddress);

    function getContract(bytes32 _contractName)
        external
        view
        returns (address _contractAddress);

    function getRelease() external view returns (bytes32 _release);

    function ensureSender(address sender, bytes32 _contractName) external view returns(bool _senderMatches);

    function contracts() external view returns (uint256 _numberOfContracts);

    function contractName(uint256 idx) external view returns (bytes32 _contractName);

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITreasury {

    event LogTreasurySuspended();
    event LogTreasuryResumed();

    event LogTreasuryProductTokenSet(uint256 productId, uint256 riskpoolId, address erc20Address);
    event LogTreasuryInstanceWalletSet(address walletAddress);
    event LogTreasuryRiskpoolWalletSet(uint256 riskpoolId, address walletAddress);

    event LogTreasuryPremiumFeesSet(uint256 productId, uint256 fixedFee, uint256 fractionalFee);
    event LogTreasuryCapitalFeesSet(uint256 riskpoolId, uint256 fixedFee, uint256 fractionalFee);

    event LogTreasuryPremiumTransferred(address from, address riskpoolWalletAddress, uint256 amount);
    event LogTreasuryPayoutTransferred(address riskpoolWalletAddress, address to, uint256 amount);
    event LogTreasuryCapitalTransferred(address from, address riskpoolWalletAddress, uint256 amount);
    event LogTreasuryFeesTransferred(address from, address instanceWalletAddress, uint256 amount);
    event LogTreasuryWithdrawalTransferred(address riskpoolWalletAddress, address to, uint256 amount);

    event LogTreasuryPremiumProcessed(bytes32 processId, uint256 amount);
    event LogTreasuryPayoutProcessed(uint256 riskpoolId, address to, uint256 amount);
    event LogTreasuryCapitalProcessed(uint256 riskpoolId, uint256 bundleId, uint256 amount);
    event LogTreasuryWithdrawalProcessed(uint256 riskpoolId, uint256 bundleId, uint256 amount);

    struct FeeSpecification {
        uint256 componentId;
        uint256 fixedFee;
        uint256 fractionalFee;
        bytes feeCalculationData;
        uint256 createdAt;
        uint256 updatedAt;
    }

    function setProductToken(uint256 productId, address erc20Address) external;

    function setInstanceWallet(address instanceWalletAddress) external;
    function setRiskpoolWallet(uint256 riskpoolId, address riskpoolWalletAddress) external;

    function createFeeSpecification(
        uint256 componentId,
        uint256 fixedFee,
        uint256 fractionalFee,
        bytes calldata feeCalculationData
    )
        external view returns(FeeSpecification memory feeSpec);
    
    function setPremiumFees(FeeSpecification calldata feeSpec) external;
    function setCapitalFees(FeeSpecification calldata feeSpec) external;
    
    function processPremium(bytes32 processId) external 
        returns(
            bool success,
            uint256 feeAmount,
            uint256 netPremiumAmount
        );
    
    function processPremium(bytes32 processId, uint256 amount) external 
        returns(
            bool success,
            uint256 feeAmount,
            uint256 netPremiumAmount
        );
    
    function processPayout(bytes32 processId, uint256 payoutId) external 
        returns(
            uint256 feeAmount,
            uint256 netPayoutAmount
        );
    
    function processCapital(uint256 bundleId, uint256 capitalAmount) external 
        returns(
            uint256 feeAmount,
            uint256 netCapitalAmount
        );

    function processWithdrawal(uint256 bundleId, uint256 amount) external
        returns(
            uint256 feeAmount,
            uint256 netAmount
        );

    function getComponentToken(uint256 componentId) external view returns(IERC20 token);
    function getFeeSpecification(uint256 componentId) external view returns(FeeSpecification memory feeSpecification);

    function getFractionFullUnit() external view returns(uint256);
    function getInstanceWallet() external view returns(address instanceWalletAddress);
    function getRiskpoolWallet(uint256 riskpoolId) external view returns(address riskpoolWalletAddress);

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "../components/IComponent.sol";

interface IComponentOwnerService {

    function propose(IComponent component) external;

    function stake(uint256 id) external;
    function withdraw(uint256 id) external;

    function pause(uint256 id) external; 
    function unpause(uint256 id) external;

    function archive(uint256 id) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "../modules/ITreasury.sol";

interface IInstanceOperatorService {

    // registry
    function prepareRelease(bytes32 newRelease) external;
    function register(bytes32 contractName, address contractAddress) external;
    function deregister(bytes32 contractName) external;
    function registerInRelease(bytes32 release, bytes32 contractName, address contractAddress) external;
    function deregisterInRelease(bytes32 release, bytes32 contractName) external;

    // access
    function createRole(bytes32 role) external;
    function invalidateRole(bytes32 role) external;
    function grantRole(bytes32 role, address principal) external;
    function revokeRole(bytes32 role, address principal) external;

    // component
    function approve(uint256 id) external;
    function decline(uint256 id) external;
    function suspend(uint256 id) external;
    function resume(uint256 id) external;
    function archive(uint256 id) external;
    
    // service staking
    function setDefaultStaking(uint16 componentType, bytes calldata data) external;
    function adjustStakingRequirements(uint256 id, bytes calldata data) external;

    // treasury
    function suspendTreasury() external;
    function resumeTreasury() external;
    
    function setInstanceWallet(address walletAddress) external;
    function setRiskpoolWallet(uint256 riskpoolId, address walletAddress) external;  
    function setProductToken(uint256 productId, address erc20Address) external; 

    function setPremiumFees(ITreasury.FeeSpecification calldata feeSpec) external;
    function setCapitalFees(ITreasury.FeeSpecification calldata feeSpec) external;
    
    function createFeeSpecification(
        uint256 componentId,
        uint256 fixedFee,
        uint256 fractionalFee,
        bytes calldata feeCalculationData
    ) external view returns(ITreasury.FeeSpecification memory);


}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "../components/IComponent.sol";
import "../modules/IBundle.sol";
import "../modules/IPolicy.sol";
import "../modules/IPool.sol";
import "../tokens/IBundleToken.sol";
import "./IComponentOwnerService.sol";
import "./IInstanceOperatorService.sol";
import "./IOracleService.sol";
import "./IProductService.sol";
import "./IRiskpoolService.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IInstanceService {

    // instance
    function getChainId() external view returns(uint256 chainId);
    function getChainName() external view returns(string memory chainName);
    function getInstanceId() external view returns(bytes32 instanceId);
    function getInstanceOperator() external view returns(address instanceOperator);

    // registry
    function getComponentOwnerService() external view returns(IComponentOwnerService service);
    function getInstanceOperatorService() external view returns(IInstanceOperatorService service);
    function getOracleService() external view returns(IOracleService service);
    function getProductService() external view returns(IProductService service);
    function getRiskpoolService() external view returns(IRiskpoolService service);
    function contracts() external view returns (uint256 numberOfContracts);
    function contractName(uint256 idx) external view returns (bytes32 name);

    // access
    function getDefaultAdminRole() external view returns(bytes32 role);
    function getProductOwnerRole() external view returns(bytes32 role);
    function getOracleProviderRole() external view returns(bytes32 role);
    function getRiskpoolKeeperRole() external view returns(bytes32 role);
    function hasRole(bytes32 role, address principal) external view returns (bool roleIsAssigned);    

    // component
    function products() external view returns(uint256 numberOfProducts);
    function oracles() external view returns(uint256 numberOfOracles);
    function riskpools() external view returns(uint256 numberOfRiskpools);

    function getComponentId(address componentAddress) external view returns(uint256 componentId);
    function getComponent(uint256 componentId) external view returns(IComponent component);
    function getComponentType(uint256 componentId) external view returns(IComponent.ComponentType componentType);
    function getComponentState(uint256 componentId) external view returns(IComponent.ComponentState componentState);

    // service staking
    function getStakingRequirements(uint256 componentId) external view returns(bytes memory data);
    function getStakedAssets(uint256 componentId) external view returns(bytes memory data);

    // riskpool
    function getRiskpool(uint256 riskpoolId) external view returns(IPool.Pool memory riskPool);
    function getFullCollateralizationLevel() external view returns (uint256);
    function getCapital(uint256 riskpoolId) external view returns(uint256 capitalAmount);
    function getTotalValueLocked(uint256 riskpoolId) external view returns(uint256 totalValueLockedAmount);
    function getCapacity(uint256 riskpoolId) external view returns(uint256 capacityAmount);
    function getBalance(uint256 riskpoolId) external view returns(uint256 balanceAmount);

    function activeBundles(uint256 riskpoolId) external view returns(uint256 numberOfActiveBundles);
    function getActiveBundleId(uint256 riskpoolId, uint256 bundleIdx) external view returns(uint256 bundleId);
    function getMaximumNumberOfActiveBundles(uint256 riskpoolId) external view returns(uint256 maximumNumberOfActiveBundles);

    // bundles
    function getBundleToken() external view returns(IBundleToken token);
    function bundles() external view returns(uint256 numberOfBundles);
    function getBundle(uint256 bundleId) external view returns(IBundle.Bundle memory bundle);
    function unburntBundles(uint256 riskpoolId) external view returns(uint256 numberOfUnburntBundles);

    // policy
    function processIds() external view returns(uint256 numberOfProcessIds);
    function getMetadata(bytes32 processId) external view returns(IPolicy.Metadata memory metadata);
    function getApplication(bytes32 processId) external view returns(IPolicy.Application memory application);
    function getPolicy(bytes32 processId) external view returns(IPolicy.Policy memory policy);
    function claims(bytes32 processId) external view returns(uint256 numberOfClaims);
    function payouts(bytes32 processId) external view returns(uint256 numberOfPayouts);

    function getClaim(bytes32 processId, uint256 claimId) external view returns (IPolicy.Claim memory claim);
    function getPayout(bytes32 processId, uint256 payoutId) external view returns (IPolicy.Payout memory payout);

    // treasury
    function getTreasuryAddress() external view returns(address treasuryAddress);
 
    function getInstanceWallet() external view returns(address walletAddress);
    function getRiskpoolWallet(uint256 riskpoolId) external view returns(address walletAddress);
 
    function getComponentToken(uint256 componentId) external view returns(IERC20 token);
    function getFeeFractionFullUnit() external view returns(uint256 fullUnit);

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IOracleService {

    function respond(uint256 requestId, bytes calldata data) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IProductService {

    function newApplication(
        address owner,
        uint256 premiumAmount,
        uint256 sumInsuredAmount,
        bytes calldata metaData, 
        bytes calldata applicationData 
    ) external returns(bytes32 processId);

    function collectPremium(bytes32 processId, uint256 amount) external
        returns(
            bool success,
            uint256 feeAmount,
            uint256 netPremiumAmount
        );
    
    function adjustPremiumSumInsured(
        bytes32 processId, 
        uint256 expectedPremiumAmount,
        uint256 sumInsuredAmount
    ) external;

    function revoke(bytes32 processId) external;
    function underwrite(bytes32 processId) external returns(bool success);
    function decline(bytes32 processId) external;
    function expire(bytes32 processId) external;
    function close(bytes32 processId) external;

    function newClaim(
        bytes32 processId, 
        uint256 claimAmount,
        bytes calldata data
    ) external returns(uint256 claimId);

    function confirmClaim(
        bytes32 processId, 
        uint256 claimId, 
        uint256 confirmedAmount
    ) external;

    function declineClaim(bytes32 processId, uint256 claimId) external;
    function closeClaim(bytes32 processId, uint256 claimId) external;

    function newPayout(
        bytes32 processId, 
        uint256 claimId, 
        uint256 amount,
        bytes calldata data
    ) external returns(uint256 payoutId);

    function processPayout(bytes32 processId, uint256 payoutId) external
        returns(
            uint256 feeAmount,
            uint256 netPayoutAmount
        );

    function request(
        bytes32 processId,
        bytes calldata data,
        string calldata callbackMethodName,
        address callbackContractAddress,
        uint256 responsibleOracleId
    ) external returns(uint256 requestId);

    function cancelRequest(uint256 requestId) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IRiskpoolService {

    function registerRiskpool(
        address wallet,
        address erc20Token,
        uint256 collateralization, 
        uint256 sumOfSumInsuredCap
    ) external;

    function createBundle(address owner_, bytes calldata filter_, uint256 amount_) external returns(uint256 bundleId);
    function fundBundle(uint256 bundleId, uint256 amount) external returns(uint256 netAmount);
    function defundBundle(uint256 bundleId, uint256 amount) external returns(uint256 netAmount);

    function lockBundle(uint256 bundleId) external;
    function unlockBundle(uint256 bundleId) external;
    function closeBundle(uint256 bundleId) external;
    function burnBundle(uint256 bundleId) external;

    function collateralizePolicy(uint256 bundleId, bytes32 processId, uint256 collateralAmount) external;
    function processPremium(uint256 bundleId, bytes32 processId, uint256 amount) external;
    function processPayout(uint256 bundleId, bytes32 processId, uint256 amount) external;
    function releasePolicy(uint256 bundleId, bytes32 processId) external returns(uint256 collateralAmount);

    function setMaximumNumberOfActiveBundles(uint256 riskpoolId, uint256 maxNumberOfActiveBundles) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IBundleToken is
    IERC721
{
    event LogBundleTokenMinted(uint256 bundleId, uint256 tokenId, address tokenOwner);
    event LogBundleTokenBurned(uint256 bundleId, uint256 tokenId);   

    function burned(uint tokenId) external view returns(bool isBurned);
    function exists(uint256 tokenId) external view returns(bool doesExist);
    function getBundleId(uint256 tokenId) external view returns(uint256 bundleId);
    function totalSupply() external view returns(uint256 tokenCount);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {CBOR, Buffer} from "../vendor/solidity-cborutils/2.0.0/CBOR.sol";

/**
 * @title Library for Chainlink Functions
 */
library Functions {
  uint256 internal constant DEFAULT_BUFFER_SIZE = 256;

  using CBOR for Buffer.buffer;

  enum Location {
    Inline,
    Remote
  }

  enum CodeLanguage {
    JavaScript
    // In future version we may add other languages
  }

  struct Request {
    Location codeLocation;
    Location secretsLocation;
    CodeLanguage language;
    string source; // Source code for Location.Inline or url for Location.Remote
    bytes secrets; // Encrypted secrets blob for Location.Inline or url for Location.Remote
    string[] args;
  }

  /**
   * @notice Encodes a Request to CBOR encoded bytes
   * @param self The request to encode
   * @return CBOR encoded bytes
   */
  function encodeCBOR(Request memory self) internal pure returns (bytes memory) {
    CBOR.CBORBuffer memory buffer;
    Buffer.init(buffer.buf, DEFAULT_BUFFER_SIZE);

    CBOR.writeString(buffer, "codeLocation");
    CBOR.writeUInt256(buffer, uint256(self.codeLocation));

    CBOR.writeString(buffer, "language");
    CBOR.writeUInt256(buffer, uint256(self.language));

    CBOR.writeString(buffer, "source");
    CBOR.writeString(buffer, self.source);

    if (self.args.length > 0) {
      CBOR.writeString(buffer, "args");
      CBOR.startArray(buffer);
      for (uint256 i = 0; i < self.args.length; i++) {
        CBOR.writeString(buffer, self.args[i]);
      }
      CBOR.endSequence(buffer);
    }

    if (self.secrets.length > 0) {
      if (self.secretsLocation == Location.Inline) {
        revert("ERROR:NoInlineSecrets");
      }
      CBOR.writeString(buffer, "secretsLocation");
      CBOR.writeUInt256(buffer, uint256(self.secretsLocation));
      CBOR.writeString(buffer, "secrets");
      CBOR.writeBytes(buffer, self.secrets);
    }

    return buffer.buf.buf;
  }

  /**
   * @notice Initializes a Chainlink Functions Request
   * @dev Sets the codeLocation and code on the request
   * @param self The uninitialized request
   * @param location The user provided source code location
   * @param language The programming language of the user code
   * @param source The user provided source code or a url
   */
  function initializeRequest(
    Request memory self,
    Location location,
    CodeLanguage language,
    string memory source
  ) internal pure {
    if (bytes(source).length == 0) revert("ERROR:EmptySource");

    self.codeLocation = location;
    self.language = language;
    self.source = source;
  }

  /**
   * @notice Initializes a Chainlink Functions Request
   * @dev Simplified version of initializeRequest for PoC
   * @param self The uninitialized request
   * @param javaScriptSource The user provided JS code (must not be empty)
   */
  function initializeRequestForInlineJavaScript(Request memory self, string memory javaScriptSource) internal pure {
    initializeRequest(self, Location.Inline, CodeLanguage.JavaScript, javaScriptSource);
  }

  /**
   * @notice Adds Remote user encrypted secrets to a Request
   * @param self The initialized request
   * @param encryptedSecretsURLs Encrypted comma-separated string of URLs pointing to off-chain secrets
   */
  function addRemoteSecrets(Request memory self, bytes memory encryptedSecretsURLs) internal pure {
    if (encryptedSecretsURLs.length == 0) revert("ERROR:EmptySecrets");

    self.secretsLocation = Location.Remote;
    self.secrets = encryptedSecretsURLs;
  }

  /**
   * @notice Adds args for the user run function
   * @param self The initialized request
   * @param args The array of args (must not be empty)
   */
  function addArgs(Request memory self, string[] memory args) internal pure {
    if (args.length == 0) revert("ERROR:EmptyArgs");

    self.args = args;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Functions.sol";
import "../interfaces/FunctionsClientInterface.sol";
import "../interfaces/FunctionsOracleInterface.sol";

/**
 * @title The Chainlink Functions client contract
 * @notice Contract writers can inherit this contract in order to create Chainlink Functions requests
 */
abstract contract FunctionsClient is FunctionsClientInterface {
  FunctionsOracleInterface internal s_oracle;
  mapping(bytes32 => address) internal s_pendingRequests;

  event RequestSent(bytes32 indexed id);
  event RequestFulfilled(bytes32 indexed id);

  constructor(address oracle) {
    setOracle(oracle);
  }

  /**
   * @inheritdoc FunctionsClientInterface
   */
  function getDONPublicKey() external view override returns (bytes memory) {
    return s_oracle.getDONPublicKey();
  }

  /**
   * @notice Estimate the total cost that will be charged to a subscription to make a request: gas re-imbursement, plus DON fee, plus Registry fee
   * @param req The initialized Functions.Request
   * @param subscriptionId The subscription ID
   * @param gasLimit gas limit for the fulfillment callback
   * @return billedCost Cost in Juels (1e18) of LINK
   */
  function estimateCost(
    Functions.Request memory req,
    uint64 subscriptionId,
    uint32 gasLimit,
    uint256 gasPrice
  ) public view returns (uint96) {
    return s_oracle.estimateCost(subscriptionId, Functions.encodeCBOR(req), gasLimit, gasPrice);
  }

  /**
   * @notice Sends a Chainlink Functions request to the stored oracle address
   * @param req The initialized Functions.Request
   * @param subscriptionId The subscription ID
   * @param gasLimit gas limit for the fulfillment callback
   * @return requestId The generated request ID
   */
  function sendRequest(
    Functions.Request memory req,
    uint64 subscriptionId,
    uint32 gasLimit
  ) internal returns (bytes32) {
    bytes32 requestId = s_oracle.sendRequest(subscriptionId, Functions.encodeCBOR(req), gasLimit);
    s_pendingRequests[requestId] = s_oracle.getRegistry();
    emit RequestSent(requestId);
    return requestId;
  }

  /**
   * @notice User defined function to handle a response
   * @param requestId The request ID, returned by sendRequest()
   * @param response Aggregated response from the user code
   * @param err Aggregated error from the user code or from the execution pipeline
   * Either response or error parameter will be set, but never both
   */
  function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal virtual;

  /**
   * @inheritdoc FunctionsClientInterface
   */
  function handleOracleFulfillment(
    bytes32 requestId,
    bytes memory response,
    bytes memory err
  ) external override recordChainlinkFulfillment(requestId) {
    fulfillRequest(requestId, response, err);
  }

  /**
   * @notice Sets the stored Oracle address
   * @param oracle The address of Functions Oracle contract
   */
  function setOracle(address oracle) internal {
    s_oracle = FunctionsOracleInterface(oracle);
  }

  /**
   * @notice Gets the stored address of the oracle contract
   * @return The address of the oracle contract
   */
  function getChainlinkOracleAddress() internal view returns (address) {
    return address(s_oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param oracleAddress The address of the oracle contract that will fulfill the request
   * @param requestId The request ID used for the response
   */
  function addExternalRequest(address oracleAddress, bytes32 requestId) internal notPendingRequest(requestId) {
    s_pendingRequests[requestId] = oracleAddress;
  }

  /**
   * @dev Reverts if the sender is not the oracle that serviced the request.
   * Emits RequestFulfilled event.
   * @param requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(bytes32 requestId) {
    if (msg.sender != s_pendingRequests[requestId]) {
      revert("ERROR:SenderIsNotRegistry");
    }
    delete s_pendingRequests[requestId];
    emit RequestFulfilled(requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param requestId The request ID for fulfillment
   */
  modifier notPendingRequest(bytes32 requestId) {
    if (s_pendingRequests[requestId] != address(0)) {
      revert("ERROR:RequestIsAlreadyPending");
    }
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
 * @title Chainlink Functions billing subscription registry interface.
 */
interface FunctionsBillingRegistryInterface {
  struct RequestBilling {
    // a unique subscription ID allocated by billing system,
    uint64 subscriptionId;
    // the client contract that initiated the request to the DON
    // to use the subscription it must be added as a consumer on the subscription
    address client;
    // customer specified gas limit for the fulfillment callback
    uint32 gasLimit;
    // the expected gas price used to execute the transaction
    uint256 gasPrice;
  }

  enum FulfillResult {
    USER_SUCCESS,
    USER_ERROR,
    INVALID_REQUEST_ID
  }

  /**
   * @notice Get configuration relevant for making requests
   * @return uint32 global max for request gas limit
   * @return address[] list of registered DONs
   */
  function getRequestConfig() external view returns (uint32, address[] memory);

  /**
   * @notice Determine the charged fee that will be paid to the Registry owner
   * @param data Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
   * @param billing The request's billing configuration
   * @return fee Cost in Juels (1e18) of LINK
   */
  function getRequiredFee(
    bytes calldata data,
    FunctionsBillingRegistryInterface.RequestBilling memory billing
  ) external view returns (uint96);

  /**
   * @notice Estimate the total cost to make a request: gas re-imbursement, plus DON fee, plus Registry fee
   * @param gasLimit Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
   * @param gasPrice The request's billing configuration
   * @param donFee Fee charged by the DON that is paid to Oracle Node
   * @param registryFee Fee charged by the DON that is paid to Oracle Node
   * @return costEstimate Cost in Juels (1e18) of LINK
   */
  function estimateCost(
    uint32 gasLimit,
    uint256 gasPrice,
    uint96 donFee,
    uint96 registryFee
  ) external view returns (uint96);

  /**
   * @notice Initiate the billing process for an Functions request
   * @param data Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
   * @param billing Billing configuration for the request
   * @return requestId - A unique identifier of the request. Can be used to match a request to a response in fulfillRequest.
   * @dev Only callable by a node that has been approved on the Registry
   */
  function startBilling(bytes calldata data, RequestBilling calldata billing) external returns (bytes32);

  /**
   * @notice Finalize billing process for an Functions request by sending a callback to the Client contract and then charging the subscription
   * @param requestId identifier for the request that was generated by the Registry in the beginBilling commitment
   * @param response response data from DON consensus
   * @param err error from DON consensus
   * @param transmitter the Oracle who sent the report
   * @param signers the Oracles who had a part in generating the report
   * @param signerCount the number of signers on the report
   * @param reportValidationGas the amount of gas used for the report validation. Cost is split by all fulfillments on the report.
   * @param initialGas the initial amount of gas that should be used as a baseline to charge the single fulfillment for execution cost
   * @return result fulfillment result
   * @dev Only callable by a node that has been approved on the Registry
   * @dev simulated offchain to determine if sufficient balance is present to fulfill the request
   */
  function fulfillAndBill(
    bytes32 requestId,
    bytes calldata response,
    bytes calldata err,
    address transmitter,
    address[31] memory signers, // 31 comes from OCR2Abstract.sol's maxNumOracles constant
    uint8 signerCount,
    uint256 reportValidationGas,
    uint256 initialGas
  ) external returns (FulfillResult);

  /**
   * @notice Gets subscription owner.
   * @param subscriptionId - ID of the subscription
   * @return owner - owner of the subscription.
   */
  function getSubscriptionOwner(uint64 subscriptionId) external view returns (address owner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
 * @title Chainlink Functions client interface.
 */
interface FunctionsClientInterface {
  /**
   * @notice Returns the DON's secp256k1 public key used to encrypt secrets
   * @dev All Oracles nodes have the corresponding private key
   * needed to decrypt the secrets encrypted with the public key
   * @return publicKey DON's public key
   */
  function getDONPublicKey() external view returns (bytes memory);

  /**
   * @notice Chainlink Functions response handler called by the designated transmitter node in an OCR round.
   * @param requestId The requestId returned by FunctionsClient.sendRequest().
   * @param response Aggregated response from the user code.
   * @param err Aggregated error either from the user code or from the execution pipeline.
   * Either response or error parameter will be set, but never both.
   */
  function handleOracleFulfillment(bytes32 requestId, bytes memory response, bytes memory err) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./FunctionsBillingRegistryInterface.sol";

/**
 * @title Chainlink Functions oracle interface.
 */
interface FunctionsOracleInterface {
  /**
   * @notice Gets the stored billing registry address
   * @return registryAddress The address of Chainlink Functions billing registry contract
   */
  function getRegistry() external view returns (address);

  /**
   * @notice Sets the stored billing registry address
   * @param registryAddress The new address of Chainlink Functions billing registry contract
   */
  function setRegistry(address registryAddress) external;

  /**
   * @notice Returns the DON's secp256k1 public key that is used to encrypt secrets
   * @dev All nodes on the DON have the corresponding private key
   * needed to decrypt the secrets encrypted with the public key
   * @return publicKey the DON's public key
   */
  function getDONPublicKey() external view returns (bytes memory);

  /**
   * @notice Sets DON's secp256k1 public key used to encrypt secrets
   * @dev Used to rotate the key
   * @param donPublicKey The new public key
   */
  function setDONPublicKey(bytes calldata donPublicKey) external;

  /**
   * @notice Sets a per-node secp256k1 public key used to encrypt secrets for that node
   * @dev Callable only by contract owner and DON members
   * @param node node's address
   * @param publicKey node's public key
   */
  function setNodePublicKey(address node, bytes calldata publicKey) external;

  /**
   * @notice Deletes node's public key
   * @dev Callable only by contract owner or the node itself
   * @param node node's address
   */
  function deleteNodePublicKey(address node) external;

  /**
   * @notice Return two arrays of equal size containing DON members' addresses and their corresponding
   * public keys (or empty byte arrays if per-node key is not defined)
   */
  function getAllNodePublicKeys() external view returns (address[] memory, bytes[] memory);

  /**
   * @notice Determine the fee charged by the DON that will be split between signing Node Operators for servicing the request
   * @param data Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
   * @param billing The request's billing configuration
   * @return fee Cost in Juels (1e18) of LINK
   */
  function getRequiredFee(
    bytes calldata data,
    FunctionsBillingRegistryInterface.RequestBilling calldata billing
  ) external view returns (uint96);

  /**
   * @notice Estimate the total cost that will be charged to a subscription to make a request: gas re-imbursement, plus DON fee, plus Registry fee
   * @param subscriptionId A unique subscription ID allocated by billing system,
   * a client can make requests from different contracts referencing the same subscription
   * @param data Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
   * @param gasLimit Gas limit for the fulfillment callback
   * @return billedCost Cost in Juels (1e18) of LINK
   */
  function estimateCost(
    uint64 subscriptionId,
    bytes calldata data,
    uint32 gasLimit,
    uint256 gasPrice
  ) external view returns (uint96);

  /**
   * @notice Sends a request (encoded as data) using the provided subscriptionId
   * @param subscriptionId A unique subscription ID allocated by billing system,
   * a client can make requests from different contracts referencing the same subscription
   * @param data Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
   * @param gasLimit Gas limit for the fulfillment callback
   * @return requestId A unique request identifier (unique per DON)
   */
  function sendRequest(uint64 subscriptionId, bytes calldata data, uint32 gasLimit) external returns (bytes32);
}

// SPDX-License-Identifier: BSD-2-Clause
pragma solidity ^0.8.2;

/**
 * @dev A library for working with mutable byte buffers in Solidity.
 *
 * Byte buffers are mutable and expandable, and provide a variety of primitives
 * for appending to them. At any time you can fetch a bytes object containing the
 * current contents of the buffer. The bytes object should not be stored between
 * operations, as it may change due to resizing of the buffer.
 */
library Buffer {
  /**
   * @dev Represents a mutable buffer. Buffers have a current value (buf) and
   *      a capacity. The capacity may be longer than the current value, in
   *      which case it can be extended without the need to allocate more memory.
   */
  struct buffer {
    bytes buf;
    uint256 capacity;
  }

  /**
   * @dev Initializes a buffer with an initial capacity.
   * @param buf The buffer to initialize.
   * @param capacity The number of bytes of space to allocate the buffer.
   * @return The buffer, for chaining.
   */
  function init(buffer memory buf, uint256 capacity) internal pure returns (buffer memory) {
    if (capacity % 32 != 0) {
      capacity += 32 - (capacity % 32);
    }
    // Allocate space for the buffer data
    buf.capacity = capacity;
    assembly {
      let ptr := mload(0x40)
      mstore(buf, ptr)
      mstore(ptr, 0)
      let fpm := add(32, add(ptr, capacity))
      if lt(fpm, ptr) {
        revert(0, 0)
      }
      mstore(0x40, fpm)
    }
    return buf;
  }

  /**
   * @dev Initializes a new buffer from an existing bytes object.
   *      Changes to the buffer may mutate the original value.
   * @param b The bytes object to initialize the buffer with.
   * @return A new buffer.
   */
  function fromBytes(bytes memory b) internal pure returns (buffer memory) {
    buffer memory buf;
    buf.buf = b;
    buf.capacity = b.length;
    return buf;
  }

  function resize(buffer memory buf, uint256 capacity) private pure {
    bytes memory oldbuf = buf.buf;
    init(buf, capacity);
    append(buf, oldbuf);
  }

  /**
   * @dev Sets buffer length to 0.
   * @param buf The buffer to truncate.
   * @return The original buffer, for chaining..
   */
  function truncate(buffer memory buf) internal pure returns (buffer memory) {
    assembly {
      let bufptr := mload(buf)
      mstore(bufptr, 0)
    }
    return buf;
  }

  /**
   * @dev Appends len bytes of a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function append(buffer memory buf, bytes memory data, uint256 len) internal pure returns (buffer memory) {
    require(len <= data.length);

    uint256 off = buf.buf.length;
    uint256 newCapacity = off + len;
    if (newCapacity > buf.capacity) {
      resize(buf, newCapacity * 2);
    }

    uint256 dest;
    uint256 src;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Start address = buffer address + offset + sizeof(buffer length)
      dest := add(add(bufptr, 32), off)
      // Update buffer length if we're extending it
      if gt(newCapacity, buflen) {
        mstore(bufptr, newCapacity)
      }
      src := add(data, 32)
    }

    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    unchecked {
      uint256 mask = (256 ** (32 - len)) - 1;
      assembly {
        let srcpart := and(mload(src), not(mask))
        let destpart := and(mload(dest), mask)
        mstore(dest, or(destpart, srcpart))
      }
    }

    return buf;
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
    return append(buf, data, data.length);
  }

  /**
   * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendUint8(buffer memory buf, uint8 data) internal pure returns (buffer memory) {
    uint256 off = buf.buf.length;
    uint256 offPlusOne = off + 1;
    if (off >= buf.capacity) {
      resize(buf, offPlusOne * 2);
    }

    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + sizeof(buffer length) + off
      let dest := add(add(bufptr, off), 32)
      mstore8(dest, data)
      // Update buffer length if we extended it
      if gt(offPlusOne, mload(bufptr)) {
        mstore(bufptr, offPlusOne)
      }
    }

    return buf;
  }

  /**
   * @dev Appends len bytes of bytes32 to a buffer. Resizes if doing so would
   *      exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @param len The number of bytes to write (left-aligned).
   * @return The original buffer, for chaining.
   */
  function append(buffer memory buf, bytes32 data, uint256 len) private pure returns (buffer memory) {
    uint256 off = buf.buf.length;
    uint256 newCapacity = len + off;
    if (newCapacity > buf.capacity) {
      resize(buf, newCapacity * 2);
    }

    unchecked {
      uint256 mask = (256 ** len) - 1;
      // Right-align data
      data = data >> (8 * (32 - len));
      assembly {
        // Memory address of the buffer data
        let bufptr := mload(buf)
        // Address = buffer address + sizeof(buffer length) + newCapacity
        let dest := add(bufptr, newCapacity)
        mstore(dest, or(and(mload(dest), not(mask)), data))
        // Update buffer length if we extended it
        if gt(newCapacity, mload(bufptr)) {
          mstore(bufptr, newCapacity)
        }
      }
    }
    return buf;
  }

  /**
   * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chhaining.
   */
  function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
    return append(buf, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
    return append(buf, data, 32);
  }

  /**
   * @dev Appends a byte to the end of the buffer. Resizes if doing so would
   *      exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @param len The number of bytes to write (right-aligned).
   * @return The original buffer.
   */
  function appendInt(buffer memory buf, uint256 data, uint256 len) internal pure returns (buffer memory) {
    uint256 off = buf.buf.length;
    uint256 newCapacity = len + off;
    if (newCapacity > buf.capacity) {
      resize(buf, newCapacity * 2);
    }

    uint256 mask = (256 ** len) - 1;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + sizeof(buffer length) + newCapacity
      let dest := add(bufptr, newCapacity)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(newCapacity, mload(bufptr)) {
        mstore(bufptr, newCapacity)
      }
    }
    return buf;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../../@ensdomains/buffer/0.1.0/Buffer.sol";

/**
 * @dev A library for populating CBOR encoded payload in Solidity.
 *
 * https://datatracker.ietf.org/doc/html/rfc7049
 *
 * The library offers various write* and start* methods to encode values of different types.
 * The resulted buffer can be obtained with data() method.
 * Encoding of primitive types is staightforward, whereas encoding of sequences can result
 * in an invalid CBOR if start/write/end flow is violated.
 * For the purpose of gas saving, the library does not verify start/write/end flow internally,
 * except for nested start/end pairs.
 */

library CBOR {
  using Buffer for Buffer.buffer;

  struct CBORBuffer {
    Buffer.buffer buf;
    uint256 depth;
  }

  uint8 private constant MAJOR_TYPE_INT = 0;
  uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 private constant MAJOR_TYPE_BYTES = 2;
  uint8 private constant MAJOR_TYPE_STRING = 3;
  uint8 private constant MAJOR_TYPE_ARRAY = 4;
  uint8 private constant MAJOR_TYPE_MAP = 5;
  uint8 private constant MAJOR_TYPE_TAG = 6;
  uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

  uint8 private constant TAG_TYPE_BIGNUM = 2;
  uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

  uint8 private constant CBOR_FALSE = 20;
  uint8 private constant CBOR_TRUE = 21;
  uint8 private constant CBOR_NULL = 22;
  uint8 private constant CBOR_UNDEFINED = 23;

  function create(uint256 capacity) internal pure returns (CBORBuffer memory cbor) {
    Buffer.init(cbor.buf, capacity);
    cbor.depth = 0;
    return cbor;
  }

  function data(CBORBuffer memory buf) internal pure returns (bytes memory) {
    require(buf.depth == 0, "Invalid CBOR");
    return buf.buf.buf;
  }

  function writeUInt256(CBORBuffer memory buf, uint256 value) internal pure {
    buf.buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
    writeBytes(buf, abi.encode(value));
  }

  function writeInt256(CBORBuffer memory buf, int256 value) internal pure {
    if (value < 0) {
      buf.buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
      writeBytes(buf, abi.encode(uint256(-1 - value)));
    } else {
      writeUInt256(buf, uint256(value));
    }
  }

  function writeUInt64(CBORBuffer memory buf, uint64 value) internal pure {
    writeFixedNumeric(buf, MAJOR_TYPE_INT, value);
  }

  function writeInt64(CBORBuffer memory buf, int64 value) internal pure {
    if (value >= 0) {
      writeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(value));
    } else {
      writeFixedNumeric(buf, MAJOR_TYPE_NEGATIVE_INT, uint64(-1 - value));
    }
  }

  function writeBytes(CBORBuffer memory buf, bytes memory value) internal pure {
    writeFixedNumeric(buf, MAJOR_TYPE_BYTES, uint64(value.length));
    buf.buf.append(value);
  }

  function writeString(CBORBuffer memory buf, string memory value) internal pure {
    writeFixedNumeric(buf, MAJOR_TYPE_STRING, uint64(bytes(value).length));
    buf.buf.append(bytes(value));
  }

  function writeBool(CBORBuffer memory buf, bool value) internal pure {
    writeContentFree(buf, value ? CBOR_TRUE : CBOR_FALSE);
  }

  function writeNull(CBORBuffer memory buf) internal pure {
    writeContentFree(buf, CBOR_NULL);
  }

  function writeUndefined(CBORBuffer memory buf) internal pure {
    writeContentFree(buf, CBOR_UNDEFINED);
  }

  function startArray(CBORBuffer memory buf) internal pure {
    writeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
    buf.depth += 1;
  }

  function startFixedArray(CBORBuffer memory buf, uint64 length) internal pure {
    writeDefiniteLengthType(buf, MAJOR_TYPE_ARRAY, length);
  }

  function startMap(CBORBuffer memory buf) internal pure {
    writeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
    buf.depth += 1;
  }

  function startFixedMap(CBORBuffer memory buf, uint64 length) internal pure {
    writeDefiniteLengthType(buf, MAJOR_TYPE_MAP, length);
  }

  function endSequence(CBORBuffer memory buf) internal pure {
    writeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
    buf.depth -= 1;
  }

  function writeKVString(CBORBuffer memory buf, string memory key, string memory value) internal pure {
    writeString(buf, key);
    writeString(buf, value);
  }

  function writeKVBytes(CBORBuffer memory buf, string memory key, bytes memory value) internal pure {
    writeString(buf, key);
    writeBytes(buf, value);
  }

  function writeKVUInt256(CBORBuffer memory buf, string memory key, uint256 value) internal pure {
    writeString(buf, key);
    writeUInt256(buf, value);
  }

  function writeKVInt256(CBORBuffer memory buf, string memory key, int256 value) internal pure {
    writeString(buf, key);
    writeInt256(buf, value);
  }

  function writeKVUInt64(CBORBuffer memory buf, string memory key, uint64 value) internal pure {
    writeString(buf, key);
    writeUInt64(buf, value);
  }

  function writeKVInt64(CBORBuffer memory buf, string memory key, int64 value) internal pure {
    writeString(buf, key);
    writeInt64(buf, value);
  }

  function writeKVBool(CBORBuffer memory buf, string memory key, bool value) internal pure {
    writeString(buf, key);
    writeBool(buf, value);
  }

  function writeKVNull(CBORBuffer memory buf, string memory key) internal pure {
    writeString(buf, key);
    writeNull(buf);
  }

  function writeKVUndefined(CBORBuffer memory buf, string memory key) internal pure {
    writeString(buf, key);
    writeUndefined(buf);
  }

  function writeKVMap(CBORBuffer memory buf, string memory key) internal pure {
    writeString(buf, key);
    startMap(buf);
  }

  function writeKVArray(CBORBuffer memory buf, string memory key) internal pure {
    writeString(buf, key);
    startArray(buf);
  }

  function writeFixedNumeric(CBORBuffer memory buf, uint8 major, uint64 value) private pure {
    if (value <= 23) {
      buf.buf.appendUint8(uint8((major << 5) | value));
    } else if (value <= 0xFF) {
      buf.buf.appendUint8(uint8((major << 5) | 24));
      buf.buf.appendInt(value, 1);
    } else if (value <= 0xFFFF) {
      buf.buf.appendUint8(uint8((major << 5) | 25));
      buf.buf.appendInt(value, 2);
    } else if (value <= 0xFFFFFFFF) {
      buf.buf.appendUint8(uint8((major << 5) | 26));
      buf.buf.appendInt(value, 4);
    } else {
      buf.buf.appendUint8(uint8((major << 5) | 27));
      buf.buf.appendInt(value, 8);
    }
  }

  function writeIndefiniteLengthType(CBORBuffer memory buf, uint8 major) private pure {
    buf.buf.appendUint8(uint8((major << 5) | 31));
  }

  function writeDefiniteLengthType(CBORBuffer memory buf, uint8 major, uint64 length) private pure {
    writeFixedNumeric(buf, major, length);
  }

  function writeContentFree(CBORBuffer memory buf, uint8 value) private pure {
    buf.buf.appendUint8(uint8((MAJOR_TYPE_CONTENT_FREE << 5) | value));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../strings.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@etherisc/gif-interface/contracts/components/Oracle.sol";
import {Functions, FunctionsClient} from "./../dev/functions/FunctionsClient.sol";
//import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

contract RainOracleCLFunctions is 
    Oracle, 
    FunctionsClient
{
    using strings for bytes32;
    using Functions for Functions.Request;

    mapping(bytes32 /* Chainlink request ID */ => uint256 /* GIF request ID */) public gifRequests;
    uint64 private subscriptionId;
    uint32 private gasLimit;

    //TODO: remove after testing
    bytes32 public latestRequestId;
    bytes public latestResponse;
    bytes public latestError;

    event LogRainRequest(uint256 requestId, bytes32 chainlinkRequestId);
    
    event LogRainFulfill(
        uint256 requestId, 
        bytes32 chainlinkRequestId, 
        uint256 prec,
        uint256 precDays
    );

    event OCRResponse(bytes32 indexed requestId, bytes result, bytes err);

    constructor(
        bytes32 _name,
        address _registry,
        address _chainLinkOperator,
        uint64 _subscriptionId,
        uint32 _gasLimit
    )
        Oracle(_name, _registry)
        FunctionsClient(_chainLinkOperator)
    {
        subscriptionId = _subscriptionId;
        gasLimit = _gasLimit;
    }

    function request(uint256 gifRequestId, bytes calldata input)
        external override
        onlyQuery
    {
        
        (
            uint256 startDate, 
            uint256 endDate, 
            int256 lat,
            int256 lng,
            uint256 coordMultiplier,
            uint256 precMultiplier,
            bytes memory secrets,
            string memory source
        ) = abi.decode(input, (uint256, uint256, int256, int256, uint256, uint256, bytes, string));

        Functions.Request memory req;
        req.initializeRequest(Functions.Location.Inline, Functions.CodeLanguage.JavaScript, source);

        if (secrets.length > 0) {
            req.addRemoteSecrets(secrets);
        }

        string[] memory args = prepareArgs(startDate, endDate, lat, lng, coordMultiplier, precMultiplier);
        req.addArgs(args);

        bytes32 chainlinkRequestId = sendRequest(req, subscriptionId, gasLimit);

        latestRequestId = chainlinkRequestId;

        gifRequests[chainlinkRequestId] = gifRequestId;
        emit LogRainRequest(gifRequestId, chainlinkRequestId);
    }

    function prepareArgs(
        uint256 startDate,
        uint256 endDate,
        int256 lat,
        int256 lng,
        uint256 coordMultiplier,
        uint256 precMultiplier
    ) public pure returns (string[] memory) {
        string[] memory args = new string[](6);
        args[0] = Strings.toString(startDate);
        args[1] = Strings.toString(endDate);
        args[2] = string(abi.encodePacked(lat >= 0 ? "" : "-", Strings.toString(abs(lat))));
        args[3] = string(abi.encodePacked(lng >= 0 ? "" : "-", Strings.toString(abs(lng))));
        args[4] = Strings.toString(coordMultiplier);
        args[5] = Strings.toString(precMultiplier);
        return args;
    }

    function fulfillRequest(
        bytes32 chainlinkRequestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        latestResponse = response;
        latestError = err;

        emit OCRResponse(chainlinkRequestId, response, err);

        if (err.length == 0) {
            (uint256 prec, uint256 precDays) = abi.decode(response, (uint256, uint256));

            uint256 gifRequest = gifRequests[chainlinkRequestId];
            bytes memory data =  abi.encode(prec, precDays);
            _respond(gifRequest, data);

            delete gifRequests[chainlinkRequestId];
            emit LogRainFulfill(gifRequest, chainlinkRequestId, prec, precDays);
        }
    }

  function cancel(uint256 requestId)
        external override
        onlyOwner
    {
        // TODO mid/low priority
        // cancelChainlinkRequest(_requestId, _payment, _callbackFunctionId, _expiration);
    }


// only used for testing of chainlink operator
    function encodeRequestParameters(
        uint256 startDate, 
        uint256 endDate, 
        int256 lat,
        int256 lng,
        uint256 coordMultiplier,
        uint256 precMultiplier,
        bytes memory secrets,
        string memory source
    ) 
        external pure returns(bytes memory parameterData)
    {
        return abi.encode(
            startDate, 
            endDate,
            lat,
            lng,
            coordMultiplier,
            precMultiplier,
            secrets,
            source
        );
    }

    // only used for testing of chainlink operator
    function encodeFulfillParameters(
        bytes32 chainlinkRequestId, 
        uint256 precActual,
        uint256 precDays
    ) 
        external
        pure
        returns(bytes memory parameterData)
    {
        bytes memory response = abi.encode(precActual, precDays);

        return abi.encode(
            chainlinkRequestId, 
            response,
            ""
        );
    }

    /**
    * @notice Allows the Functions oracle address to be updated
    *
    * @param oracle New oracle address
    */
    function updateOracleAddress(address oracle) public onlyOwner {
        setOracle(oracle);
    }

    function addSimulatedRequestId(address oracleAddress, bytes32 requestId) public onlyOwner {
        addExternalRequest(oracleAddress, requestId);
    }

    function abs(int256 x) private pure returns (uint256) {
        return x >= 0 ? uint256(x) : uint256(-x);
    }

    function getCLFunctionsGasLimit() external view returns(uint32 clFunctionsgasLimit) {
        return gasLimit;
    }

    function getCLFunctionsSubscriptionId() external view returns(uint64 clFunctionsSubscriptionId) {
        return subscriptionId;
    }

}

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

pragma solidity ^0.8.2;

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = type(uint).max;
        if (len > 0) {
            mask = 256 ** (32 - len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (uint(self) & type(uint128).max == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (uint(self) & type(uint64).max == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (uint(self) & type(uint32).max == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (uint(self) & type(uint16).max == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (uint(self) & type(uint8).max == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint mask = type(uint).max; // 0xffff...
                if(shortest < 32) {
                  mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                unchecked {
                    uint diff = (a & mask) - (b & mask);
                    if (diff != 0)
                        return int(diff);
                }
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if(b < 0xE0) {
            l = 2;
        } else if(b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(uint i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}