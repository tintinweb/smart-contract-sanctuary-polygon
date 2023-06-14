// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.2;

import "Product.sol";


contract TerraGuardProduct is Product {
    // constants
    bytes32 public constant VERSION = "0.0.1";
    bytes32 public constant POLICY_FLOW = "PolicyDefaultFlow";

    uint256 public constant TYPE_5_PLUS = 5;
    uint256 public constant TYPE_7_PLUS = 7;

    // leads to %5 premiums on object value
    uint8 public constant COORD_DECIMALS = 4;
    uint24 public constant OFFSET_LAT = uint24(90 * 10 ** COORD_DECIMALS);
    uint24 public constant OFFSET_LONG = uint24(180 * 10 ** COORD_DECIMALS);

    // hold list of applications/policies for address
    mapping(address /* policyHolder */ => bytes32 [] /* processIds */) private _processIdsForHolder;

    // variables
    // TODO should be framework feature
    bytes32[] private _applications;

    // events
    event LogTerraGuardApplicationCreated(
        bytes32 processId,
        address policyHolder,
        uint256 premium,
        uint256 sumInsured,
        uint16 locationId,
        uint8 protectionType
    );

    event LogTerraGuardPolicyCreated(bytes32 processId);
    event LogTerraGuardPolicyExpired(bytes32 processId);

    event LogTerraGuardClaimConfirmed(
        bytes32 processId,
        uint256 claimId,
        uint256 payoutAmount
    );

    event LogTerraGuardPayoutExecuted(
        bytes32 processId,
        uint256 claimId,
        uint256 payoutId,
        uint256 payoutAmount
    );

    constructor(
        bytes32 productName,
        address token,
        uint256 riskpoolId,
        address registry
    )
        Product(productName, token, POLICY_FLOW, riskpoolId, registry)
    { }

    function applyForPolicy(
        uint8 protectionType,
        uint24 latitude,
        uint24 longitude,
        uint16 locationId,
        uint256 sumInsuredAmount,
        uint256 premiumAmount
    )
        external 
        returns (bytes32 processId)
    {

        // Create and underwrite new application
        address policyHolder = msg.sender;
        bytes memory metaData = "";
        bytes memory applicationData = encodeApplicationParametersToData(
            protectionType,
            latitude,
            longitude,
            locationId
        );

        processId = _newApplication(
            policyHolder,
            premiumAmount,
            sumInsuredAmount,
            metaData,
            applicationData
        );

        _applications.push(processId);
        _processIdsForHolder[policyHolder].push(processId);

        emit LogTerraGuardApplicationCreated(
            processId,
            policyHolder,
            premiumAmount,
            sumInsuredAmount,
            locationId,
            protectionType
        );
    }


    function underwrite(bytes32 processId)
        external
        onlyOwner
    {
        _underwrite(processId);

        emit LogTerraGuardPolicyCreated(processId);
    }


    function processIds(address policyHolder)
        external 
        view
        returns(uint256 numberOfProcessIds)
    {
        return _processIdsForHolder[policyHolder].length;
    }


    function getProcessId(address policyHolder, uint256 idx)
        external 
        view
        returns(bytes32 processId)
    {
        require(_processIdsForHolder[policyHolder].length > 0, "ERROR:DP-070:NO_POLICIES");
        return _processIdsForHolder[policyHolder][idx];
    }


    function applications()
        external
        view
        returns (uint256 numberOfApplications)
    {
        return _applications.length;
    }

    function getApplicationId(
        uint256 idx
    ) external view returns (bytes32 processId) {
        require(
            idx < _applications.length,
            "ERROR:TGP-001:APPLICATION_INDEX_TOO_LARGE"
        );
        return _applications[idx];
    }

    function decodeApplicationParameterFromData(
        bytes memory data
    )
        public 
        pure 
        returns (
            uint8 protectionType,
            uint24 latitude,
            uint24 longitude,
            uint16 locationId
        )
    {
        return abi.decode(data, (uint8, uint24, uint24, uint16));
    }

    function encodeApplicationParametersToData(
        uint8 protectionType,
        uint24 latitude,
        uint24 longitude,
        uint16 locationId
    ) public pure returns (bytes memory data) {
        return abi.encode(protectionType, latitude, longitude, locationId);
    }

    function expirePolicy(bytes32 processId) external onlyOwner {
        // Get policy data
        IPolicy.Application memory application = _getApplication(processId);

        _expire(processId);

        emit LogTerraGuardPolicyExpired(processId);
    }


    function _handleClaim(
        bytes32 policyId,
        address payable policyHolder,
        uint256 sumInsured,
        bytes1 fireCategory
    ) internal {
        uint256 payoutAmount = _calculatePayoutAmount(sumInsured, fireCategory);

        // no claims handling for payouts == 0
        if (payoutAmount > 0) {
            uint256 claimId = _newClaim(policyId, payoutAmount, "");
            _confirmClaim(policyId, claimId, payoutAmount);

            emit LogTerraGuardClaimConfirmed(policyId, claimId, payoutAmount);

            uint256 payoutId = _newPayout(policyId, claimId, payoutAmount, "");
            emit LogTerraGuardClaimConfirmed(policyId, claimId, payoutAmount);
            _processPayout(policyId, payoutId);

            emit LogTerraGuardPayoutExecuted(
                policyId,
                claimId,
                payoutId,
                payoutAmount
            );
        }
    }

    function _calculatePayoutAmount(
        uint256 sumInsured,
        bytes1 fireCategory
    ) internal pure returns (uint256 payoutAmount) {
        if (fireCategory == "M") {
            payoutAmount = (5 * sumInsured)  / 100;
        } else if (fireCategory == "L") {
            payoutAmount = (7 * sumInsured) / 100;
        } else {
            // small fires considered below deductible, no payout
            payoutAmount = 0;
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IProduct.sol";
import "Component.sol";
import "IPolicy.sol";
import "IInstanceService.sol";
import "IProductService.sol";

abstract contract Product is
    IProduct, 
    Component 
{    
    address private _policyFlow; // policy flow contract to use for this procut
    address private _token; // erc20 token to use for this product
    uint256 private _riskpoolId; // id of riskpool responsible for this product

    IProductService internal _productService;
    IInstanceService internal _instanceService;

    modifier onlyPolicyHolder(bytes32 policyId) {
        address policyHolder = _instanceService.getMetadata(policyId).owner;
        require(
            _msgSender() == policyHolder, 
            "ERROR:PRD-001:POLICY_OR_HOLDER_INVALID"
        );
        _;
    }

    modifier onlyLicence {
        require(
             _msgSender() == _getContractAddress("Licence"),
            "ERROR:PRD-002:ACCESS_DENIED"
        );
        _;
    }

    modifier onlyOracle {
        require(
             _msgSender() == _getContractAddress("Query"),
            "ERROR:PRD-003:ACCESS_DENIED"
        );
        _;
    }

    constructor(
        bytes32 name,
        address token,
        bytes32 policyFlow,
        uint256 riskpoolId,
        address registry
    )
        Component(name, ComponentType.Product, registry)
    {
        _token = token;
        _riskpoolId = riskpoolId;

        // TODO add validation for policy flow
        _policyFlow = _getContractAddress(policyFlow);
        _productService = IProductService(_getContractAddress("ProductService"));
        _instanceService = IInstanceService(_getContractAddress("InstanceService"));

        emit LogProductCreated(address(this));
    }

    function getToken() public override view returns(address) {
        return _token;
    }

    function getPolicyFlow() public view override returns(address) {
        return _policyFlow;
    }

    function getRiskpoolId() public override view returns(uint256) {
        return _riskpoolId;
    }

    // default callback function implementations
    function _afterApprove() internal override { emit LogProductApproved(getId()); }

    function _afterPropose() internal override { emit LogProductProposed(getId()); }
    function _afterDecline() internal override { emit LogProductDeclined(getId()); }

    function _newApplication(
        address applicationOwner,
        uint256 premiumAmount,
        uint256 sumInsuredAmount,
        bytes memory metaData, 
        bytes memory applicationData 
    )
        internal
        returns(bytes32 processId)
    {
        processId = _productService.newApplication(
            applicationOwner, 
            premiumAmount, 
            sumInsuredAmount, 
            metaData, 
            applicationData);
    }

    function _collectPremium(bytes32 processId) 
        internal
        returns(
            bool success,
            uint256 feeAmount,
            uint256 netAmount
        )
    {
        IPolicy.Policy memory policy = _getPolicy(processId);

        if (policy.premiumPaidAmount < policy.premiumExpectedAmount) {
            (success, feeAmount, netAmount) 
                = _collectPremium(
                    processId, 
                    policy.premiumExpectedAmount - policy.premiumPaidAmount
                );
        }
    }

    function _collectPremium(
        bytes32 processId,
        uint256 amount
    )
        internal
        returns(
            bool success,
            uint256 feeAmount,
            uint256 netAmount
        )
    {
        (success, feeAmount, netAmount) = _productService.collectPremium(processId, amount);
    }

    function _adjustPremiumSumInsured(
        bytes32 processId,
        uint256 expectedPremiumAmount,
        uint256 sumInsuredAmount
    ) internal {
        _productService.adjustPremiumSumInsured(processId, expectedPremiumAmount, sumInsuredAmount);
    }

    function _revoke(bytes32 processId) internal {
        _productService.revoke(processId);
    }

    function _underwrite(bytes32 processId) internal returns(bool success) {
        success = _productService.underwrite(processId);
    }

    function _decline(bytes32 processId) internal {
        _productService.decline(processId);
    }

    function _expire(bytes32 processId) internal {
        _productService.expire(processId);
    }

    function _close(bytes32 processId) internal {
        _productService.close(processId);
    }

    function _newClaim(
        bytes32 processId, 
        uint256 claimAmount,
        bytes memory data
    ) 
        internal
        returns (uint256 claimId)
    {
        claimId = _productService.newClaim(
            processId, 
            claimAmount, 
            data);
    }

    function _confirmClaim(
        bytes32 processId,
        uint256 claimId,
        uint256 payoutAmount
    )
        internal
    {
        _productService.confirmClaim(
            processId, 
            claimId, 
            payoutAmount);
    }

    function _declineClaim(bytes32 processId, uint256 claimId) internal {
        _productService.declineClaim(processId, claimId);
    }

    function _closeClaim(bytes32 processId, uint256 claimId) internal {
        _productService.closeClaim(processId, claimId);
    }

    function _newPayout(
        bytes32 processId,
        uint256 claimId,
        uint256 amount,
        bytes memory data
    )
        internal
        returns(uint256 payoutId)
    {
        payoutId = _productService.newPayout(processId, claimId, amount, data);
    }

    function _processPayout(
        bytes32 processId,
        uint256 payoutId
    )
        internal
        returns(
            uint256 feeAmount,
            uint256 netPayoutAmount
        )
    {
        (
            feeAmount,
            netPayoutAmount
        ) = _productService.processPayout(processId, payoutId);
    }

    function _request(
        bytes32 processId,
        bytes memory input,
        string memory callbackMethodName,
        uint256 responsibleOracleId
    )
        internal
        returns (uint256 requestId)
    {
        requestId = _productService.request(
            processId,
            input,
            callbackMethodName,
            address(this),
            responsibleOracleId
        );
    }

    function _cancelRequest(uint256 requestId)
        internal
    {
        _productService.cancelRequest(requestId);
    }

    function _getMetadata(bytes32 processId) 
        internal 
        view 
        returns (IPolicy.Metadata memory metadata) 
    {
        return _instanceService.getMetadata(processId);
    }

    function _getApplication(bytes32 processId) 
        internal 
        view 
        returns (IPolicy.Application memory application) 
    {
        return _instanceService.getApplication(processId);
    }

    function _getPolicy(bytes32 processId) 
        internal 
        view 
        returns (IPolicy.Policy memory policy) 
    {
        return _instanceService.getPolicy(processId);
    }

    function _getClaim(bytes32 processId, uint256 claimId) 
        internal 
        view 
        returns (IPolicy.Claim memory claim) 
    {
        return _instanceService.getClaim(processId, claimId);
    }

    function _getPayout(bytes32 processId, uint256 payoutId) 
        internal 
        view 
        returns (IPolicy.Payout memory payout) 
    {
        return _instanceService.getPayout(processId, payoutId);
    }

    function getApplicationDataStructure() external override virtual view returns(string memory dataStructure) {
        return "";
    }

    function getClaimDataStructure() external override virtual view returns(string memory dataStructure) {
        return "";
    }    
    function getPayoutDataStructure() external override virtual view returns(string memory dataStructure) {
        return "";
    }

    function riskPoolCapacityCallback(uint256 capacity) external override virtual { }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IComponent.sol";

interface IProduct is IComponent {

    event LogProductCreated (address productAddress);
    event LogProductProposed (uint256 componentId);
    event LogProductApproved (uint256 componentId);
    event LogProductDeclined (uint256 componentId);

    function getToken() external view returns(address token);
    function getPolicyFlow() external view returns(address policyFlow);
    function getRiskpoolId() external view returns(uint256 riskpoolId);

    function getApplicationDataStructure() external view returns(string memory dataStructure);
    function getClaimDataStructure() external view returns(string memory dataStructure);
    function getPayoutDataStructure() external view returns(string memory dataStructure);

    function riskPoolCapacityCallback(uint256 capacity) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IRegistry.sol";

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

import "IComponent.sol";
import "IAccess.sol";
import "IComponentEvents.sol";
import "IRegistry.sol";
import "IComponentOwnerService.sol";
import "IInstanceService.sol";
import "Ownable.sol";


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

import "IComponent.sol";

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

import "IComponent.sol";

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

import "IComponent.sol";
import "IBundle.sol";
import "IPolicy.sol";
import "IPool.sol";
import "IBundleToken.sol";
import "IComponentOwnerService.sol";
import "IInstanceOperatorService.sol";
import "IOracleService.sol";
import "IProductService.sol";
import "IRiskpoolService.sol";

import "IERC20.sol";
import "IERC721.sol";

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

import "IERC721.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "ITreasury.sol";

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
import "IERC20.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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