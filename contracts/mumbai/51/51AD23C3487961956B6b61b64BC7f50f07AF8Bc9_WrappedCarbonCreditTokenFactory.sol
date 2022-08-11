// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol';

import '../../abstracts/AbstractFactory.sol';
import '../CarbonCreditTerminalStation.sol';
import './WrappedCarbonCreditToken.sol';
import {CarbonCreditToken} from "../../CarbonCreditToken.sol";

/// @author FlowCarbon LLC
/// @title A Carbon Credit Wrapped Token Factory
contract WrappedCarbonCreditTokenFactory is AbstractFactory {

    using ClonesUpgradeable for address;

    /// @param implementationContract_ - the contract that is used a implementation base for new tokens
    /// @param owner_ - the owner of this contract, this will be a terminal station
    constructor (WrappedCarbonCreditToken implementationContract_, address owner_) {
        swapImplementationContract(address(implementationContract_));
        transferOwnership(owner_);
    }

    /// @notice Deploy a new carbon credit token
    /// @param name_ - the name of the new token, should be unique within the Flow Carbon Ecosystem
    /// @param symbol_ - the token symbol of the ERC-20, should be unique within the Flow Carbon Ecosystem
    /// @param details_ - token details to define the fungibillity characteristics of this token
    /// @param permissionList_ - the permission list of this token
    /// @param terminalStation_ - the terminal station to manage this token
    /// @return the address of the newly created token
    function createCarbonCreditToken(
        string memory name_,
        string memory symbol_,
        CarbonCreditToken.TokenDetails memory details_,
        ICarbonCreditPermissionList permissionList_,
        CarbonCreditTerminalStation terminalStation_
    ) onlyOwner external returns (WrappedCarbonCreditToken) {
        WrappedCarbonCreditToken token = WrappedCarbonCreditToken(implementationContract.clone());
        token.initialize(name_, symbol_, details_, permissionList_, terminalStation_);
        finalizeCreation(address(token));
        return token;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

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
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
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
        /// @solidity memory-safe-assembly
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
        /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';

/// @author FlowCarbon LLC
/// @title A Carbon Credit Token Factory
abstract contract AbstractFactory is Ownable {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /// @notice Emitted after the implementation contract has been swapped
    /// @param contractAddress - The address of the new implementation contract
    event SwappedImplementationContract(address contractAddress);

    /// @notice Emitted after a new token has been created by this factory
    /// @param instanceAddress - The address of the freshly deployed contract
    event InstanceCreated(address instanceAddress);

    /// @notice The implementation contract used to create new instances
    address public implementationContract;

    /// @dev Discoverable contracts that have been deployed by this factory
    EnumerableSetUpgradeable.AddressSet private _deployedContracts;

    /// @notice The owner is able to swap out the underlying token implementation
    /// @param implementationContract_ - The contract to be used from now on
    function swapImplementationContract(address implementationContract_) onlyOwner public returns (bool) {
        require(implementationContract_ != address(0), 'null address given as implementation contract');
        implementationContract = implementationContract_;
        emit SwappedImplementationContract(implementationContract_);
        return true;
    }

    /// @notice Check if a contract as been released by this factory
    /// @param address_ - The address of the contract
    /// @return Whether this contract has been deployed by this factory
    function hasContractDeployedAt(address address_) external view returns (bool) {
        return _deployedContracts.contains(address_);
    }

    /// @notice The number of contracts deployed by this factory
    function deployedContractsCount() external view returns (uint256) {
        return _deployedContracts.length();
    }

    /// @notice The contract deployed at a specific index
    /// @dev The ordering may change upon adding / removing
    /// @param index_ - The index into the set
    function deployedContractAt(uint256 index_) external view returns (address) {
        return _deployedContracts.at(index_);
    }

    /// @dev Internal function that should be called after each clone
    /// @param address_ - A freshly created token address
    function finalizeCreation(address address_) internal {
        _deployedContracts.add(address_);
        emit InstanceCreated(address_);
    }

    /// @dev Overridden to disable renouncing ownership
    function renounceOwnership() public virtual override onlyOwner {
        revert('renouncing ownership is disabled');
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol';
import '../abstracts/AbstractFactory.sol';
import './abstracts/AbstractStation.sol';
import '../CarbonCreditBundleToken.sol';
import '../CarbonCreditToken.sol';
import './CarbonCreditMainStation.sol';
import '../CarbonCreditPermissionListFactory.sol';
import './terminal/WrappedCarbonCreditBundleTokenFactory.sol';
import './terminal/WrappedCarbonCreditBundleToken.sol';
import './terminal/WrappedCarbonCreditTokenFactory.sol';
import "./terminal/TerminalAction.sol";
import "./terminal/TerminalHandler.sol";

/// @author FlowCarbon LLC
/// @title The Terminal Station Endpoint for all xchain activity
contract CarbonCreditTerminalStation is AbstractStation {

    /// @notice Emitted when the offsets of a bundle are forwarded to the main chain
    /// @param bundleAddress - the bundle being forwarded
    /// @param amount - the amount being forwarded
    event BundleOffsetsForwarded(address bundleAddress, uint256 amount);

    /// @notice Emitted when the offsets of a token are forwarded to the main chain
    /// @param tokenAddress - the token being forwarded
    /// @param amount - the amount being forwarded
    event OffsetsForwarded(address tokenAddress, uint256 amount);

    using ClonesUpgradeable for address;

    /// Chain ID of this this station
    uint256 public selfDestination;

    /// Chain ID of the main station
    uint256 public mainChainId;

    /// factory of the token
    WrappedCarbonCreditTokenFactory public tokenFactory;
    /// factory of the bundle
    WrappedCarbonCreditBundleTokenFactory public bundleFactory;
    /// The permission list factory
    CarbonCreditPermissionListFactory public permissionListFactory;

    /// we want to keep track of main chain to this chain address mappings!
    mapping (address => address) public selfToMainChainBundleMapping;
    mapping (address => address) public mainChainToSelfBundleMapping;

    mapping (address => address) public selfToMainChainTokenMapping;
    mapping (address => address) public mainChainToSelfTokenMapping;

    mapping (address => address) public selfToMainChainPermissionListMapping;
    mapping (address => address) public mainChainToSelfPermissionListMapping;

    modifier onlyTokens() {
        require(
            tokenFactory.hasContractDeployedAt(_msgSender()) || bundleFactory.hasContractDeployedAt(_msgSender()),
            'caller is not a token of this protocol'
        );
        _;
    }

    constructor(
        uint256 mainChainId_,
        uint256 selfDestination_,
        address owner_
    )  AbstractStation(address(new TerminalAction(this)), address(new TerminalHandler(this)), owner_) {
        mainChainId = mainChainId_;
        selfDestination = selfDestination_;

        tokenFactory = new WrappedCarbonCreditTokenFactory(new WrappedCarbonCreditToken(), address(this));
        bundleFactory = new WrappedCarbonCreditBundleTokenFactory(new WrappedCarbonCreditBundleToken(), address(this));
        permissionListFactory = new CarbonCreditPermissionListFactory(new CarbonCreditPermissionList(), address(this));
    }

    /// @notice Access function to the underlying factories to swap the implementation
    /// @param factoryAddress_ - the address of the factory
    /// @param newImplementationAddress_ - the address of the new implementation
    function swapFactoryImplementation(address factoryAddress_, address newImplementationAddress_) onlyOwner external {
        AbstractFactory factory;
        if (factoryAddress_ == address(bundleFactory)) {
            factory = WrappedCarbonCreditBundleTokenFactory(factoryAddress_);
        } else if (factoryAddress_ == address(tokenFactory)) {
            factory = WrappedCarbonCreditTokenFactory(factoryAddress_);
        } else if (factoryAddress_ == address(permissionListFactory)) {
            factory = CarbonCreditPermissionListFactory(factoryAddress_);
        } else {
            revert("factory address unknown");
        }
        factory.swapImplementationContract(newImplementationAddress_);
    }

    /// @notice sets chain specific addresses to a permission list
    /// @param permissionList_ - the permission list to add/remove a contract to
    /// @param contractAddress_ - the contract to add/remove
    /// @param hasPermission_ - true if adding, false to remove
    function setSingleChainPermission(ICarbonCreditPermissionList permissionList_, address contractAddress_, bool hasPermission_) external onlyOwner {
        require(permissionListFactory.hasContractDeployedAt(address(permissionList_)), "permission list not registered");
        permissionList_.setSingleChainPermission(contractAddress_, hasPermission_);
    }

    /// @notice returns the bundle for the given address or reverts if not a valid address
    /// @param bundleAddress_ - the address of the bundle
    function getBundle(address bundleAddress_) external view returns (WrappedCarbonCreditBundleToken) {
        require(bundleFactory.hasContractDeployedAt(bundleAddress_), 'bundle not registered');
        return WrappedCarbonCreditBundleToken(bundleAddress_);
    }

    /// @notice returns the token for the given address or reverts if not a valid address
    /// @param tokenAddress_ - the address of the token
    function getToken(address tokenAddress_) external view returns (WrappedCarbonCreditToken) {
        require(tokenFactory.hasContractDeployedAt(tokenAddress_), 'token not registered');
        return WrappedCarbonCreditToken(tokenAddress_);
    }

    /// @dev create token wrapper function as the terminal station is the owner of the factory
    function createToken(
        address originalAddress_, string memory name_, string memory symbol_, CarbonCreditToken.TokenDetails memory details_, ICarbonCreditPermissionList permissionList_
    ) external onlyEndpoints returns (WrappedCarbonCreditToken){
        WrappedCarbonCreditToken wToken = tokenFactory.createCarbonCreditToken(
            name_, symbol_, details_, permissionList_, this
        );
        selfToMainChainTokenMapping[address(wToken)] = originalAddress_;
        mainChainToSelfTokenMapping[originalAddress_] = address(wToken);

        return wToken;
    }

    /// @dev minting wrapper function as the terminal station is the owner of the tokens
    function mint(AbstractWrappedToken token_, address account_, uint256 amount_) external onlyEndpoints {
        token_.mint(account_, amount_);
    }

    /// @dev burning wrapper function as the terminal station is the owner of the tokens
    function burn(AbstractWrappedToken token_, address account_, uint256 amount_) external onlyEndpoints {
        token_.burn(account_, amount_);
    }

    /// @dev update permission list wrapper function as the terminal station is the owner of the tokens
    function updatePermissionList(WrappedCarbonCreditToken wToken, ICarbonCreditPermissionList wList) external onlyEndpoints {
        wToken.setPermissionList(wList);
    }

    /// @dev increase offset wrapper function as the terminal station is the owner of the tokens
    function increaseOffset(WrappedCarbonCreditToken wToken, address beneficiary_, uint256 amount_) external onlyEndpoints {
        wToken.increaseOffset(beneficiary_, amount_);
    }

    /// @dev create bundle wrapper function as the terminal station is the owner of the factory
    function createBundle(
        address originalAddress_, string memory name_, string memory symbol_, uint16 vintage_, uint256 feeDivisor_
    ) external onlyEndpoints returns (WrappedCarbonCreditBundleToken) {
         WrappedCarbonCreditBundleToken wBundle = bundleFactory.createCarbonCreditBundleToken(
                name_, symbol_, vintage_, feeDivisor_, this
        );
        selfToMainChainBundleMapping[address(wBundle)] = originalAddress_;
        mainChainToSelfBundleMapping[originalAddress_] = address(wBundle);
        return wBundle;
    }

    /// @dev bundle vintage increment wrapper function as the terminal station is the owner of the tokens
    function incrementVintage(WrappedCarbonCreditBundleToken wBundle, uint16 vintage_) external onlyEndpoints {
        wBundle.increaseVintage(vintage_);
    }


    /// @dev add / remove a token to a bundle wrapper function as the terminal station is the owner of the tokens
    function registerTokenForBundle(WrappedCarbonCreditBundleToken wBundle, WrappedCarbonCreditToken wToken, bool isAdded_, bool isPaused_) external onlyEndpoints {
        wBundle.pauseOrReactivateForDeposits(wToken, isPaused_);
        if (isAdded_) {
            wBundle.addToken(wToken);
        } else {
            wBundle.removeToken(wToken);
        }
    }

    /// @dev create permission list wrapper function as the terminal station is the owner of the factory
    function createPermissionList(address originalAddress_, string memory name_) external onlyEndpoints returns (ICarbonCreditPermissionList) {
        ICarbonCreditPermissionList permissionList = ICarbonCreditPermissionList(permissionListFactory.createCarbonCreditPermissionList(
            name_, address(this)
        ));
        selfToMainChainPermissionListMapping[address(permissionList)] = originalAddress_;
        mainChainToSelfPermissionListMapping[originalAddress_] = address(permissionList);

        permissionList.setSingleChainPermission(address(this), true);
        permissionList.setSingleChainPermission(actionEndpoint, true);
        permissionList.setSingleChainPermission(handlerEndpoint, true);

        return permissionList;
    }

    /// @dev set permission wrapper function as the terminal station is the owner of the permission lists
    function setMultiChainPermission(ICarbonCreditPermissionList permissionList, address account_, bool hasPermission_) external onlyEndpoints {
        permissionList.setMultiChainPermission(account_, hasPermission_);
    }

    /// @dev communication entrypoint for bundle offsets for bundles
    function forwardBundleOffset(WrappedCarbonCreditBundleToken wBundle_, uint256 amount_) external onlyTokens payable {
        _send(
            mainChainId,
            abi.encodeWithSelector(
              MainHandler.handleOffsetFromTreasury.selector,
              selfToMainChainBundleMapping[address(wBundle_)],
              amount_
            )
        );
        emit BundleOffsetsForwarded(address(wBundle_), amount_);
    }

    /// @dev communication entrypoint for offsets for tokens
    function forwardOffset(WrappedCarbonCreditToken wToken_, uint256 amount_) external onlyTokens payable {
        _send(
            mainChainId,
            abi.encodeWithSelector(
              MainHandler.handleOffsetFromTreasury.selector,
              selfToMainChainTokenMapping[address(wToken_)],
              amount_
            )
        );
        emit BundleOffsetsForwarded(address(wToken_), amount_);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import "../CarbonCreditTerminalStation.sol";
import "../../interfaces/ICarbonCreditPermissionList.sol";
import {CarbonCreditToken} from "../../CarbonCreditToken.sol";
import "../abstracts/AbstractWrappedToken.sol";

/// @author FlowCarbon LLC
/// @title A Carbon Credit Token Implementation for XChain Setups
contract WrappedCarbonCreditToken is AbstractWrappedToken {

    /// @notice Emitted when a token renounces its permission list
    /// @param renouncedPermissionListAddress - The address of the renounced permission list
    event PermissionListRenounced(address renouncedPermissionListAddress);

    /// @notice Emitted when the used permission list changes
    /// @param oldPermissionListAddress - The address of the old permission list
    /// @param newPermissionListAddress - The address of the new permission list
    event PermissionListChanged(address oldPermissionListAddress, address newPermissionListAddress);

    /// @notice Emitted when an increase is coming from a remote chain
    /// @param account_ - the account to increase
    /// @param amount_ - the amount that is increased
    event RemoteOffsetIncrease(address account_, uint256 amount_);

    /// @notice Token metadata
    CarbonCreditToken.TokenDetails private _details;

    /// @notice The permissionList associated with this token
    ICarbonCreditPermissionList public permissionList;

    /// @dev see factory for details
    function initialize(
        string memory name_,
        string memory symbol_,
        CarbonCreditToken.TokenDetails memory details_,
        ICarbonCreditPermissionList permissionList_,
        CarbonCreditTerminalStation terminalStation_
    ) external initializer {
        __AbstractWrappedToken__init(name_, symbol_, terminalStation_);

        _details = details_;
        permissionList = permissionList_;
    }

    /// @notice The methodology of this token (e.g. VERRA or GOLDSTANDARD)
    function methodology() external view returns (string memory) {
        return _details.methodology;
    }

    /// @notice The creditType of this token (e.g. 'WETLAND_RESTORATION', or 'REFORESTATION')
    function creditType() external view returns (string memory) {
        return _details.creditType;
    }

    /// @notice The guaranteed vintage of this token - newer is possible because new is always better :-)
    function vintage() external view returns (uint16) {
        return _details.vintage;
    }

    /// @notice Set the permission list
    /// @param permissionList_ - The permission list to use
    /// @dev since this may only be invoked by contracts, there is no dedicated renounce function
    function setPermissionList(ICarbonCreditPermissionList permissionList_) onlyOwner external {
        address oldPermissionListAddress = address(permissionList);
        address newPermissionListAddress = address(permissionList_);

        if (oldPermissionListAddress == newPermissionListAddress) {
            return;
        } else if (newPermissionListAddress != address(0)) {
            permissionList = permissionList_;
            emit PermissionListChanged(oldPermissionListAddress, address(permissionList_));
        } else {
            permissionList = ICarbonCreditPermissionList(address(0));
            emit PermissionListRenounced(oldPermissionListAddress);
        }
    }

    /// @notice the terminal function increases the offset
    /// @dev this happens if a ping-pong with an exposure function happened (e.g. offset specific)
    /// @param account_ - the account for which the offset is increased
    /// @param amount_ - the amount to offset
    function increaseOffset(address account_, uint256 amount_) external onlyOwner  {
        // we mint to the terminal station to keep the bookkeeping on the chain in sync
        _mint(_msgSender(), amount_);
        _offset(account_, amount_);

        // the balance is already forwarded to the main chain, so we do not keep track of it here
        pendingBalance -= amount_;

        emit RemoteOffsetIncrease(account_, amount_);

    }

    /// @dev see parent
    function _forwardOffsets(uint256 amount_) internal virtual override {
        terminalStation.forwardOffset{value: msg.value}(this, amount_);
    }


    /// @notice Override ERC20.transfer to respect permission lists
    /// @param from_ - The senders address
    /// @param to_ - The recipients address
    /// @param amount_ - The amount of tokens to send
    function _transfer(address from_, address to_, uint256 amount_) internal virtual override {
        if (address(permissionList) != address(0)) {
            require(permissionList.hasPermission(from_), 'the sender is not permitted to transfer this token');
            require(permissionList.hasPermission(to_), 'the recipient is not permitted to receive this token');
        }
        return super._transfer(from_, to_, amount_);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import './abstracts/AbstractToken.sol';
import './interfaces/ICarbonCreditPermissionList.sol';
import './CarbonCreditBundleTokenFactory.sol';

/// @author FlowCarbon LLC
/// @title A Carbon Credit Token Reference Implementation
contract CarbonCreditToken is AbstractToken {

    /// @notice Emitted when a token renounces its permission list
    /// @param renouncedPermissionListAddress - The address of the renounced permission list
    event PermissionListRenounced(address renouncedPermissionListAddress);

    /// @notice Emitted when the used permission list changes
    /// @param oldPermissionListAddress - The address of the old permission list
    /// @param newPermissionListAddress - The address of the new permission list
    event PermissionListChanged(address oldPermissionListAddress, address newPermissionListAddress);

    /// @notice The details of a token
    struct TokenDetails {
        /// The methodology of the token (e.g. VERRA)
        string methodology;
        /// The credit type of the token (e.g. FORESTRY)
        string creditType;
        /// The year in which the offset took place
        uint16 vintage;
    }

    /// @notice Token metadata
    TokenDetails private _details;

    /// @notice The permissionlist associated with this token
    ICarbonCreditPermissionList public permissionList;

    /// @notice The bundle token factory associated with this token
    CarbonCreditBundleTokenFactory public carbonCreditBundleTokenFactory;

    /// @notice Emitted when the contract owner mints new tokens
    /// @dev The account is already in the Transfer Event and thus omitted here
    /// @param amount - The amount of tokens that were minted
    /// @param checksum - A checksum associated with the underlying purchase event
    event Mint(uint256 amount, bytes32 checksum);

    /// @notice Checksums associated with the underlying mapped to the number of minted tokens
    mapping (bytes32 => uint256) private _checksums;

    /// @notice Checksums associated with the underlying offset event mapped to the number of finally offsetted tokens
    mapping (bytes32 => uint256) private _offsetChecksums;

    /// @notice Number of tokens removed from chain
    uint256 public movedOffChain;

    /// @dev see factory for details
    function initialize(
        string memory name_,
        string memory symbol_,
        TokenDetails memory details_,
        ICarbonCreditPermissionList permissionList_,
        address owner_,
        CarbonCreditBundleTokenFactory carbonCreditBundleTokenFactory_
    ) external initializer {
        require(details_.vintage > 2000, 'vintage out of bounds');
        require(details_.vintage < 2100, 'vintage out of bounds');
        require(bytes(details_.methodology).length > 0, 'methodology is required');
        require(bytes(details_.creditType).length > 0, 'credit type is required');
        require(address(carbonCreditBundleTokenFactory_) != address(0), 'bundle token factory is required');
        __AbstractToken_init(name_, symbol_, owner_);
        _details = details_;
        permissionList = permissionList_;
        carbonCreditBundleTokenFactory = carbonCreditBundleTokenFactory_;
    }

    /// @notice Mints new tokens, a checksum representing purchase of the underlying with the minting event
    /// @param account_ - The account that will receive the new tokens
    /// @param amount_ - The amount of new tokens to be minted
    /// @param checksum_ - A checksum associated with the underlying purchase event
    function mint(address account_, uint256 amount_, bytes32 checksum_) external onlyOwner returns (bool) {
        require(checksum_ > 0, 'checksum is required');
        require(_checksums[checksum_] == 0, 'checksum was already used');
        _mint(account_, amount_);
        _checksums[checksum_] = amount_;
        emit Mint(amount_, checksum_);
        return true;
    }

    /// @notice Get the amount of tokens minted with the given checksum
    /// @param checksum_ - The checksum associated with a minting event
    /// @return The amount minted with the associated checksum
    function amountMintedWithChecksum(bytes32 checksum_) external view returns (uint256) {
        return _checksums[checksum_];
    }

    /// @notice The contract owner can finalize the offsetting process once the underlying tokens have been offset
    /// @param amount_ - The number of token to finalize offsetting
    /// @param checksum_ - The checksum associated with the underlying offset event
    function finalizeOffset(uint256 amount_, bytes32 checksum_) external onlyOwner returns (bool) {
        require(checksum_ > 0, 'checksum is required');
        require(_offsetChecksums[checksum_] == 0, 'checksum was already used');
        require(amount_ <= pendingBalance, 'offset exceeds pending balance');
        _offsetChecksums[checksum_] = amount_;
        pendingBalance -= amount_;
        offsetBalance += amount_;
        emit FinalizeOffset(amount_, checksum_);
        return true;
    }

    /// @dev Allow only privileged users to burn the given amount of tokens
    /// @param amount_ - The amount of tokens to burn
    function burn(uint256 amount_) public virtual {
        require(
            _msgSender() == owner() || carbonCreditBundleTokenFactory.hasContractDeployedAt(_msgSender()),
            'sender does not have permission to burn'
        );
        _burn(_msgSender(), amount_);
        if (owner() == _msgSender()) {
            movedOffChain += amount_;
        }
    }

    /// @notice Return the balance of tokens offsetted by an address that match the given checksum
    /// @param checksum_ - The checksum of the associated offset event of the underlying token
    /// @return The number of tokens that have been offsetted with this checksum
    function amountOffsettedWithChecksum(bytes32 checksum_) external view returns (uint256) {
        return _offsetChecksums[checksum_];
    }

    /// @notice The methodology of this token (e.g. VERRA or GOLDSTANDARD)
    function methodology() external view returns (string memory) {
        return _details.methodology;
    }

    /// @notice The creditType of this token (e.g. 'WETLAND_RESTORATION', or 'REFORESTATION')
    function creditType() external view returns (string memory) {
        return _details.creditType;
    }

    /// @notice The guaranteed vintage of this token - newer is possible because new is always better :-)
    function vintage() external view returns (uint16) {
        return _details.vintage;
    }

    /// @notice Renounce the permission list, making this token accessible to everyone
    /// NOTE: This operation is *irreversible* and will leave the token permanently non-permissioned!
    function renouncePermissionList() onlyOwner external {
        permissionList = ICarbonCreditPermissionList(address(0));
        emit PermissionListRenounced(address(this));
    }

    /// @notice Set the permission list
    /// @param permissionList_ - The permission list to use
    function setPermissionList(ICarbonCreditPermissionList permissionList_) onlyOwner external {
        require(address(permissionList) != address(0), 'this operation is not allowed for non-permissioned tokens');
        require(address(permissionList_) != address(0), 'invalid attempt at renouncing the permission list - use renouncePermissionList() instead');
        address oldPermissionListAddress = address(permissionList);
        permissionList = permissionList_;
        emit PermissionListChanged(oldPermissionListAddress, address(permissionList_));
    }

    /// @notice Override ERC20.transfer to respect permission lists
    /// @param from_ - The senders address
    /// @param to_ - The recipients address
    /// @param amount_ - The amount of tokens to send
    function _transfer(address from_, address to_, uint256 amount_) internal virtual override {
        if (address(permissionList) != address(0)) {
            require(permissionList.hasPermission(from_), 'the sender is not permitted to transfer this token');
            require(permissionList.hasPermission(to_), 'the recipient is not permitted to receive this token');
        }
        return super._transfer(from_, to_, amount_);
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "../interfaces/IBridgeReceiver.sol";
import "../interfaces/IBridgeInterface.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import "../../CarbonCreditBundleToken.sol";
import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';

/// @author FlowCarbon LLC
/// @title Abstract Station for xchain messages
abstract contract AbstractStation is IBridgeReceiver, Ownable {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    /// @notice Emitted when native tokens are send to this account
    /// @param account - the sender
    /// @param amount - the amount received
    event Received(address account, uint amount);

    /// @notice Emitted when a remote contract is registered
    /// @param bridgeAdapterAddress - address of the bridge adapter
    /// @param destination - the remote chain
    /// @param contractAddress - the registered contract
    event RemoteContractRegistered(address bridgeAdapterAddress, uint256 destination, address contractAddress);

    /// @notice Emitted when a new bridge is configured for a chain
    /// @param destination - the remote chain
    /// @param bridgeAdapterAddress - address of the bridge adapter
    /// @param identifier - hashed identifier of the bridge
    event BridgeConfigured(uint256 destination, address bridgeAdapterAddress, bytes32 identifier);

    /// @notice Action Endpoint updated
    /// @param actionEndpoint - new endpoint address
    event ActionEndpointUpdated(address actionEndpoint);

    /// @notice Handler Endpoint updated
    /// @param handlerEndpoint - new endpoint address
    event HandlerEndpointUpdated(address handlerEndpoint);

    /// bridge configuration
    mapping(uint256 => IBridgeInterface) public bridges;
    EnumerableSetUpgradeable.UintSet private _supportedBridges;

    /// all actions configured for this station can be found here
    address public actionEndpoint;
    /// all handlers that this station can handle
    address public handlerEndpoint;
    /// are the endpoints final?
    bool public endpointsFinal;

    modifier onlyEndpoints() {
        require(
            _msgSender() == actionEndpoint || _msgSender() == handlerEndpoint
            , "caller is not action"
        );
        _;
    }

    constructor(address actionEndpoint_, address handlerEndpoint_, address owner_)  {
        actionEndpoint = actionEndpoint_;
        handlerEndpoint = handlerEndpoint_;
        transferOwnership(owner_);
    }

    function finalizeEndpoints() external onlyOwner {
        endpointsFinal = true;
    }

    /// @notice configure a new action endpoint
    /// @param endpoint_ - address of the new action endpoint
    function setActionEndpoint(address endpoint_) external onlyOwner {
        require(!endpointsFinal, "endpoints final");

        // setting the endpoint to address(0) is allowed as an emergency deactivation mechanism
        actionEndpoint = endpoint_;
        emit ActionEndpointUpdated(endpoint_);
    }

    /// @notice configure a new handler endpoint
    /// @param endpoint_ - address of the new handler endpoint
    function setHandlerEndpoint(address endpoint_) external onlyOwner {
        require(!endpointsFinal, "endpoints final");

        // setting the endpoint to address(0) is allowed as an emergency deactivation mechanism
        handlerEndpoint = endpoint_;
        emit HandlerEndpointUpdated(endpoint_);
    }

    /// @notice checks if we have a bridge for a given destination
    /// @return true if we have support, else false
    function hasBridge(uint256 destination_) public view returns (bool) {
        return _supportedBridges.contains(destination_);
    }

    /// @notice returns the bridge for the given destination
    /// @dev reverts if it does not exist
    /// @param destination_ - the target chain
    /// @return the bridge for the given destination
    function getBridge(uint256 destination_) public view returns (IBridgeInterface) {
        require(hasBridge(destination_), "no bridge registered for destination");
        return bridges[destination_];
    }

    /// @return the number of bridges / chains supported
    function bridgesCount() external view returns (uint256) {
        return _supportedBridges.length();
    }

    /// @notice The bridge at a specific index
    /// @dev The ordering may change upon adding / removing
    /// @param index_ - The index into the set
    /// @return the bridge for the given index
    function bridgeAt(uint256 index_) external view returns (IBridgeInterface) {
        return bridges[_supportedBridges.at(index_)];
    }

    /// @notice add or remove a bridge adapter
    /// @param destination_ - the target destination chain
    /// @param bridge_ - the bridge adapter to use, can be set to zero address to cut off the destination chain
    function registerBridgeAdapter(uint256 destination_, IBridgeInterface bridge_) external onlyOwner {
        bridges[destination_] = bridge_;

        if (address(bridge_) == address(0)) {
            _supportedBridges.remove(destination_);
            /// we use the zero address as identifier!
            emit BridgeConfigured(destination_, address(bridge_), bytes32(uint256(uint160(0))));
        } else {
            _supportedBridges.add(destination_);
            emit BridgeConfigured(destination_, address(bridge_), bridge_.getIdentifier());
        }
    }

    /// @notice registers a remote contract as authentic for this station
    /// @param destination_ - the remote chain
    /// @param contractAddress_ - the address of the contract to trust as a message sender
    function registerRemoteContract(uint256 destination_, address contractAddress_) external onlyOwner {
        getBridge(destination_).registerRemoteContract(destination_, contractAddress_);
        emit RemoteContractRegistered(address(bridges[destination_]), destination_, contractAddress_);
    }

    /// @dev see IBridgeReceiver
    function receiveMessage(uint256 source_, bytes memory payload_) external {
        require(address(getBridge(source_)) == _msgSender(), "invalid source");

        bool success;
        bytes memory returnData;

        /// forward to the handler
        (success, returnData) = address(handlerEndpoint).call(payload_);
        require(success, string(returnData));
    }

    /// @dev send messages to the remote chain, only allowed for trusted endpoints
    function send(uint256 destination_, bytes memory payload_) external payable onlyEndpoints {
        _send(destination_, payload_);
    }

    /// @param destination_ - the remote chain
    /// @param payload_ - the raw payload of the message call
    function _send(uint256 destination_, bytes memory payload_) internal {
        getBridge(destination_).sendMessage{value: msg.value}(destination_, payload_);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';
import './abstracts/AbstractToken.sol';
import './CarbonCreditToken.sol';
import './CarbonCreditTokenFactory.sol';
import './libraries/CarbonCreditIntegrity.sol';

/// @author FlowCarbon LLC
/// @title A Carbon Credit Bundle Token Reference Implementation
contract CarbonCreditBundleToken is AbstractToken {

    /// @notice The token address and amount of an offset event
    /// @dev The struct is stored for each checksum
    struct TokenChecksum {
        address _tokenAddress;
        uint256 _amount;
    }

    /// @notice Emitted when someone bundles tokens into the bundle token
    /// @param account - The token sender
    /// @param amount - The amount of tokens to bundle
    /// @param tokenAddress - The address of the vanilla underlying
    event Bundle(address account, uint256 amount, address tokenAddress);

    /// @notice Emitted when someone unbundles tokens from the bundle
    /// @param account - The token recipient
    /// @param amount - The amount of unbundled tokens
    /// @param tokenAddress - The address of the vanilla underlying
    event Unbundle(address account, uint256 amount, address tokenAddress);

    /// @notice Emitted when a new token is added to the bundle
    /// @param tokenAddress - The new token that is added
    event TokenAdded(address tokenAddress);

    /// @notice Emitted when a new token is removed from the bundle
    /// @param tokenAddress - The token that has been removed
    event TokenRemoved(address tokenAddress);

    /// @notice Emitted when a token is paused for deposited or removed
    /// @param token - The token paused for deposits
    /// @param paused - Whether the token was paused (true) or reactivated (false)
    event TokenPaused(address token, bool paused);

    /// @notice Emitted when the minimum vintage requirements change
    /// @param vintage - The new vintage after the update
    event VintageIncremented(uint16 vintage);

    /// @notice Emitted when an amount of the bundle is reserved for finalisation
    /// @param tokenAddress - The token that reserves a batch
    event ReservedForFinalization(address tokenAddress, uint256 amount);

    /// @notice The token factory for carbon credit tokens
    CarbonCreditTokenFactory public carbonCreditTokenFactory;

    /// @notice The fee divisor taken upon unbundling
    /// @dev 1/feeDivisor is the fee in %
    uint256 public feeDivisor;

    /// @notice The minimal vintage
    uint16 public vintage;

    /// @notice The CarbonCreditTokens that form this bundle
    EnumerableSetUpgradeable.AddressSet private _tokenAddresses;

    /// @notice Tokens disabled for deposit
    EnumerableSetUpgradeable.AddressSet private _pausedForDepositTokenAddresses;

    /// @notice The bookkeeping method on the bundled tokens
    /// @dev This could differ from the balance if someone sends raw tokens to the contract
    mapping (CarbonCreditToken => uint256) public bundledAmount;

    /// @notice Amount reserved for offsetting
    mapping (CarbonCreditToken => uint256) public reservedAmount;
    uint256 public totalAmountReserved;

    /// @notice Keeps track of checksums, amounts and underlying tokens
    mapping (bytes32 => TokenChecksum) private _offsetChecksums;

    uint16 constant MIN_VINTAGE_YEAR = 2000;
    uint16 constant MAX_VINTAGE_YEAR = 2100;
    uint8 constant MAX_VINTAGE_INCREMENT = 10;

    /// @dev see factory for details
    function initialize(
        string memory name_,
        string memory symbol_,
        uint16 vintage_,
        CarbonCreditToken[] memory tokens_,
        address owner_,
        uint256 feeDivisor_,
        CarbonCreditTokenFactory carbonCreditTokenFactory_
    ) external initializer {
        require(vintage_ > MIN_VINTAGE_YEAR, 'vintage out of bounds');
        require(vintage_ < MAX_VINTAGE_YEAR, 'vintage out of bounds');
        require(address(carbonCreditTokenFactory_) != address(0), 'token factory is required');

        __AbstractToken_init(name_, symbol_, owner_);

        vintage = vintage_;
        feeDivisor = feeDivisor_;
        carbonCreditTokenFactory = carbonCreditTokenFactory_;

        for (uint256 i = 0; i < tokens_.length; i++) {
            _addToken(tokens_[i]);
        }
    }

    /// @notice Increasing the vintage
    /// @dev Existing tokens can no longer be bundled, new tokens require the new vintage
    /// @param years_ - Number of years to increment the vintage, needs to be smaller than MAX_VINTAGE_INCREMENT
    function incrementVintage(uint16 years_) external onlyOwner returns (uint16) {
        require(years_ <= MAX_VINTAGE_INCREMENT, 'vintage increment is too large');
        require(vintage + years_ < MAX_VINTAGE_YEAR, 'vintage too high');

        vintage += years_;
        emit VintageIncremented(vintage);
        return vintage;
    }

    /// @notice Check if a token is paused for deposits
    /// @param token_ - The token to check
    /// @return Whether the token is paused or not
    function pausedForDeposits(CarbonCreditToken token_) public view returns (bool) {
        return EnumerableSetUpgradeable.contains(_pausedForDepositTokenAddresses, address(token_));
    }

    /// @notice Pauses or reactivates deposits for carbon credits
    /// @param token_ - The token to pause or reactivate
    /// @return Whether the action had an effect (the token was not already flagged for the respective action) or not
    function pauseOrReactivateForDeposits(CarbonCreditToken token_, bool pause_) external onlyOwner returns(bool) {
        CarbonCreditIntegrity.requireHasToken(this, token_);

        bool actionHadEffect;
        if (pause_) {
            actionHadEffect = EnumerableSetUpgradeable.add(_pausedForDepositTokenAddresses, address(token_));
        } else {
            actionHadEffect = EnumerableSetUpgradeable.remove(_pausedForDepositTokenAddresses, address(token_));
        }

        if (actionHadEffect) {
            emit TokenPaused(address(token_), pause_);
        }

        return actionHadEffect;
    }

    /// @notice Withdraws tokens that have been transferred to the contract
    /// @dev This may happen if people accidentally transfer tokens to the bundle instead of using the bundle function
    /// @param token_ - The token to withdraw orphans for
    /// @return The amount withdrawn to the owner
    function withdrawOrphanToken(CarbonCreditToken token_) public returns (uint256) {
        uint256 _orphanTokens = token_.balanceOf(address(this)) - bundledAmount[token_];

        if (_orphanTokens > 0) {
            SafeERC20Upgradeable.safeTransfer(token_, owner(), _orphanTokens);
        }
        return _orphanTokens;
    }

    /// @notice Checks if a token exists
    /// @param token_ - A carbon credit token
    function hasToken(CarbonCreditToken token_) public view returns (bool) {
        return EnumerableSetUpgradeable.contains(_tokenAddresses, address(token_));
    }

    /// @notice Number of tokens in this bundle
    function tokenCount() external view returns (uint256) {
        return EnumerableSetUpgradeable.length(_tokenAddresses);
    }

    /// @notice A token from the bundle
    /// @dev The ordering may change upon adding / removing
    /// @param index_ - The index position taken from tokenCount()
    function tokenAtIndex(uint256 index_) external view returns (address) {
        return EnumerableSetUpgradeable.at(_tokenAddresses, index_);
    }

    /// @notice Adds a new token to the bundle. The token has to match the TokenDetails signature of the bundle
    /// @param token_ - A carbon credit token that is added to the bundle.
    /// @return True if token was added, false it if did already exist
    function addToken(CarbonCreditToken token_) external onlyOwner returns (bool) {
        return _addToken(token_);
    }

    /// @dev Private function to execute addToken so it can be used in the initializer
    /// @return True if token was added, false it if did already exist
    function _addToken(CarbonCreditToken token_) private returns (bool) {
        CarbonCreditIntegrity.requireIsEligibleForBundle(this, token_);

        bool isAdded = EnumerableSetUpgradeable.add(_tokenAddresses, address(token_));
        emit TokenAdded(address(token_));
        return isAdded;
    }

    /// @notice Removes a token from the bundle
    /// @param token_ - The carbon credit token to remove
    function removeToken(CarbonCreditToken token_) external onlyOwner {
        CarbonCreditIntegrity.requireHasToken(this, token_);

        withdrawOrphanToken(token_);
        require(token_.balanceOf(address(this)) == 0, 'token has remaining balance');

        address tokenAddress = address(token_);
        EnumerableSetUpgradeable.remove(_tokenAddresses, tokenAddress);
        emit TokenRemoved(tokenAddress);
    }

    /// @notice Bundles an underlying into the bundle, bundle need to be approved beforehand
    /// @param token_ - The carbon credit token to bundle
    /// @param amount_ - The amount one wants to bundle
    function bundle(CarbonCreditToken token_, uint256 amount_) external returns (bool) {
        CarbonCreditIntegrity.requireCanBundleToken(this, token_, amount_);

        _mint(_msgSender(), amount_);
        bundledAmount[token_] += amount_;
        SafeERC20Upgradeable.safeTransferFrom(token_, _msgSender(), address(this), amount_);

        emit Bundle(_msgSender(), amount_, address(token_));
        return true;
    }

    /// @notice Unbundles an underlying from the bundle, note that a fee may apply
    /// @param token_ - The carbon credit token to undbundle
    /// @param amount_ - The amount one wants to unbundle (including fee)
    /// @return The amount of tokens after fees
    function unbundle(CarbonCreditToken token_, uint256 amount_) external returns (uint256) {
        CarbonCreditIntegrity.requireCanUnbundleToken(this, token_, amount_);

        _burn(_msgSender(), amount_);

        uint256 amountToUnbundle = amount_;
        if (feeDivisor > 0) {
            uint256 feeAmount = amount_ / feeDivisor;
            amountToUnbundle = amount_ - feeAmount;
            SafeERC20Upgradeable.safeTransfer(token_, owner(), feeAmount);
        }

        bundledAmount[token_] -= amount_;
        SafeERC20Upgradeable.safeTransfer(token_, _msgSender(), amountToUnbundle);

        emit Unbundle(_msgSender(), amountToUnbundle, address(token_));
        return amountToUnbundle;
    }

    /// @notice Reserves a specific amount of tokens for finalization of offsets
    /// @dev To avoid race-conditions this function should be called before completing the off-chain retirement process
    /// @param token_ - The token to reserve
    /// @param amount_ - The amount of tokens to reserve
    function reserveForFinalization(CarbonCreditToken token_, uint256 amount_) external onlyOwner {
        CarbonCreditIntegrity.requireHasToken(this, token_);

        totalAmountReserved -= reservedAmount[token_];
        reservedAmount[token_] = amount_;
        totalAmountReserved += amount_;

        require(pendingBalance >= totalAmountReserved, 'cannot reserve more than currently pending');

        emit ReservedForFinalization(address(token_), amount_);
    }

    /// @notice The contract owner can finalize the offsetting process once the underlying tokens have been offset
    /// @param token_ - The carbon credit token to finalize the offsetting process for
    /// @param amount_ - The number of token to finalize offsetting process for
    /// @param checksum_ - The checksum associated with the underlying offset event
    function finalizeOffset(CarbonCreditToken token_, uint256 amount_, bytes32 checksum_) external onlyOwner returns (bool) {
        CarbonCreditIntegrity.requireCanFinalizeOffset(this, token_, amount_, checksum_);

        pendingBalance -= amount_;
        _offsetChecksums[checksum_] = TokenChecksum(address(token_), amount_);
        offsetBalance += amount_;
        bundledAmount[token_] -= amount_;

        token_.burn(amount_);

        totalAmountReserved = amount_ < totalAmountReserved ? totalAmountReserved - amount_ : 0;
        reservedAmount[token_] = amount_ < reservedAmount[token_] ? reservedAmount[token_] - amount_ : 0;

        emit FinalizeOffset(amount_, checksum_);
        return true;
    }

    /// @notice Return the balance of tokens offsetted by an address that match the given checksum
    /// @param checksum_ - The checksum of the associated offset event of the underlying token
    /// @return The number of tokens that have been offsetted with this checksum
    function amountOffsettedWithChecksum(bytes32 checksum_) external view returns (uint256) {
        return _offsetChecksums[checksum_]._amount;
    }

    /// @param checksum_ - The checksum of the associated offset event of the underlying
    /// @return The address of the CarbonCreditToken that has been offset with this checksum
    function tokenAddressOffsettedWithChecksum(bytes32 checksum_) external view returns (address) {
        return _offsetChecksums[checksum_]._tokenAddress;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';
import "../CarbonCreditBundleConductor.sol";
import "../CarbonCreditTokenFactory.sol";
import "../CarbonCreditPermissionListFactory.sol";
import "./abstracts/AbstractStation.sol";
import "../CarbonCreditToken.sol";
import "./CarbonCreditTerminalStation.sol";
import "./main/PostageFee.sol";
import "./main/MainAction.sol";
import "./main/MainHandler.sol";

/// @author FlowCarbon LLC
/// @title The Main Station Entrypoint for all xchain activity
contract CarbonCreditMainStation is AbstractStation {

    /// @notice Emitted when we send a callback to a chain
    /// @dev gives us a hint on when to refill the main station
    /// @param destination - the receiver of the callback
    event CallbackSend(uint256 destination);

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// The bundle conductor to orchestrate rakeback activity
    CarbonCreditBundleConductor public bundleConductor;
    /// The token factory for GCO2
    CarbonCreditTokenFactory public tokenFactory;
    /// The permission list factory
    CarbonCreditPermissionListFactory public permissionListFactory;

    /// The following mappings do keep track about which tokens have already been synced to destination chains
    mapping(uint256 => EnumerableSetUpgradeable.AddressSet) private _releasedTokens;
    mapping(uint256 => EnumerableSetUpgradeable.AddressSet) private _releasedBundles;
    mapping(uint256 => EnumerableSetUpgradeable.AddressSet) private _releasedPermissionLists;

    /// The fee structure to prevent network spam
    PostageFee public postageFee;

     constructor(
         address bundleConductorAddress_,
         address carbonCreditTokenFactoryAddress_,
         address carbonCreditPermissionListFactoryAddress_,
         address owner_
    )  AbstractStation(address(new MainAction(this)), address(new MainHandler(this)), owner_) {
         require(bundleConductorAddress_ != address(0), "bundle conductor is required");
         require(carbonCreditTokenFactoryAddress_ != address(0), "carbon credit token factory is required");
         require(carbonCreditPermissionListFactoryAddress_ != address(0), "carbon credit permission list factory is required");

         tokenFactory = CarbonCreditTokenFactory(carbonCreditTokenFactoryAddress_);
         permissionListFactory = CarbonCreditPermissionListFactory(carbonCreditPermissionListFactoryAddress_);
         bundleConductor = CarbonCreditBundleConductor(bundleConductorAddress_);

         postageFee = new PostageFee(owner_);
    }

    /// @notice get the bundle from the address
    /// @param bundleAddress_ - the address of the bundle
    /// @return the bundle token
    function getBundle(address bundleAddress_) public view returns (CarbonCreditBundleToken) {
        require(
            bundleConductor.carbonCreditBundleTokenFactory().hasContractDeployedAt(bundleAddress_), "unknown bundle"
        );
        return CarbonCreditBundleToken(bundleAddress_);
    }

    /// @notice get the permission list from the address
    /// @param permissionListAddress_ - the address of the permission list
    /// @return the permission list
    function getPermissionList(address permissionListAddress_) external view returns (CarbonCreditPermissionList) {
        require(
            permissionListFactory.hasContractDeployedAt(permissionListAddress_),
            "unknown permission list"
        );
        return CarbonCreditPermissionList(permissionListAddress_);
    }

    /// @notice get the token from the address
    /// @param tokenAddress_ - the address of the token
    /// @return the token
    function getToken(address tokenAddress_) public view returns (CarbonCreditToken) {
        require(tokenFactory.hasContractDeployedAt(tokenAddress_), "unknown token");
        return CarbonCreditToken(tokenAddress_);
    }

    /// @dev enforces permission list to be synced if it is not the zero address
    /// @param destination_ - the destination chain
    /// @param permissionListAddress_ - the permission list to check for
    function requirePermissionListSynced(uint256 destination_, address permissionListAddress_) external view {
        if (permissionListAddress_ != address(0)) {
            require(
                _releasedPermissionLists[destination_].contains(permissionListAddress_),
                "permission list not synced"
            );
        }
    }

    /// @dev enforces permission list to be NOT synced
    /// @param destination_ - the destination chain
    /// @param permissionListAddress_ - the permission list to check for
    function requirePermissionListNotSynced(uint256 destination_, address permissionListAddress_) external view {
        require(!_releasedPermissionLists[destination_].contains(permissionListAddress_), "permission list already synced");
    }


    /// @dev enforces token to be synced
    /// @param destination_ - the destination chain
    /// @param tokenAddress_ - address of the token
    function requireTokenSynced(uint256 destination_, address tokenAddress_) external view {
        require(_releasedTokens[destination_].contains(tokenAddress_), "token not synced");
    }

    /// @dev enforces bundle to be synced
    /// @param destination_ - the destination chain
    /// @param bundleAddress_ - address of the bundle
    function requireBundleSynced(uint256 destination_, address bundleAddress_) external view {
        require(_releasedBundles[destination_].contains(bundleAddress_), "bundle not synced");
    }

    /// @dev transfers out the postage fee to the station owner, this is to cover ping-pong actions below a threshold
    /// @param destination_ - the destination fee for which the is a fee to pay
    /// @param bundle_ - the bundle involved for price determination
    /// @param feeBasisToken_ - the token in which the fee is paid, can be the bundle or an underlying GCO2
    /// @param amount_ - the amount in terms of bundle that is subject to the fee
    /// @param isSuccessPath_ - on success the fee may be lower or even 0 (cause there is already an unbundle fee)
    /// @return the amount after fee
    function deductPostageFee(
        uint256 destination_, CarbonCreditBundleToken bundle_, IERC20Upgradeable feeBasisToken_, uint256 amount_,
        bool isSuccessPath_
    ) external onlyEndpoints returns (uint256) {
        uint256 fee = postageFee.get(destination_, bundle_, amount_, isSuccessPath_);
        if (amount_ <= fee) {
            feeBasisToken_.safeTransfer(owner(), amount_);
            return 0;
        }
        if (fee > 0) {
            feeBasisToken_.safeTransfer(owner(), fee);
        }
        return amount_ - fee;
    }

    /// @dev registers a released token - only available to endpoints
    function registerReleasedToken(uint256 destination_, address tokenAddress_) external onlyEndpoints returns (bool) {
        return _releasedTokens[destination_].add(tokenAddress_);
    }

    /// @dev registers a released bundle - only available to endpoints
    function registerReleaseBundle(uint256 destination_, address bundleAddress_) external onlyEndpoints returns (bool) {
        getBundle(bundleAddress_).approve(address(bundleConductor), type(uint256).max);
        return _releasedBundles[destination_].add(bundleAddress_);
    }

    /// @dev registers a released permission list - only available to endpoints
    function registerReleasePermissionList(uint256 destination_, address permissionListAddress_) external onlyEndpoints returns (bool) {
        return _releasedPermissionLists[destination_].add(permissionListAddress_);
    }

    /// @dev transfer wrapper, as this contract is the state-holding treasury of tokens - only available to endpoints
    function transfer(address tokenAddress_, address recipient_, uint256 amount_) external onlyEndpoints {
        IERC20Upgradeable(tokenAddress_).safeTransfer(recipient_, amount_);
    }

    /// @dev offset wrapper, as this contract is the state-holding treasury of tokens
    function offset(address tokenAddress_, uint256 amount_) external onlyEndpoints {
        ICarbonCreditTokenInterface(tokenAddress_).offset(amount_);
    }

    /// @dev bundle wrapper, as this contract is the state-holding treasury of tokens
    function bundle(CarbonCreditBundleToken bundle_, CarbonCreditToken token_, uint256 amount_) external onlyEndpoints {
        token_.approve(address(bundle_), amount_);
        bundle_.bundle(token_, amount_);
    }

    /// @dev unbundle wrapper, as this contract is the state-holding treasury of tokens
    function unbundle(
        CarbonCreditBundleToken bundle_, CarbonCreditToken token_, uint256 amount_
    ) external onlyEndpoints returns (uint256){
        return bundle_.unbundle(token_, amount_);
    }

    /// @dev swap bundle wrapper, as this contract is the state-holding treasury of tokens
    function swapBundle(
        CarbonCreditBundleToken sourceBundle_, CarbonCreditBundleToken targetBundle_, CarbonCreditToken token_, uint256 amount_
    ) external onlyEndpoints returns (uint256) {
        return bundleConductor.swapBundle(sourceBundle_, targetBundle_, token_, amount_);
    }

    /// @dev offset specific wrapper, as this contract is the state-holding treasury of tokens
    function offsetSpecific(
        CarbonCreditBundleToken bundle_, CarbonCreditToken token_, uint256 amount_
    ) external onlyEndpoints returns (uint256) {
        return bundleConductor.offsetSpecific(bundle_, token_, amount_);
    }

    /// @dev callback to the original chain, fee is paid by the contract and deducted in terms of GCO2/Bundle tokens
    /// @param destination_ - the original chain to callback
    /// @param payload_ - the raw payload to send back
    function sendCallback(uint256 destination_, bytes memory payload_) external onlyEndpoints {
        getBridge(destination_).sendMessage{
            value: postageFee.getNative(destination_)
        }(destination_, payload_);

        emit CallbackSend(destination_);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './CarbonCreditPermissionList.sol';
import './abstracts/AbstractFactory.sol';

/// @author FlowCarbon LLC
/// @title A Carbon Credit Token Permission List Factory
contract CarbonCreditPermissionListFactory is AbstractFactory {

    using ClonesUpgradeable for address;

    /// @param implementationContract_ - The contract to be used as implementation for new lists
    /// @param owner_ - The address to which ownership of this contract will be transferred
    constructor (CarbonCreditPermissionList implementationContract_, address owner_) {
        swapImplementationContract(address(implementationContract_));
        transferOwnership(owner_);
    }

    /// @notice Deploy a new carbon credit permission list
    /// @param name_ - The name given to the newly deployed list
    /// @param owner_ - The address to which ownership of the deployed contract will be transferred
    /// @return The address of the newly created list
    function createCarbonCreditPermissionList(string memory name_, address owner_) onlyOwner external returns (address) {
        CarbonCreditPermissionList permissionList = CarbonCreditPermissionList(implementationContract.clone());
        permissionList.initialize(name_, owner_);
        finalizeCreation(address(permissionList));
        return address(permissionList);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol';

import '../../abstracts/AbstractFactory.sol';
import '../CarbonCreditTerminalStation.sol';
import './WrappedCarbonCreditBundleToken.sol';

/// @author FlowCarbon LLC
/// @title A Carbon Credit Wrapped Bundle Token Factory
contract WrappedCarbonCreditBundleTokenFactory is AbstractFactory {

    using ClonesUpgradeable for address;

    /// @param implementationContract_ - the contract that is used a implementation base for new tokens
    /// @param owner_ - the owner of this contract, this will be a terminal station
    constructor (WrappedCarbonCreditBundleToken implementationContract_, address owner_) {
        swapImplementationContract(address(implementationContract_));
        transferOwnership(owner_);
    }

    /// @notice Deploy a new carbon credit bundle token
    /// @param name_ - The name of the new token, should be unique within the Flow Carbon Ecosystem
    /// @param symbol_ - The token symbol of the ERC-20, should be unique within the Flow Carbon Ecosystem
    /// @param vintage_ - The minimum vintage of this bundle
    /// @param feeDivisor_ - The fee divisor that should be taken upon unbundling
    /// @param terminalStation_ - the terminal station to manage this token
    /// @return The address of the newly created token
    function createCarbonCreditBundleToken(
        string memory name_,
        string memory symbol_,
        uint16 vintage_,
        uint256 feeDivisor_,
        CarbonCreditTerminalStation terminalStation_
    ) onlyOwner external returns (WrappedCarbonCreditBundleToken) {
        WrappedCarbonCreditBundleToken token = WrappedCarbonCreditBundleToken(implementationContract.clone());
        token.initialize(name_, symbol_, vintage_, feeDivisor_, terminalStation_);
        finalizeCreation(address(token));
        return token;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';
import '../CarbonCreditTerminalStation.sol';
import './WrappedCarbonCreditToken.sol';
import "../abstracts/AbstractWrappedToken.sol";

/// @author FlowCarbon LLC
/// @title A bundle token implementation for terminal chains
contract WrappedCarbonCreditBundleToken is AbstractWrappedToken {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /// @notice tokens in this bundle
    EnumerableSetUpgradeable.AddressSet private _tokenAddresses;

    /// @notice Tokens disabled for deposit
    EnumerableSetUpgradeable.AddressSet private _pausedForDepositTokenAddresses;

    /// @notice Emitted when a token is added
    /// @param tokenAddress - the token added to the bundle
    event TokenAdded(address tokenAddress);

    /// @notice Emitted when a token is removed
    /// @param tokenAddress - the token removed from the bundle
    event TokenRemoved(address tokenAddress);

    /// @notice Emitted when a token is paused for deposited or removed
    /// @param token - The token paused for deposits
    /// @param paused - Whether the token was paused (true) or reactivated (false)
    event TokenPaused(address token, bool paused);

    /// @notice Emitted when the minimum vintage requirements change
    /// @param vintage - The new vintage after the update
    event VintageIncremented(uint16 vintage);

    /// @notice The fee divisor taken upon unbundling
    /// @dev 1/feeDivisor is the fee in %
    uint256 public feeDivisor;

    /// @notice The minimal vintage
    uint16 public vintage;

    /// @dev see factory for details
    function initialize(
        string memory name_,
        string memory symbol_,
        uint16 vintage_,
        uint256 feeDivisor_,
        CarbonCreditTerminalStation terminalStation_
    ) external initializer {
        __AbstractWrappedToken__init(name_, symbol_, terminalStation_);

        vintage = vintage_;
        feeDivisor = feeDivisor_;
        terminalStation = terminalStation_;
    }

    /// @notice Checks if a token exists
    /// @param token_ - A carbon credit token
    function hasToken(WrappedCarbonCreditToken token_) external view returns (bool) {
        return _tokenAddresses.contains(address(token_));
    }

    /// @notice Number of tokens in this bundle
    function tokenCount() external view returns (uint256) {
        return _tokenAddresses.length();
    }

    /// @notice A token from the bundle
    /// @dev The ordering may change upon adding / removing
    /// @param index_ - The index position taken from tokenCount()
    function tokenAtIndex(uint256 index_) external view returns (address) {
        return _tokenAddresses.at(index_);
    }

    /// @notice Adds a new token to the bundle.
    /// @param token_ - A carbon credit token that is added to the bundle.
    /// @return True if token was added, false it if did already exist
    function addToken(WrappedCarbonCreditToken token_) external onlyOwner returns (bool) {
        bool isAdded = _tokenAddresses.add(address(token_));
        emit TokenAdded(address(token_));
        return isAdded;
    }

    /// @notice Removes a token from the bundle
    /// @param token_ - The carbon credit token to remove
    function removeToken(WrappedCarbonCreditToken token_) external onlyOwner {
        address tokenAddress = address(token_);
        _tokenAddresses.remove(tokenAddress);
        emit TokenRemoved(tokenAddress);
    }

    /// @notice Check if a token is paused for deposits
    /// @param token_ - The token to check
    /// @return Whether the token is paused or not
    function pausedForDeposits(WrappedCarbonCreditToken token_) public view returns (bool) {
        return EnumerableSetUpgradeable.contains(_pausedForDepositTokenAddresses, address(token_));
    }

    /// @notice Pauses or reactivates deposits for carbon credits
    /// @param token_ - The token to pause or reactivate
    /// @return Whether the action had an effect (the token was not already flagged for the respective action) or not
    function pauseOrReactivateForDeposits(WrappedCarbonCreditToken token_, bool pause_) external onlyOwner returns(bool) {
        bool actionHadEffect;
        if (pause_) {
            actionHadEffect = EnumerableSetUpgradeable.add(_pausedForDepositTokenAddresses, address(token_));
        } else {
            actionHadEffect = EnumerableSetUpgradeable.remove(_pausedForDepositTokenAddresses, address(token_));
        }

        if (actionHadEffect) {
            emit TokenPaused(address(token_), pause_);
        }

        return actionHadEffect;
    }

    // @notice Increasing the vintage
    /// @dev does nothings if the new vintage isn't higher than the old one
    /// @param vintage_ - the new vintage (e.g. 2020)
    function increaseVintage(uint16 vintage_) external onlyOwner {
        if (vintage < vintage_) {
            vintage = vintage_;
            emit VintageIncremented(vintage);
        }
    }

    /// @dev see parent
    function _forwardOffsets(uint256 amount_) internal virtual override {
        terminalStation.forwardBundleOffset{value: msg.value}(this, amount_);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts/access/Ownable.sol';
import "../CarbonCreditTerminalStation.sol";
import "../interfaces/IActionInterface.sol";
import "./WrappedCarbonCreditBundleToken.sol";
import "./WrappedCarbonCreditToken.sol";
import "../main/MainHandler.sol";

/// @author FlowCarbon LLC
/// @title A terminal action implementation
contract TerminalAction is IActionInterface {

    CarbonCreditTerminalStation station;

    /// @notice Emitted when someone bundles tokens into the bundle token
    /// @param account - The token sender
    /// @param amount - The amount of tokens to bundle
    /// @param tokenAddress - The address of the vanilla underlying
    event Bundle(address account, uint256 amount, address tokenAddress);

    /// @notice Emitted when someone unbundles tokens from the bundle
    /// @param account - The token recipient
    /// @param amount - The amount of unbundled tokens
    /// @param tokenAddress - The address of the vanilla underlying
    event Unbundle(address account, uint256 amount, address tokenAddress);

    /// @notice Emitted when a bundle swapped is triggered
    /// @param sourceBundleAddress - the source bundle
    /// @param targetBundleAddress - the target bundle
    /// @param tokenAddress - the token to swap from source to target
    /// @param amount - the amount of tokens to swap
    event BundleSwapped(address sourceBundleAddress, address targetBundleAddress, address tokenAddress, uint256 amount);

    /// @notice Emitted on offset specific on behalf of and offset specific (which is just a special case of the on behalf of)
    /// @param bundleAddress - the bundle from which to offset
    /// @param tokenAddress - the token to offset
    /// @param account - address of the account that is granted the offset
    /// @param amount - number f tokens
    event OffsetSpecificOnBehalfOf(address bundleAddress, address tokenAddress, address account, uint256 amount);

    constructor(CarbonCreditTerminalStation station_) {
        station = station_;
    }

    /// @dev see IActionInterface, tokens are burned here, if the token is not synced one has to sync and retry
    function sendTokens(uint256 destination_, address tokenAddress_, address recipient_, uint256 amount_) public payable {
        require(amount_ > 0, "amount must be greater than 0");

        WrappedCarbonCreditToken wToken = station.getToken(tokenAddress_);
        if (address(wToken.permissionList()) != address(0)) {
            require(wToken.permissionList().hasPermission(msg.sender), 'the sender is not permitted to send this token');
            require(wToken.permissionList().hasPermission(recipient_), 'the recipient is not permitted to receive this token');
        }

        station.burn(wToken, msg.sender, amount_);
        station.send{value: msg.value}(
            destination_,
            abi.encodeWithSelector(
                IHandlerInterface.handleReceiveTokens.selector,
                station.selfToMainChainTokenMapping(tokenAddress_),
                recipient_,
                amount_
            )
        );
        emit TokensSend(address(wToken), destination_, msg.sender, recipient_, amount_);
    }

    /// @dev see IActionInterface, bundles are burned here
    function sendBundleTokens(uint256 destination_, address wBundleAddress_, address recipient_, uint256 amount_) external payable {
        require(amount_ > 0, "amount must be greater than 0");

        WrappedCarbonCreditBundleToken wBundle = station.getBundle(wBundleAddress_);
        station.burn(wBundle, msg.sender, amount_);
        station.send{value: msg.value}(
            destination_,
            abi.encodeWithSelector(
              IHandlerInterface.handleReceiveBundleTokens.selector,
              station.selfToMainChainBundleMapping(wBundleAddress_),
              recipient_,
              amount_
            )
        );
        emit BundleTokensSend(address(wBundle), destination_, msg.sender, recipient_, amount_);
    }

    /// @notice swaps source bundle for the target via the given token for the given amount
    /// @dev bundle tokens are send back on failure, a small fee to cover the tx in terms of the bundle may occur
    /// @param wSourceBundle_ - the source bundle
    /// @param wTargetBundle_ - the target bundle
    /// @param wToken_ - the token to swap from source to target
    /// @param amount_ - the amount of tokens to swap
    function swapBundle(
        WrappedCarbonCreditBundleToken wSourceBundle_, WrappedCarbonCreditBundleToken wTargetBundle_,
        WrappedCarbonCreditToken wToken_, uint256 amount_
    ) external payable {
        require(wSourceBundle_.hasToken(wToken_), "token must be eligible for source");
        require(wTargetBundle_.hasToken(wToken_), "token must be eligible for target");
        require(!wTargetBundle_.pausedForDeposits(wToken_), "token is paused for bundling");


        station.burn(wSourceBundle_, msg.sender, amount_);
        station.send{value: msg.value}(
            station.mainChainId(),
            abi.encodeWithSelector(
                MainHandler.handleSwapBundle.selector,
                station.selfDestination(),
                station.selfToMainChainBundleMapping(address(wSourceBundle_)),
                station.selfToMainChainBundleMapping(address(wTargetBundle_)),
                station.selfToMainChainTokenMapping(address(wToken_)),
                msg.sender,
                amount_
            )
        );
        emit BundleSwapped(address(wSourceBundle_), address(wTargetBundle_), address(wToken_), amount_);
    }

    /// @notice Offsets a specific token from a bundle on behalf of a user
    /// @dev bundle tokens are send back on failure, a small fee to cover the tx in terms of the bundle may occur
    /// @param wBundle_ - the bundle from which to offset
    /// @param wToken_ - the token to offset
    /// @param account_ - address of the account that is granted the offset
    /// @param amount_ - number of tokens in question
    function offsetSpecificOnBehalfOf(
        WrappedCarbonCreditBundleToken wBundle_, WrappedCarbonCreditToken wToken_, address account_, uint256 amount_
    ) public payable {
        require(wBundle_.hasToken(wToken_), "token must be eligible for the bundle");
        station.burn(wBundle_, msg.sender, amount_);
        station.send{value: msg.value}(
            station.mainChainId(),
            abi.encodeWithSelector(
                MainHandler.handleOffsetSpecificOnBehalfOf.selector,
                station.selfDestination(),
                station.selfToMainChainBundleMapping(address(wBundle_)),
                station.selfToMainChainTokenMapping(address(wToken_)),
                msg.sender,
                account_,
                amount_
            )
        );
        emit OffsetSpecificOnBehalfOf(address(wBundle_), address(wToken_), account_, amount_);
    }

    /// @notice Offset in the name of the sender
    /// @dev see offsetSpecificOnBehalfOf, this is just a special case convenience function
    function offsetSpecific(
        WrappedCarbonCreditBundleToken wBundle_, WrappedCarbonCreditToken wToken_, uint256 amount_
    ) external payable {
        offsetSpecificOnBehalfOf(wBundle_, wToken_, msg.sender, amount_);
    }

    /// @notice inject a token into a bundle
    /// @dev tokens are send back on failure, a small fee to cover the tx in terms of the bundle may occur
    /// @param wBundle_ - the bundle to receive
    /// @param wToken_ - the token to bundle
    /// @param amount_ the amount of tokens
    function bundle(
        WrappedCarbonCreditBundleToken wBundle_, WrappedCarbonCreditToken wToken_, uint256 amount_
    ) external payable {
        require(wBundle_.hasToken(wToken_), "token must be eligible for the bundle");
        require(!wBundle_.pausedForDeposits(wToken_), "token is paused for bundling");
        station.burn(wToken_, msg.sender, amount_);
        station.send{value: msg.value}(
            station.mainChainId(),
            abi.encodeWithSelector(
                MainHandler.handleBundle.selector,
                station.selfDestination(),
                station.selfToMainChainBundleMapping(address(wBundle_)),
                station.selfToMainChainTokenMapping(address(wToken_)),
                msg.sender,
                amount_
            )
        );

        emit Bundle(msg.sender, amount_, address(wToken_));
    }

    /// @notice takes a token out of a bundle
    /// @dev bundle tokens are send back on failure, a small fee to cover the tx in terms of the bundle may occur
    /// @param wBundle_ - the bundle to give up
    /// @param wToken_ - the token to receive
    /// @param amount_ the amount of tokens
    function unbundle(
        WrappedCarbonCreditBundleToken wBundle_, WrappedCarbonCreditToken wToken_, uint256 amount_
    ) external payable {
        require(wBundle_.hasToken(wToken_), "token must be eligible for the bundle");

        station.burn(wBundle_, msg.sender, amount_);
        station.send{value: msg.value}(
            station.mainChainId(),
            abi.encodeWithSelector(
                MainHandler.handleUnbundle.selector,
                station.selfDestination(),
                station.selfToMainChainBundleMapping(address(wBundle_)),
                station.selfToMainChainTokenMapping(address(wToken_)),
                msg.sender,
                amount_
            )
        );
        emit Unbundle(msg.sender, amount_, address(wToken_));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts/access/Ownable.sol';
import "../../CarbonCreditToken.sol";
import "./WrappedCarbonCreditToken.sol";
import "./WrappedCarbonCreditBundleToken.sol";
import "../CarbonCreditTerminalStation.sol";
import "../../interfaces/ICarbonCreditPermissionList.sol";
import "../interfaces/IHandlerInterface.sol";

/// @author FlowCarbon LLC
/// @title A terminal handler implementation
contract TerminalHandler is Ownable, IHandlerInterface {

    CarbonCreditTerminalStation station;

    constructor(CarbonCreditTerminalStation station_) {
        station = station_;
        transferOwnership(address(station_));
    }

    /// @dev callback to sync a token
    /// @param originalAddress_ - the address on the main chain
    /// @param name_ - the name of the token
    /// @param symbol_ - the symbol of the token
    /// @param details_ the details of the token
    /// @param originalPermissionListAddress_ - the permission list of the token on the main chain
    function handleSyncToken(
        address originalAddress_, string memory name_, string memory symbol_,
        CarbonCreditToken.TokenDetails memory details_, address originalPermissionListAddress_
    ) external onlyOwner {
        WrappedCarbonCreditToken wToken;
        ICarbonCreditPermissionList wList = originalPermissionListAddress_ == address(0)
            ?  ICarbonCreditPermissionList(address(0))
            : ICarbonCreditPermissionList(station.mainChainToSelfPermissionListMapping(originalPermissionListAddress_));

        if (station.mainChainToSelfTokenMapping(originalAddress_) == address(0)) {
            wToken = station.createToken(originalAddress_, name_, symbol_, details_, wList);
        } else {

            wToken = WrappedCarbonCreditToken(station.mainChainToSelfTokenMapping(originalAddress_));
            station.updatePermissionList(wToken, wList);
        }
    }

    /// @dev callback to sync a bundle
    /// @param originalAddress_ - the bundle on the main chain
    /// @param name_ - name of the bundle
    /// @param symbol_ - the symbol of the bundle
    /// @param vintage_ - minimum vintage requirements of this bundle
    /// @param feeDivisor_ - the fee divisor of this bundle
     function handleSyncBundle(
        address originalAddress_, string memory name_, string memory symbol_, uint16 vintage_, uint256 feeDivisor_
    ) external onlyOwner {
        WrappedCarbonCreditBundleToken wBundleToken;
        if (station.mainChainToSelfBundleMapping(originalAddress_) == address(0)) {
            wBundleToken = station.createBundle(originalAddress_, name_, symbol_, vintage_, feeDivisor_);
        } else {
            wBundleToken = WrappedCarbonCreditBundleToken(station.mainChainToSelfBundleMapping(originalAddress_));
            station.incrementVintage(wBundleToken, vintage_);
        }
    }

    /// @dev syncs a given permission list
    /// @param originalAddress_ the address on the main chain
    /// @param name_ the name of the permission list
    function handleSyncPermissionList(
        address originalAddress_, string memory name_
    ) external onlyOwner {
        // it is guaranteed by the main chain to be only synced once
        station.createPermissionList(originalAddress_, name_);
    }

    /// @dev updates a permission list, guaranteed by the main chain that this exists
    /// @param originalPermissionListAddress_ - the address of this permission list on the main chain
    /// @param account_ - the address of the account to add or remove
    /// @param hasPermission_ - flag if permission is granted or removed
    function handleRegisterPermission(address originalPermissionListAddress_, address account_, bool hasPermission_) external onlyOwner {
        station.setMultiChainPermission(
            ICarbonCreditPermissionList(station.mainChainToSelfPermissionListMapping(originalPermissionListAddress_)),
            account_,
            hasPermission_
        );
    }

    /// @dev updates a token, guaranteed by the main chain that this exists
    /// @param originalBundleAddress_ - the address of bundle that should add / remove the token
    /// @param originalTokenAddress_ - the address of the token
    /// @param isAdded_ - flag if added or removed
    /// @param isPaused_ - flag if token is paused
    function handleRegisterTokenForBundle(
        address originalBundleAddress_, address originalTokenAddress_, bool isAdded_, bool isPaused_
    ) external onlyOwner {
        station.registerTokenForBundle(
            WrappedCarbonCreditBundleToken(station.mainChainToSelfBundleMapping(originalBundleAddress_)),
            WrappedCarbonCreditToken(station.mainChainToSelfTokenMapping(originalTokenAddress_)),
            isAdded_,
            isPaused_
        );
    }

    /// @dev see IHandlerInterface
    function handleReceiveTokens(
        address originalTokenAddress_, address recipient_, uint256 amount_
    ) external onlyOwner {
        station.mint(
            WrappedCarbonCreditToken(station.mainChainToSelfTokenMapping(originalTokenAddress_)),
            recipient_,
            amount_
        );
    }

    /// @dev see IHandlerInterface
    function handleReceiveBundleTokens(
        address originalBundleAddress_, address recipient_, uint256 amount_
    ) external onlyOwner {
        station.mint(
            WrappedCarbonCreditBundleToken(station.mainChainToSelfBundleMapping(originalBundleAddress_)),
            recipient_,
            amount_
        );
    }

    /// @dev handles an offset specific by increasing the offset for that token
    /// @param originalTokenAddress_ - the address of the token on the main chain
    /// @param beneficiary_ - the receiver of the token
    /// @param amount_ - the amount of the token
    function handleOffsetSpecificOnBehalfOfCallback(
        address originalTokenAddress_, address beneficiary_, uint256 amount_
    ) external onlyOwner {
        station.increaseOffset(
            WrappedCarbonCreditToken(station.mainChainToSelfTokenMapping(originalTokenAddress_)),
            beneficiary_,
            amount_
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

/// @author FlowCarbon LLC
/// @title A bridge receiver interface to receive messages from a remote chain
interface IBridgeReceiver {

    /// @notice hook point to receive a message
    /// @param source_ - the chain id from which this message was received
    /// @param payload_ - the raw payload
    function receiveMessage(uint256 source_, bytes memory payload_) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

/// @author FlowCarbon LLC
/// @title A no-vendor-lock bridge interface to add configurable message bridges to this protocol
interface IBridgeInterface {

    /// @dev The identifier should be in the format BRIDGE_NAME_v1.0.0
    /// @return keccak256 encoded identifier
    function getIdentifier() external pure returns (bytes32);

    /// @notice Connect a contract on the terminal chain to this chain
    /// @dev the target contract needs to be an IBridgeReceiver
    /// @param destination_ - the chain id with the respective bridge endpoint contract
    /// @param contractAddress_ - the address on the terminal chain
    function registerRemoteContract(uint256 destination_, address contractAddress_) external;

    /// @notice Send a message to the remote chain
    /// @param destination_ - the chain id to which we want to send the message
    /// @param payload_ - the raw payload to send
    function sendMessage(uint256 destination_, bytes memory payload_) payable external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '../interfaces/ICarbonCreditTokenInterface.sol';

/// @author FlowCarbon LLC
/// @title An Abstract Carbon Credit Token
abstract contract AbstractToken is Initializable, OwnableUpgradeable, ERC20Upgradeable, ICarbonCreditTokenInterface {

    /// @notice The time and amount of a specific offset
    struct OffsetEntry {
        uint time;
        uint amount;
    }

    /// @notice Emitted when the underlying token is offset
    /// @param amount - The amount of tokens offset
    /// @param checksum - The checksum associated with the offset event
    event FinalizeOffset(uint256 amount, bytes32 checksum);

    /// @notice User mapping to the amount of offset tokens
    mapping (address => uint256) internal _offsetBalances;

    /// @notice Number of tokens offset by the protocol that have not been finalized yet
    uint256 public pendingBalance;

    /// @notice Number of tokens fully offset
    uint256 public offsetBalance;

    /// @dev Mapping of user to offsets to make them discoverable
    mapping(address => OffsetEntry[]) private _offsets;

    function __AbstractToken_init(string memory name_, string memory symbol_, address owner_) internal onlyInitializing {
        require(bytes(name_).length > 0, 'name is required');
        require(bytes(symbol_).length > 0, 'symbol is required');
        __ERC20_init(name_, symbol_);
        __Ownable_init();
        transferOwnership(owner_);
    }

    /// @dev See ICarbonCreditTokenInterface
    function offsetCountOf(address address_) external view returns (uint256) {
        return _offsets[address_].length;
    }

    /// @dev See ICarbonCreditTokenInterface
    function offsetAmountAtIndex(address address_, uint256 index_) external view returns(uint256) {
        return _offsets[address_][index_].amount;
    }

    /// @dev See ICarbonCreditTokenInterface
    function offsetTimeAtIndex(address address_, uint256 index_) external view returns(uint256) {
        return _offsets[address_][index_].time;
    }

    //// @dev See ICarbonCreditTokenInterface
    function offsetBalanceOf(address account_) external view returns (uint256) {
        return _offsetBalances[account_];
    }

    /// @dev Common functionality of the two offset functions
    function _offset(address account_, uint256 amount_) internal {
        _burn(_msgSender(), amount_);
        _offsetBalances[account_] += amount_;
        pendingBalance += amount_;
        _offsets[account_].push(OffsetEntry(block.timestamp, amount_));

        emit Offset(account_, amount_);
    }

    /// @dev See ICarbonCreditTokenInterface
    function offsetOnBehalfOf(address account_, uint256 amount_) external {
        _offset(account_, amount_);
    }

    /// @dev See ICarbonCreditTokenInterface
    function offset(uint256 amount_) external {
        _offset(_msgSender(), amount_);
    }

    /// @dev Overridden to disable renouncing ownership
    function renounceOwnership() public virtual override onlyOwner {
        revert('renouncing ownership is disabled');
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol';
import './abstracts/AbstractFactory.sol';
import './CarbonCreditToken.sol';
import './CarbonCreditPermissionList.sol';
import './CarbonCreditBundleTokenFactory.sol';

/// @author FlowCarbon LLC
/// @title A Carbon Credit Token Factory
contract CarbonCreditTokenFactory is AbstractFactory {

    using ClonesUpgradeable for address;

    CarbonCreditBundleTokenFactory public carbonCreditBundleTokenFactory;

    /// @param implementationContract_ - the contract that is used a implementation base for new tokens
    /// @param owner_ - the owner of this contract
    constructor (CarbonCreditToken implementationContract_, address owner_) {
        swapImplementationContract(address(implementationContract_));
        transferOwnership(owner_);
    }

    /// @notice Set the carbon credit bundle token factory which is passed to token instances
    /// @param carbonCreditBundleTokenFactory_ - The factory instance associated with new tokens
    function setCarbonCreditBundleTokenFactory(CarbonCreditBundleTokenFactory carbonCreditBundleTokenFactory_) external onlyOwner {
        carbonCreditBundleTokenFactory = carbonCreditBundleTokenFactory_;
    }

    /// @notice Deploy a new carbon credit token
    /// @param name_ - the name of the new token, should be unique within the Flow Carbon Ecosystem
    /// @param symbol_ - the token symbol of the ERC-20, should be unique within the Flow Carbon Ecosystem
    /// @param details_ - token details to define the fungibillity characteristics of this token
    /// @param permissionList_ - the permission list of this token
    /// @param owner_ - the owner of the new token, able to mint and finalize offsets
    /// @return the address of the newly created token
    function createCarbonCreditToken(
        string memory name_,
        string memory symbol_,
        CarbonCreditToken.TokenDetails memory details_,
        ICarbonCreditPermissionList permissionList_,
        address owner_
    )
    onlyOwner external returns (address)
    {
        require(address(carbonCreditBundleTokenFactory) != address(0), 'bundle token factory is not set');
        CarbonCreditToken token = CarbonCreditToken(implementationContract.clone());
        token.initialize(name_, symbol_, details_, permissionList_, owner_, carbonCreditBundleTokenFactory);
        finalizeCreation(address(token));
        return address(token);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '../CarbonCreditToken.sol';
import '../CarbonCreditBundleToken.sol';
import '../CarbonCreditBundleTokenFactory.sol';

/// @author FlowCarbon LLC
/// @title A Carbon Credit Integrity Library - cross check eligibility between bundles and tokens
library CarbonCreditIntegrity {

    /// @dev Reverts if a bundle does not contain a token
    function requireHasToken(CarbonCreditBundleToken bundle_, CarbonCreditToken token_) public view {
        require(bundle_.hasToken(token_), 'token is not part of bundle');
    }

    /// @dev Reverts if the vintage is outdated
    function requireVintageNotOutdated(CarbonCreditBundleToken bundle_, CarbonCreditToken token_) public view {
        require(token_.vintage() >= bundle_.vintage(), 'token outdated');
    }

    /// @dev Reverts if the token is not compatible with the bundle
    function requireIsEligibleForBundle(CarbonCreditBundleToken bundle_, CarbonCreditToken token_) external view {
        require(!bundle_.hasToken(token_), 'token already added to bundle');
        require(
            bundle_.carbonCreditTokenFactory().hasContractDeployedAt(address(token_)),
            'token is not a carbon credit token'
        );
        require(token_.vintage() >= bundle_.vintage(), 'vintage mismatch');

        if (bundle_.tokenCount() > 0) {
            CarbonCreditBundleTokenFactory existingTokenFactory = CarbonCreditToken(bundle_.tokenAtIndex(0)).carbonCreditBundleTokenFactory();
            require(
                address(token_.carbonCreditBundleTokenFactory()) ==  address(existingTokenFactory),
                'all tokens must share the same bundle token factory'
            );
        }
    }

    /// @dev Reverts if the token can not be bundled with the given amount to the given bundle
    function requireCanBundleToken(CarbonCreditBundleToken bundle_, CarbonCreditToken token_, uint256 amount_) external view {
        requireHasToken(bundle_, token_);
        requireVintageNotOutdated(bundle_, token_);
        require(amount_ > 0, 'amount may not be zero');
        require(!bundle_.pausedForDeposits(token_), 'token is paused for bundling');
    }

    /// @dev Reverts if the token can not be unbundled with the given amount to the given bundle
    function requireCanUnbundleToken(CarbonCreditBundleToken bundle_, CarbonCreditToken token_, uint256 amount_) external view {
        requireHasToken(bundle_, token_);
        require(token_.balanceOf(address(bundle_)) - bundle_.reservedAmount(token_) >= amount_, 'amount exceeds the token balance');
        require(amount_ > 0, 'amount may not be zero');
        require(amount_ >= bundle_.feeDivisor(), 'fee divisor exceeds amount');
    }

    /// @dev Reverts if the given checksum / amount combination cannot be finalized for the given bundle and token
    function requireCanFinalizeOffset(CarbonCreditBundleToken bundle_, CarbonCreditToken token_, uint256 amount_, bytes32 checksum_) external view {
        requireHasToken(bundle_, token_);
        require(checksum_ > 0, 'checksum is required');
        require(bundle_.amountOffsettedWithChecksum(checksum_) == 0, 'checksum was already used');
        require(amount_ <= bundle_.pendingBalance(), 'offset exceeds pending balance');
        require(token_.balanceOf(address(bundle_)) >= amount_, 'amount exceeds the token balance');
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
     * @dev Moves `amount` of tokens from `from` to `to`.
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

/// @author FlowCarbon LLC
/// @title The common interface of carbon credit tokens
interface ICarbonCreditTokenInterface is IERC20Upgradeable {

    /// @notice Emitted when someone offsets carbon tokens
    /// @param account - The account credited with offsetting
    /// @param amount - The amount of carbon that was offset
    event Offset(address account, uint256 amount);

    /// @notice Offset on behalf of the user
    /// @dev This will only offset tokens send by msg.sender, increases tokens awaiting finalization
    /// @param amount_ - The number of tokens to be offset
    function offset(uint256 amount_) external;

    /// @notice Offsets on behalf of the given address
    /// @dev This will offset tokens on behalf of account, increases tokens awaiting finalization
    /// @param account_ - The address of the account to offset on behalf of
    /// @param amount_ - The number of tokens to be offset
    function offsetOnBehalfOf(address account_, uint256 amount_) external;

    /// @notice Return the balance of tokens offsetted by the given address
    /// @param account_ - The account for which to check the number of tokens that were offset
    /// @return The number of tokens offsetted by the given account
    function offsetBalanceOf(address account_) external view returns (uint256);

    /// @notice Returns the number of offsets for the given address
    /// @dev This is a pattern to discover all offsets and their occurrences for a user
    /// @param address_ - Address of the user that offsetted the tokens
    function offsetCountOf(address address_) external view returns(uint256);

    /// @notice Returns amount of offsetted tokens for the given address and index
    /// @param address_ - Address of the user who did the offsets
    /// @param index_ - Index into the list
    function offsetAmountAtIndex(address address_, uint256 index_) external view returns(uint256);

    /// @notice Returns the timestamp of an offset for the given address and index
    /// @param address_ - Address of the user who did the offsets
    /// @param index_ - Index into the list
    function offsetTimeAtIndex(address address_, uint256 index_) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

/// @author FlowCarbon LLC
/// @title The common interface of carbon credit permission lists
interface ICarbonCreditPermissionList {

    /// @notice Emitted when the multi chain list state changes
    /// @param account - The account for which permissions have changed
    /// @param hasPermission - Flag indicating whether permissions were granted or revoked
    event MultiChainPermissionChanged(address account, bool hasPermission);

    /// @notice Emitted when the single chain list changed
    /// @param account - The account for which permissions have changed
    /// @param hasPermission - Flag indicating whether permissions were granted or revoked
    event SingleChainPermissionChanged(address account, bool hasPermission);

    // @notice Return the name of the list
    function name() external view returns (string memory);

    // @notice Grant or revoke the permission of an account that is synced across chains
    // @param account_ - The address to which to grant or revoke permissions
    // @param hasPermission_ - Flag indicating whether to grant or revoke permissions
    function setMultiChainPermission(address account_, bool hasPermission_) external;

    // @notice Grant or revoke permissions of multiple multi chain accounts
    // @param account_ - The addresses to which to grant or revoke permissions
    // @param hasPermission_ - Flag indicating whether to grant or revoke permissions
    function setMultiChainPermissions(address[] memory accounts_, bool[] memory permissions_) external;

    /// @notice Checks if an account is permissioned as multi chain address
    /// @param account_ - The address to check
    /// @return True if the address is permissioned
    function hasMultiChainPermission(address account_) external view returns (bool);

    // @notice Return the address at the given list index if it is on the multi chain address list
    // @param index_ - The index into the list
    // @return Address at the given index
    function multiChainAddressAt(uint256 index_) external view returns (address);

    // @notice Get the number of multi chain accounts that have been granted permission
    // @return Number of accounts that have been granted permission
    function multiChainAddressCount() external view returns (uint256);

    // @notice Get an array containing all multi chain addresses that have been granted permission
    // @return Array containing all multi chain addresses that have been granted permission
    function multiChainAddresses() external view returns (address[] memory);

    // @notice Grant or revoke the permission of an account on this chain only
    // @param account_ - The address to which to grant or revoke permissions
    // @param hasPermission_ - Flag indicating whether to grant or revoke permissions
    function setSingleChainPermission(address account_, bool hasPermission_) external;

    // @notice Grant or revoke permissions of an account on this chain only
    // @param account_ - The address to which to grant or revoke permissions
    // @param hasPermission_ - Flag indicating whether to grant or revoke permissions
    function setSingleChainPermissions(address[] memory accounts_, bool[] memory permissions_) external;

    /// @notice Checks is an address is permissioned on this chain only
    /// @param account_ - The address to check
    /// @return True if the address is permissioned
    function hasSingleChainPermission(address account_) external view returns (bool);

    /// @notice Discovery function for the single chain counts
    /// @return the number of addresses on this list
    function singleChainAddressCount() external view returns (uint256);

    /// @notice Discovery function for the single chain address
    /// @param index_ - the index of the address
    /// @return the address
    function singleChainAddressAt(uint256 index_) external view returns (address);

    // @notice Get an array containing all addresses that have been granted permission on this chain
    // @return Array containing all addresses that have been granted permission this chain
    function singleChainAddresses() external view returns (address[] memory);

    // @notice Return the current permissions of an account on this chain (can be single or multi chain)
    // @param account_ - The address to check
    // @return Flag indicating whether this account has permission or not
    function hasPermission(address account_) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol';
import './abstracts/AbstractFactory.sol';
import './CarbonCreditBundleToken.sol';
import './CarbonCreditToken.sol';
import './CarbonCreditTokenFactory.sol';
import './abstracts/AbstractToken.sol';

/// @author FlowCarbon LLC
/// @title A Carbon Credit Bundle Token Factory
contract CarbonCreditBundleTokenFactory is AbstractFactory {

    using ClonesUpgradeable for address;

    /// @notice The token factory for carbon credit tokens
    CarbonCreditTokenFactory public carbonCreditTokenFactory;

    /// @param implementationContract_ - The contract to be used as implementation base for new tokens
    /// @param owner_ - The owner of the contract
    /// @param carbonCreditTokenFactory_ - The factory used to deploy carbon credits tokens
    constructor (CarbonCreditBundleToken implementationContract_, address owner_, CarbonCreditTokenFactory carbonCreditTokenFactory_) {
        require(address(carbonCreditTokenFactory_) != address(0), 'carbonCreditTokenFactory_ may not be zero address');
        swapImplementationContract(address(implementationContract_));
        carbonCreditTokenFactory = carbonCreditTokenFactory_;
        transferOwnership(owner_);
    }

    /// @notice Deploy a new carbon credit bundle token
    /// @param name_ - The name of the new token, should be unique within the Flow Carbon Ecosystem
    /// @param symbol_ - The token symbol of the ERC-20, should be unique within the Flow Carbon Ecosystem
    /// @param vintage_ - The minimum vintage of this bundle
    /// @param tokens_ - Initial set of tokens
    /// @param owner_ - The owner of the bundle token, eligible for fees and able to finalize offsets
    /// @param feeDivisor_ - The fee divisor that should be taken upon unbundling
    /// @return The address of the newly created token
    function createCarbonCreditBundleToken(
        string memory name_,
        string memory symbol_,
        uint16 vintage_,
        CarbonCreditToken[] memory tokens_,
        address owner_,
        uint256 feeDivisor_
    ) onlyOwner external returns (address) {
        CarbonCreditBundleToken token = CarbonCreditBundleToken(implementationContract.clone());
        token.initialize(name_, symbol_, vintage_, tokens_, owner_, feeDivisor_, carbonCreditTokenFactory);
        finalizeCreation(address(token));
        return address(token);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import './interfaces/ICarbonCreditPermissionList.sol';
import './CarbonCreditPermissionList.sol';

/// @author FlowCarbon LLC
/// @title List of accounts permitted to transfer or receive carbon credit tokens
contract CarbonCreditPermissionList is ICarbonCreditPermissionList, OwnableUpgradeable {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    EnumerableSetUpgradeable.AddressSet private _multiChainAddresses;
    EnumerableSetUpgradeable.AddressSet private _singleChainAddresses;

    /// @dev The ecosystem-internal name given to the permission list
    string private _name;

    /// @param name_ - The name of the permission list
    /// @param owner_ - The owner of the permission list, allowed manage it's entries
    function initialize(string memory name_, address owner_) external initializer {
        __Ownable_init();
        _name = name_;
        transferOwnership(owner_);
    }

    // @dev see ICarbonCreditPermissionList
    function name() external view returns (string memory) {
        return _name;
    }

    // @dev see ICarbonCreditPermissionList
    function setMultiChainPermission(address account_, bool hasPermission_) onlyOwner public {
        require(account_ != address(0), 'account is required');
        bool changed;
        if (hasPermission_) {
            changed = _multiChainAddresses.add(account_);
        } else {
            changed = _multiChainAddresses.remove(account_);
        }
        if (changed) {
            emit MultiChainPermissionChanged(account_, hasPermission_);
        }
    }

    // @dev see ICarbonCreditPermissionList
    function setMultiChainPermissions(address[] memory accounts_, bool[] memory permissions_) onlyOwner external {
        require(accounts_.length == permissions_.length, 'accounts and permissions must have the same length');
        for (uint256 i=0; i < accounts_.length; i++) {
            setMultiChainPermission(accounts_[i], permissions_[i]);
        }
    }

    // @dev see ICarbonCreditPermissionList
    function hasMultiChainPermission(address account_) external view returns (bool) {
        return _multiChainAddresses.contains(account_);
    }

    // @dev see ICarbonCreditPermissionList
    function multiChainAddressAt(uint256 index_) external view returns (address) {
        return _multiChainAddresses.at(index_);
    }

    // @dev see ICarbonCreditPermissionList
    function multiChainAddressCount() external view returns (uint256) {
        return _multiChainAddresses.length();
    }

    // @dev see ICarbonCreditPermissionList
    function multiChainAddresses() external view returns (address[] memory) {
        return _multiChainAddresses.values();
    }

    // @dev see ICarbonCreditPermissionList
    function setSingleChainPermission(address account_, bool hasPermission_) onlyOwner public {
        require(account_ != address(0), 'account is required');
        bool changed;
        if (hasPermission_) {
            changed = _singleChainAddresses.add(account_);
        } else {
            changed = _singleChainAddresses.remove(account_);
        }
        if (changed) {
            emit SingleChainPermissionChanged(account_, hasPermission_);
        }
    }

    // @dev see ICarbonCreditPermissionList
    function setSingleChainPermissions(address[] memory accounts_, bool[] memory permissions_) onlyOwner external {
        require(accounts_.length == permissions_.length, 'accounts and permissions must have the same length');
        for (uint256 i=0; i < accounts_.length; i++) {
            setSingleChainPermission(accounts_[i], permissions_[i]);
        }
    }

    /// @dev see ICarbonCreditContractPermissionList
    function hasSingleChainPermission(address account_) external view returns (bool) {
        return _singleChainAddresses.contains(account_);
    }

    /// @dev see ICarbonCreditContractPermissionList
    function singleChainAddressCount() external view returns (uint256) {
        return _singleChainAddresses.length();
    }

    /// @dev see ICarbonCreditContractPermissionList
    function singleChainAddressAt(uint256 index_) external view returns (address) {
        return _singleChainAddresses.at(index_);
    }

    // @dev see ICarbonCreditPermissionList
    function singleChainAddresses() external view returns (address[] memory) {
        return _singleChainAddresses.values();
    }

    // @dev see ICarbonCreditPermissionList
    function hasPermission(address account_) external view returns (bool) {
        return _multiChainAddresses.contains(account_) || _singleChainAddresses.contains(account_);
    }

    /// @dev Overridden to disable renouncing ownership
    function renounceOwnership() public virtual override onlyOwner {
        revert('renouncing ownership is disabled');
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {SafeERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import {AbstractFactory, CarbonCreditBundleTokenFactory, CarbonCreditBundleToken} from './CarbonCreditBundleTokenFactory.sol';
import {CarbonCreditTokenFactory, CarbonCreditToken} from './CarbonCreditTokenFactory.sol';
import {CarbonCreditRakeback, CarbonCreditRakebackFactory} from './CarbonCreditRakebackFactory.sol';

/// @author FlowCarbon LLC
/// @title A conductor to wire bundles with it's respective rakeback contract
contract CarbonCreditBundleConductor is Ownable {

    /// @notice Emitted when a bundle token is connected to a new rakeback contract
    /// @param bundleTokenAddress - The respective bundle
    /// @param rakebackContractAddress - The respective rakeback
    event SetRakeback(address bundleTokenAddress, address rakebackContractAddress);

    /// @notice Emitted when this contract is retired and the factories are released
    /// @param newOwner - the new owner of the underlying factories
    event FactoriesReleased(address newOwner);

    using SafeERC20Upgradeable for CarbonCreditBundleToken;
    using SafeERC20Upgradeable for CarbonCreditToken;

    /// @dev this contract maintains and owns the bundle factory
    CarbonCreditBundleTokenFactory public carbonCreditBundleTokenFactory;

    /// @dev this contract maintains and owns the rakeback factory
    CarbonCreditRakebackFactory public carbonCreditRakebackFactory;

    /// @notice Easy discovery of bundle tokens and their current active rakeback
    mapping (CarbonCreditBundleToken => CarbonCreditRakeback) public rakebackContracts;

    constructor (
        CarbonCreditBundleTokenFactory carbonCreditBundleTokenFactory_,
        CarbonCreditRakebackFactory carbonCreditRakebackFactory_,
        address owner_
    ) {
        transferOwnership(owner_);

        carbonCreditBundleTokenFactory = carbonCreditBundleTokenFactory_;
        carbonCreditRakebackFactory = carbonCreditRakebackFactory_;

        for (uint256 i=0; i < carbonCreditRakebackFactory.deployedContractsCount(); ++i) {
            CarbonCreditRakeback rakeback = CarbonCreditRakeback(carbonCreditRakebackFactory.deployedContractAt(i));
            CarbonCreditBundleToken bundleToken = rakeback.bundle();
            _setBundleAndRakeback(bundleToken, rakeback);
        }
    }

    /// @notice Access function to the underlying factories to swap the implementation
    /// @param factoryAddress_ - the address of the factory
    /// @param newImplementationAddress_ - the address of the new implementation
    function swapFactoryImplementation(address factoryAddress_, address newImplementationAddress_) onlyOwner external {
        AbstractFactory factory;
        if (factoryAddress_ == address(carbonCreditBundleTokenFactory)) {
            factory = CarbonCreditTokenFactory(factoryAddress_);
        } else if (factoryAddress_ == address(carbonCreditRakebackFactory)) {
            factory = CarbonCreditRakebackFactory(factoryAddress_);
        } else {
            revert("factory address unknown");
        }
        factory.swapImplementationContract(newImplementationAddress_);
    }

    /// @notice retire this conductor contract by releasing the ownership of the underlying factories
    /// @param newOwner_ - address of the new owner
    function releaseFactories(address newOwner_) external onlyOwner {
        require(newOwner_ != address(0), "owner may not be zero address");

        carbonCreditBundleTokenFactory.transferOwnership(newOwner_);
        carbonCreditRakebackFactory.transferOwnership(newOwner_);

        emit FactoriesReleased(newOwner_);
    }

    /// @notice Creates a new bundle with an empty default rakeback contract
    /// @dev see carbonCreditBundleTokenFactory.createCarbonCreditBundleToken() for param definitions.
    function createBundleWithRakeback(
        string memory name_,
        string memory symbol_,
        uint16 vintage_,
        CarbonCreditToken[] memory tokens_,
        address owner_,
        uint256 feeDivisor_
    ) onlyOwner external {
        CarbonCreditBundleToken bundleToken = CarbonCreditBundleToken(
            carbonCreditBundleTokenFactory.createCarbonCreditBundleToken(
                name_, symbol_, vintage_, tokens_, owner_, feeDivisor_
            )
        );

        _setBundleAndRakeback(
            bundleToken,
            CarbonCreditRakeback(carbonCreditRakebackFactory.createCarbonCreditRakeback(bundleToken, owner_))
        );
    }

    /// @notice Creates a new rakeback for the given bundle
    /// @param bundle_ - the bundle that should be upgraded to the latest implementation
    /// @dev note that the new rakeback is in the empty state
    function createNewRakebackImplementationForBundle(CarbonCreditBundleToken bundle_) onlyOwner external {
        _setBundleAndRakeback(
            bundle_,
            CarbonCreditRakeback(carbonCreditRakebackFactory.createCarbonCreditRakeback(bundle_, bundle_.owner()))
        );
    }

    /// @notice bundle the given amount of tokens to the given bundle
    /// @dev requires approval to transferFrom the sender, this is just to have the same interface for terminal stations
    /// @param bundle_ - the bundle token to bundle from
    /// @param token_ - the token that should be bundled
    /// @param amount_ - the amount of tokens to bundle
    function bundle(CarbonCreditBundleToken bundle_, CarbonCreditToken token_, uint256 amount_) external {
        token_.safeTransferFrom(_msgSender(), address(this), amount_);
        token_.approve(address(bundle_), amount_);
        bundle_.bundle(token_, amount_);
        bundle_.safeTransfer(_msgSender(), amount_);
    }

    /// @notice unbundle the given amount of tokens from the given bundle
    /// @dev requires approval to transferFrom the sender
    /// @param bundle_ - the bundle token to unbundle from
    /// @param token_ - the token that should be unbundled
    /// @param amount_ - the amount of tokens to unbundle
    /// @return the amount unbundled after fees
    function unbundle(CarbonCreditBundleToken bundle_, CarbonCreditToken token_, uint256 amount_) external returns (uint256) {
        CarbonCreditRakeback rakeback = _getRakebackContract(bundle_);

        bundle_.safeTransferFrom(_msgSender(), address(this), amount_);
        uint256 amountUnbundled = rakeback.unbundle(token_, amount_);
        token_.safeTransfer(_msgSender(), amountUnbundled);
        return amountUnbundled;
    }

    /// @notice Swaps the sourceBundle for the targetBundle for the given amount
    /// @dev requires approval to transferFrom the sender
    /// @param sourceBundle_ - the bundle token that one wants to swap
    /// @param targetBundle_ - the bundle token that one wants to receive
    /// @param token_ - the token to use for the swap
    /// @param amount_ - the amount of tokens to swap
    /// @return the amount of swapped tokens after the fee
    function swapBundle(
        CarbonCreditBundleToken sourceBundle_, CarbonCreditBundleToken targetBundle_,
        CarbonCreditToken token_, uint256 amount_
    ) external returns (uint256) {
        CarbonCreditRakeback rakeback = _getRakebackContract(sourceBundle_);

        sourceBundle_.safeTransferFrom(_msgSender(), address(this), amount_);
        uint amountSwapped = rakeback.swapBundle(targetBundle_, token_, amount_);
        targetBundle_.safeTransfer(_msgSender(), amountSwapped);
        return amountSwapped;
    }

    /// @notice Offset a specific token on behalf of someone else
    /// @dev requires approval to transferFrom the sender
    /// @param bundle_ - the bundle token to use for offset
    /// @param token_ - the underlying token used to offset
    /// @param account_ - the target address for the retirement
    /// @param amount_ - the amount of tokens to offset
    /// @return the amount of offsetted tokens after the fee
    function offsetSpecificOnBehalfOf(
        CarbonCreditBundleToken bundle_, CarbonCreditToken token_, address account_, uint256 amount_
    ) public returns (uint256) {
        CarbonCreditRakeback rakeback = _getRakebackContract(bundle_);

        bundle_.safeTransferFrom(_msgSender(), address(this), amount_);
        return rakeback.offsetSpecificOnBehalfOf(token_, account_, amount_);
    }

    /// @notice Offset a specific token
    /// @dev requires approval to transferFrom the sender
    /// @param bundle_ - the bundle token to use for offset
    /// @param token_ - the underlying token used to offset
    /// @param amount_ - the amount of tokens to offset
    /// @return the amount of offsetted tokens after the fee
    function offsetSpecific(
        CarbonCreditBundleToken bundle_, CarbonCreditToken token_, uint256 amount_
    ) external returns (uint256) {
        return offsetSpecificOnBehalfOf(bundle_, token_, _msgSender(), amount_);
    }

    /// @notice find out if a bundle token has a respective rakeback contract
    /// @return true if a contract exists, else false
    function hasRakeback(CarbonCreditBundleToken bundle_) public view returns (bool) {
        return address(rakebackContracts[bundle_]) != address(0);
    }

    /// @dev sets the rakeback and approves it to withdraw from this contract
    /// @param bundle_ - the bundle token that should be connected
    /// @param rakeback_ - the rakeback contract for the given bundle
    function _setBundleAndRakeback(CarbonCreditBundleToken bundle_, CarbonCreditRakeback rakeback_) internal {
        bundle_.approve(address(rakeback_), type(uint256).max);
        rakebackContracts[bundle_] = rakeback_;

        emit SetRakeback(address(bundle_), address(rakeback_));
    }

    /// @dev returns the respective rakeback for the bundle or reverts if it does not have one
    /// @param bundle_ - the bundle token for which we want the rakeback
    function _getRakebackContract(CarbonCreditBundleToken bundle_) internal view returns (CarbonCreditRakeback) {
        require(hasRakeback(bundle_), "no rakeback found");
        return CarbonCreditRakeback(rakebackContracts[bundle_]);
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts/access/Ownable.sol';
import "../../CarbonCreditBundleToken.sol";

/// @author FlowCarbon LLC
/// @title A PostageFee implementation, solely to mitigate low-level spamming
contract PostageFee is Ownable {

    /// @notice Emitted when the fee is set
    /// @param destination - fee set for a specific destination
    /// @param bundleAddress - the bundle in question
    /// @param amountNative - amount in native terms
    /// @param amountInTermsOfBundle - amount in bundle terms
    /// @param noFeeOnSuccessThreshold - threshold, if passed we'll take the fees
    event FeeSet(
        uint256 destination,
        address bundleAddress,
        uint256 amountNative,
        uint256 amountInTermsOfBundle,
        uint256 noFeeOnSuccessThreshold
    );

    struct FeeStructure {
        CarbonCreditBundleToken bundle;
        /// amount in bundle terms
        uint256 amountInBundleFee;
        // threshold, if passed we'll take the fees
        uint256 noFeeOnSuccessThreshold;
    }

    // destination to Fee Structure
    mapping(uint256 => FeeStructure[]) private _postageFees;
    // destination to native fees
    mapping(uint256 => uint256) private _nativeFees;

    constructor(address owner_) {
         transferOwnership(owner_);
    }

    /// @notice batch update for fees
    /// @dev all params are arrays of the set function
    function batchSet(
        uint256[] memory destinations_, CarbonCreditBundleToken[] memory bundles_,
        uint256[] memory amountsNative_, uint256[] memory amountsInTermsOfBundle_,
        uint256[] memory noFeeOnSuccessThresholds_
    ) external onlyOwner {
        require(destinations_.length == bundles_.length, "dimension mismatch");
        require(destinations_.length == amountsNative_.length, "dimension mismatch");
        require(destinations_.length == amountsInTermsOfBundle_.length, "dimension mismatch");
        require(destinations_.length == noFeeOnSuccessThresholds_.length, "dimension mismatch");

        for (uint256 i=0; i < destinations_.length; ++i) {
            _set(
                destinations_[i], bundles_[i], amountsNative_[i], amountsInTermsOfBundle_[i], noFeeOnSuccessThresholds_[i]
            );
        }
    }

    /// @notice update thee fee structure for a given bundle at a given a destination
    /// @param destination_ - the chain to apply the new fee structure
    /// @param bundle_ - the bundle token for the new fee structure
    /// @param amountNative_ - the amount in native terms
    /// @param amountInTermsOfBundle_ - the amount in terms of the bundle
    /// @param noFeeOnSuccessThreshold_ - threshold, if passed we'll take the fees
    function set(
        uint256 destination_, CarbonCreditBundleToken bundle_,
        uint256 amountNative_, uint256 amountInTermsOfBundle_, uint256 noFeeOnSuccessThreshold_
    ) external onlyOwner {
        _set(destination_, bundle_, amountNative_, amountInTermsOfBundle_, noFeeOnSuccessThreshold_);
    }

    /// @param destination_ - the chain to apply the new fee structure
    /// @param bundle_ - the bundle token for the new fee structure
    /// @param amountNative_ - the amount in native terms
    /// @param amountInTermsOfBundle_ - the amount in terms of the bundle
    /// @param noFeeOnSuccessThreshold_ - threshold, if passed we'll take the fees
    function _set(
        uint256 destination_, CarbonCreditBundleToken bundle_,
        uint256 amountNative_, uint256 amountInTermsOfBundle_, uint256 noFeeOnSuccessThreshold_
    ) internal {
        _nativeFees[destination_] = amountNative_;
        uint256 index = _getForIndex(destination_, bundle_);
        if (index < _postageFees[destination_].length) {
            _postageFees[destination_][index] = FeeStructure(bundle_, amountInTermsOfBundle_, noFeeOnSuccessThreshold_);
        } else {
            _postageFees[destination_].push(FeeStructure(bundle_, amountInTermsOfBundle_, noFeeOnSuccessThreshold_));
        }

        emit FeeSet(destination_, address(bundle_), amountNative_, amountInTermsOfBundle_, noFeeOnSuccessThreshold_);
    }

    /// @dev defaults to 0
    /// @return the fee in terms of the native token
    function getNative(uint256 destination_) external view returns (uint256) {
        return _nativeFees[destination_];
    }

    /// @param destination_ - the chain for which one is interested in the fees
    /// @param bundle_ - the bundle for which one is interested in the fees
    /// @param amount_ - the amount that is subject to fees
    /// @param onSuccess_ - which path is this fee collected on? For success we may want to take the fee :-)
    /// @return the fee for a chain / bundle
    function get(uint256 destination_, CarbonCreditBundleToken bundle_, uint256 amount_, bool onSuccess_) external view returns (uint256) {
        uint256 index = _getForIndex(destination_, bundle_);
        if (index < _postageFees[destination_].length) {
            FeeStructure memory fee = _postageFees[destination_][index];
            if (onSuccess_ && amount_ >= fee.noFeeOnSuccessThreshold) {
                return 0;
            }
            return _postageFees[destination_][index].amountInBundleFee;
        }

        /// free as a bird!
        return 0;
    }

    /// @notice this is never a threshold for failure
    /// @return the threshold over which no fee is taken
    function getThresholdForSuccessPath(uint256 destination_, CarbonCreditBundleToken bundle_) external view returns (uint256) {
        uint256 index = _getForIndex(destination_, bundle_);
        if (index < _postageFees[destination_].length) {
            return _postageFees[destination_][index].noFeeOnSuccessThreshold;
        }
        revert("no threshold");
    }

    /// @return the index of a postage fee or length o fee if not existing
    function _getForIndex(uint256 destination_, CarbonCreditBundleToken bundle_) internal view returns (uint256) {
        for (uint256 i=0; i < _postageFees[destination_].length; i++) {
            if (_postageFees[destination_][i].bundle == bundle_) {
                return i;
            }
        }
        return _postageFees[destination_].length;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import {CarbonCreditToken, CarbonCreditBundleToken} from '../../CarbonCreditBundleToken.sol';
import '../../interfaces/ICarbonCreditPermissionList.sol';
import '../CarbonCreditMainStation.sol';
import '../terminal/TerminalHandler.sol';
import '../interfaces/IActionInterface.sol';


/// @author FlowCarbon LLC
/// @title A main action implementation
contract MainAction is IActionInterface {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Emitted when a token is synced
    /// @param destination - The target chain of the sync
    /// @param tokenAddress - The address of the synced token
    event TokenSynced(uint256 destination, address tokenAddress);

    /// @notice Emitted when a bundle token is synced
    /// @param destination - The target chain of the sync
    /// @param bundleTokenAddress - The address of the synced bundle
    event BundleTokenSynced(uint256 destination, address bundleTokenAddress);

    /// @notice Emitted when a permission list is synced
    /// @param destination - The target chain of the sync
    /// @param permissionListAddress - The address of the synced permission list
    event PermissionListSynced(uint256 destination, address permissionListAddress);

    /// @notice Emitted when a permission is registered
    /// @param destination - The target chain of the sync
    /// @param permissionListAddress - The address of the synced permission list
    /// @param account - Which account was registered
    /// @param hasPermission - The flag of permission granted or revoked
    event PermissionRegistered(uint256 destination, address permissionListAddress, address account, bool hasPermission);

    /// @notice Emitted when a token is registered
    /// @param destination - The target chain of the sync
    /// @param tokenAddress - The token being registered
    /// @param bundleAddress - The bundle where the token is registered / deregistered for
    /// @param isAdded - True for adding, false for removal
    /// @param isPaused - True if paused, false if not
    event TokenRegistered(uint256 destination, address tokenAddress, address bundleAddress, bool isAdded, bool isPaused);

    /// @notice Emitted when a token is sent to a different chain
    /// @param destination - The target chain
    /// @param sender - Who sends the tokens on the starting chain
    /// @param recipient - Who receives the tokens on the target chain
    /// @param tokenAddress - Which token
    /// @param amount - How many
    event TokenSend(uint256 destination, address sender, address recipient, address tokenAddress, uint256 amount);

    /// @notice Emitted when a bundle token is sent to a different chain
    /// @param destination - The target chain
    /// @param sender - Who sends the bundle tokens on the starting chain
    /// @param recipient - Who receives the bundle tokens on the target chain
    /// @param bundleAddress - Which bundle
    /// @param amount - How many
    event BundleTokenSend(uint256 destination, address sender, address recipient, address bundleAddress, uint256 amount);

    CarbonCreditMainStation station;

    constructor(CarbonCreditMainStation station_) {
        station = station_;
    }

    /// @notice Syncs a token to the terminal chain, giving it the full interface on the terminal chain
    /// @dev Syncs initially, subsequent calls update the permission list or do nothing but costing you fees
    /// @param destination_ - The terminal chain
    /// @param tokenAddress_ - The address of the token to sync
    /// @return True if the token is added for the first time, else false (on update)
    function syncToken(uint256 destination_, address tokenAddress_) external payable returns (bool) {
        CarbonCreditToken token = station.getToken(tokenAddress_);
        ICarbonCreditPermissionList permissionList = token.permissionList();
        station.requirePermissionListSynced(destination_, address(permissionList));

        station.send{value: msg.value}(
            destination_,
            abi.encodeWithSelector(
                TerminalHandler.handleSyncToken.selector,
                tokenAddress_,
                token.name(),
                token.symbol(),
                CarbonCreditToken.TokenDetails(token.methodology(), token.creditType(), token.vintage()),
                permissionList
            )
        );

        emit TokenSynced(destination_, tokenAddress_);
        return station.registerReleasedToken(destination_, tokenAddress_);
    }

    /// @notice Syncs a bundle to the terminal chain, giving it the full interface on the terminal chain
    /// @dev Sync initially, subsequent calls update the vintage or do nothing but costing you fees
    /// @param destination_ - The terminal chain
    /// @param bundleAddress_ - The address of the bundle to sync
    /// @return True if created, false if already existed (and therefore updated)
    function syncBundle(uint256 destination_, address bundleAddress_) external payable returns (bool) {
        CarbonCreditBundleToken bundle = station.getBundle(bundleAddress_);
        station.send{value: msg.value}(
            destination_,
            abi.encodeWithSelector(
              TerminalHandler.handleSyncBundle.selector,
              bundleAddress_,
              bundle.name(),
              bundle.symbol(),
              bundle.vintage(),
              bundle.feeDivisor()
            )
        );
        emit BundleTokenSynced(destination_, bundleAddress_);
        return station.registerReleaseBundle(destination_, bundleAddress_);
    }

    /// @notice Sync a permission list over to the destination chain
    /// @param destination_ - The terminal chain
    /// @param permissionListAddress_ - The permissionList to sync
    /// @return A flag if this action had an effect
    function syncPermissionList(uint256 destination_, address permissionListAddress_) external payable returns (bool) {
        station.requirePermissionListNotSynced(destination_, permissionListAddress_);

        ICarbonCreditPermissionList permissionList = station.getPermissionList(permissionListAddress_);
        station.send{value: msg.value}(
            destination_,
            abi.encodeWithSelector(
                TerminalHandler.handleSyncPermissionList.selector,
                permissionListAddress_,
                permissionList.name()
            )
        );

        emit PermissionListSynced(destination_, permissionListAddress_);
        return station.registerReleasePermissionList(destination_, permissionListAddress_);
    }

    /// @notice Registers a permission given to the destination chain
    /// @param destination_ - The terminal chain id
    /// @param permissionListAddress_ - Address of the permission list to register an account for
    /// @param account_ - The account to sync
    /// @return Flag if permission is added or not
    function registerPermission(
        uint256 destination_, address permissionListAddress_, address account_
    ) external payable returns (bool) {
        station.requirePermissionListSynced(destination_, permissionListAddress_);
        ICarbonCreditPermissionList permissionList = station.getPermissionList(permissionListAddress_);
        bool hasPermission = permissionList.hasMultiChainPermission(account_);
        station.send{value: msg.value}(
            destination_,
            abi.encodeWithSelector(
                TerminalHandler.handleRegisterPermission.selector,
                permissionListAddress_,
                account_,
                hasPermission
            )
        );

        emit PermissionRegistered(destination_, permissionListAddress_, account_, hasPermission);
        return hasPermission;
    }

    /// @notice Registers a token for a bundle
    /// @param destination_ - The target chain
    /// @param bundleAddress_ - The bundle where the token is registered for
    /// @param tokenAddress_ - The respective token
    /// @return Flag if token is added or removed
    function registerTokenForBundle(
        uint256 destination_, address bundleAddress_, address tokenAddress_
    ) external payable returns (bool) {
        station.requireTokenSynced(destination_, tokenAddress_);
        station.requireBundleSynced(destination_, bundleAddress_);
        CarbonCreditBundleToken bundle = station.getBundle(bundleAddress_);
        CarbonCreditToken token = CarbonCreditToken(tokenAddress_);

        bool isAdded = bundle.hasToken(token);
        bool isPaused = bundle.pausedForDeposits(CarbonCreditToken(token));

        station.send{value: msg.value}(
            destination_,
            abi.encodeWithSelector(
              TerminalHandler.handleRegisterTokenForBundle.selector,
              bundleAddress_,
              tokenAddress_,
              isAdded,
              isPaused
            )
        );
        emit TokenRegistered(destination_, tokenAddress_, bundleAddress_, isAdded, isPaused);
        return isAdded;
    }

    /// @notice Send tokens to a someone on some chain!
    /// @param destination_ - The target chain
    /// @param tokenAddress_ - The token to send
    /// @param recipient_ - The recipient on the remote chain
    /// @param amount_ - The amount of tokens to be send
    /// @dev Requires approval
    function sendTokens(uint256 destination_, address tokenAddress_, address recipient_, uint256 amount_) public payable {
        station.requireTokenSynced(destination_, tokenAddress_);

        CarbonCreditToken token = station.getToken(tokenAddress_);
        if (address(token.permissionList()) != address(0)) {
            require(token.permissionList().hasPermission(msg.sender), "the sender is not permitted to send this token");
            require(token.permissionList().hasPermission(recipient_), "the recipient is not permitted to receive this token");
        }

        IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(station), amount_);
        station.send{value: msg.value}(
            destination_,
            abi.encodeWithSelector(
                IHandlerInterface.handleReceiveTokens.selector,
                tokenAddress_,
                recipient_,
                amount_
            )
        );

        emit TokenSend(destination_, msg.sender, recipient_, tokenAddress_, amount_);
    }

    /// @notice Send bundle tokens to a someone on some chain!
    /// @param destination_ - The target chain
    /// @param bundleAddress_ - The token to send
    /// @param recipient_ - The recipient on the remote chain
    /// @param amount_ - The amount of tokens to be send
    /// @dev Requires approval
    function sendBundleTokens(uint256 destination_, address bundleAddress_, address recipient_, uint256 amount_) public payable {
        station.requireBundleSynced(destination_, bundleAddress_);

        IERC20Upgradeable(station.getBundle(bundleAddress_)).safeTransferFrom(msg.sender, address(station), amount_);
        station.send{value: msg.value}(
            destination_,
            abi.encodeWithSelector(
              TerminalHandler.handleReceiveBundleTokens.selector,
              bundleAddress_,
              recipient_,
              amount_
            )
        );

        emit BundleTokenSend(destination_, msg.sender, recipient_, bundleAddress_, amount_);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts/access/Ownable.sol';
import {CarbonCreditToken, CarbonCreditBundleToken} from "../../CarbonCreditBundleToken.sol";
import "../CarbonCreditMainStation.sol";
import "../terminal/TerminalHandler.sol";
import "../interfaces/IHandlerInterface.sol";

/// @author FlowCarbon LLC
/// @title A main handler implementation
contract MainHandler is Ownable, IHandlerInterface {

    CarbonCreditMainStation station;

    constructor(CarbonCreditMainStation station_) {
        station = station_;
        transferOwnership(address(station_));
    }

    /// @dev see IHandlerInterface
    function handleReceiveTokens(
        address originalTokenAddress_, address recipient_, uint256 amount_
    ) external onlyOwner {
        station.transfer(originalTokenAddress_, recipient_, amount_);
    }

    /// @dev see IHandlerInterface
    function handleReceiveBundleTokens(
        address originalBundleAddress_, address recipient_, uint256 amount_
    ) external onlyOwner {
        station.transfer(originalBundleAddress_, recipient_, amount_);
    }

    /// @dev finalizes the offsets from the treasury
    function handleOffsetFromTreasury(address tokenAddress_, uint256 amount_) external onlyOwner {
        station.offset(tokenAddress_, amount_);
    }

    /// @dev finalizes the bundle from the treasury
    function handleBundle(
        uint256 destination_, address bundleAddress_, address tokenAddress_, address recipient_, uint256 amount_
    ) external onlyOwner {
        CarbonCreditBundleToken bundle = station.getBundle(bundleAddress_);
        CarbonCreditToken token = station.getToken(tokenAddress_);

        try station.bundle(bundle, token, amount_) {
            // pay the fees in terms of bundle
            uint256 amountAfterFees = station.deductPostageFee(destination_, bundle, IERC20Upgradeable(bundle), amount_, true);
            if (amountAfterFees > 0) {
                station.sendCallback(
                    destination_,
                    abi.encodeWithSelector(
                        TerminalHandler.handleReceiveBundleTokens.selector,
                        bundleAddress_,
                        recipient_,
                        amountAfterFees
                    )
                );
            }
        } catch {
            // this is an edgy case when we removed the token on the main chain but it's not synced yet and
            // someone tries to bundle

            // pay the fees in terms of gco2 tokens
            uint256 amountAfterFees = station.deductPostageFee(destination_, bundle, IERC20Upgradeable(token), amount_, false);
            if (amountAfterFees > 0) {
                station.sendCallback(
                    destination_,
                    abi.encodeWithSelector(
                        TerminalHandler.handleReceiveTokens.selector,
                        tokenAddress_,
                        recipient_,
                        amountAfterFees
                    )
                );
            }
        }
    }

    /// @dev finalizes the unbundling from the treasury, sends back GCO2 on success or bundle token on failure
    function handleUnbundle(
        uint256 destination_, address bundleAddress_, address tokenAddress_, address recipient_, uint256 amount_
    ) external onlyOwner {
        CarbonCreditBundleToken bundle = station.getBundle(bundleAddress_);
        CarbonCreditToken token = station.getToken(tokenAddress_);

        uint256 fee = station.postageFee().get(destination_, bundle, amount_, true);
        if (fee >= amount_) {
            station.deductPostageFee(destination_, bundle, bundle, amount_, true);
            /* The provided amount is too low - do nothing. */
            return;
        }

        try station.unbundle(bundle, token, amount_ - fee) returns (uint256 amountUnbundled){
            station.deductPostageFee(destination_, bundle, IERC20Upgradeable(bundle), amount_, true);
            station.sendCallback(
                destination_,
                abi.encodeWithSelector(
                    TerminalHandler.handleReceiveTokens.selector,
                    tokenAddress_,
                    recipient_,
                    amountUnbundled
                )
            );
        } catch {
            uint256 amountAfterFeesFailure = station.deductPostageFee(destination_, bundle, IERC20Upgradeable(bundle), amount_, false);
            station.sendCallback(
                destination_,
                abi.encodeWithSelector(
                    TerminalHandler.handleReceiveBundleTokens.selector,
                    bundleAddress_,
                    recipient_,
                    amountAfterFeesFailure
                )
            );
        }
    }

    /// @dev swaps the bundle in the treasury, sends back GCO2 on success or bundle token on failure
    function handleSwapBundle(
        uint256 destination_, address sourceBundleAddress_, address targetBundleAddress_, address tokenAddress_, address recipient_, uint256 amount_
    ) external onlyOwner {
        CarbonCreditBundleToken sourceBundle = station.getBundle(sourceBundleAddress_);
        CarbonCreditBundleToken targetBundle = station.getBundle(targetBundleAddress_);
        CarbonCreditToken token = station.getToken(tokenAddress_);

        uint256 fee = station.postageFee().get(destination_, sourceBundle, amount_, true);
        if (fee >= amount_) {
            station.deductPostageFee(destination_, sourceBundle, IERC20Upgradeable(sourceBundle), amount_, true);
            /* The provided amount is too low - d   o nothing. */
            return;
        }

        try station.swapBundle(sourceBundle, targetBundle, token, amount_ - fee) returns (uint256 amountSwapped) {
            station.deductPostageFee(destination_, sourceBundle, IERC20Upgradeable(sourceBundle), amount_, true);
            station.sendCallback(
                destination_,
                abi.encodeWithSelector(
                    TerminalHandler.handleReceiveBundleTokens.selector,
                    targetBundleAddress_,
                    recipient_,
                    amountSwapped
                )
            );
        } catch {
            uint256 amountAfterFeesFailure = station.deductPostageFee(destination_, sourceBundle, IERC20Upgradeable(sourceBundle), amount_, false);
            station.sendCallback(
                destination_,
                abi.encodeWithSelector(
                    TerminalHandler.handleReceiveBundleTokens.selector,
                    sourceBundleAddress_,
                    recipient_,
                    amountAfterFeesFailure
                )
            );
        }
    }

    /// @dev offset specific on behalf of from the treasury, sends back GCO2 on success or bundle token on failure
    function handleOffsetSpecificOnBehalfOf(
        uint256 destination_, address bundleTokenAddress_, address tokenAddress_, address offsetter_, address beneficiary_, uint256 amount_
    ) external onlyOwner {
        CarbonCreditBundleToken bundle = station.getBundle(bundleTokenAddress_);
        CarbonCreditToken token = station.getToken(tokenAddress_);
        uint256 fee = station.postageFee().get(destination_, bundle, amount_, true);
        if (fee >= amount_) {
            station.deductPostageFee(destination_, bundle, IERC20Upgradeable(bundle), amount_, true);
            /* The provided amount is too low - do nothing. */
            return;
        }

        try station.offsetSpecific(bundle, token, amount_ - fee) returns (uint256 amountOffsetted) {
            station.deductPostageFee(destination_, bundle, IERC20Upgradeable(bundle), amount_, true);
            station.sendCallback(
                destination_,
                abi.encodeWithSelector(
                    TerminalHandler.handleOffsetSpecificOnBehalfOfCallback.selector,
                    tokenAddress_,
                    beneficiary_,
                    amountOffsetted
                )
            );
        } catch {
            uint256 amountAfterFeesFailure = station.deductPostageFee(destination_, bundle, IERC20Upgradeable(bundle), amount_, false);
            station.sendCallback(
                destination_,
                abi.encodeWithSelector(
                    TerminalHandler.handleReceiveBundleTokens.selector,
                    bundleTokenAddress_,
                    offsetter_,
                    amountAfterFeesFailure
                )
            );
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './CarbonCreditRakeback.sol';
import './abstracts/AbstractFactory.sol';

/// @author FlowCarbon LLC
/// @title A Carbon Credit Token Rakeback Factory
contract CarbonCreditRakebackFactory is AbstractFactory {

    using ClonesUpgradeable for address;

    /// @param implementationContract_ - The contract to be used as implementation for new rakebacks
    /// @param owner_ - The address to which ownership of this contract will be transferred
    constructor (CarbonCreditRakeback implementationContract_, address owner_) {
        swapImplementationContract(address(implementationContract_));
        transferOwnership(owner_);
    }

    /// @notice Deploy a new rakeback
    /// @param bundle_ - The bundle for this rakeback contract
    /// @param owner_ - The address to which ownership of the deployed contract will be transferred
    /// @return The address of the newly created rakeback
    function createCarbonCreditRakeback(CarbonCreditBundleToken bundle_, address owner_) onlyOwner external returns (address) {
        CarbonCreditRakeback carbonCreditRakeback = CarbonCreditRakeback(implementationContract.clone());
        carbonCreditRakeback.initialize(bundle_, owner_);
        finalizeCreation(address(carbonCreditRakeback));
        return address(carbonCreditRakeback);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import './CarbonCreditToken.sol';
import './CarbonCreditBundleToken.sol';


/// @author FlowCarbon LLC
/// @title A Carbon Credit Token Rakeback Implementation
/// @dev In order to work with permissioned tokens, this contract needs to be added to the respective permission list
contract CarbonCreditRakeback is Initializable, OwnableUpgradeable {

    using SafeERC20Upgradeable for CarbonCreditToken;

    using SafeERC20Upgradeable for CarbonCreditBundleToken;

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /// @notice Emitted after bundle swap
    /// @param account - The account that triggered the swap
    /// @param sourceBundleAddress - The source bundle address
    /// @param targetBundleAddress - The target bundle address
    /// @param tokenAddress - The address of the token that was swapped
    /// @param swapAmount - The amount swapped in terms of source bundle
    /// @param receivedAmount - The amount received after fees in terms of target bundle
    event BundleSwap(
        address account,
        address sourceBundleAddress,
        address targetBundleAddress,
        address tokenAddress,
        uint256 swapAmount,
        uint256 receivedAmount
    );

    /// @notice Emitted after offset specific
    /// @param account - The account that triggered the offset
    /// @param bundleAddress - The bundle address
    /// @param tokenAddress - The address of the token that is to be offsetted
    /// @param initialAmount - The amount to offset in terms of source bundle
    /// @param offsettedAmount - The amount offsetted after fees in terms of the token
    event OffsetSpecific(
        address account,
        address bundleAddress,
        address tokenAddress,
        uint256 initialAmount,
        uint256 offsettedAmount
    );

    /// @notice Emitted when someone unbundles tokens from the bundle using the rakeback contract
    /// @param account - The token recipient
    /// @param bundleAddress - The bundle from which the token was unbundled
    /// @param tokenAddress - The address of the vanilla underlying
    /// @param amount - The amount sent to unbundle
    /// @param receivedAmount - The amount after fees (these may change in the rakeback and are therefore explicit)
    event RakebackUnbundle(
        address account,
        address bundleAddress,
        address tokenAddress,
        uint256 amount,
        uint256 receivedAmount
    );

    /// @notice Emitted whenever a fee divisor is updated for a token
    /// @param token - The token with a new fee divisor
    /// @param feeDivisor - The new fee divisor; the actual fee is the reciprocal
    event FeeDivisorUpdated(CarbonCreditToken token, uint256 feeDivisor);

    /// @notice The bundle token associated with this rakeback
    CarbonCreditBundleToken public bundle;

    /// @dev Internal mapping of carbon credit tokens to fee divisor overrides.
    mapping(CarbonCreditToken => uint256) private _feeDivisors;

    /// @dev Internal set of carbon credit tokens that have overridden fee divisors.
    EnumerableSetUpgradeable.AddressSet private _tokensWithFeeDivisorOverrides;

    /// @param bundle_ - The bundle that this rakeback contract controls
    /// @param owner_ - The owner of this rakeback contract
    function initialize(CarbonCreditBundleToken bundle_, address owner_) external initializer {
        require(address(bundle_) != address(0), 'bundle is required');
        bundle = bundle_;
        __Ownable_init();
        transferOwnership(owner_);
    }

    /// @notice Batch setting of the feeDivisor
    /// @param tokens_ - Array of CarbonCreditTokens
    /// @param feeDivisor_ - Array of feeDivisors
    function batchSetFeeDivisor(CarbonCreditToken[] memory tokens_,  uint256[] memory feeDivisor_) onlyOwner external {
        require(tokens_.length == feeDivisor_.length, 'tokens and feeDivisors must have the same length');
        for (uint256 i=0; i < tokens_.length; i++) {
            setFeeDivisor(tokens_[i], feeDivisor_[i]);
        }
    }

    /// @notice Batch remove of feeDivisors
    /// @param tokens_ - Array of CarbonCreditTokens
    function batchRemoveFeeDivisor(CarbonCreditToken[] memory tokens_) onlyOwner external {
        for (uint256 i=0; i < tokens_.length; i++) {
            removeFeeDivisor(tokens_[i]);
        }
    }

    // @notice Set a fee divisor for a token
    // @dev A fee divisor is the reciprocal of the actual fee, e.g. 100 is 1% because 1/100 = 0.01
    // @param token_ - The token for which we set the fee divisor
    // @param feeDivisor_ - The fee divisor
    function setFeeDivisor(CarbonCreditToken token_, uint256 feeDivisor_) onlyOwner public {
        require(bundle.feeDivisor() < feeDivisor_, 'feeDivisor must exceed base fee');
        require(_feeDivisors[token_] != feeDivisor_, 'feeDivisor must change');
        _tokensWithFeeDivisorOverrides.add(address(token_));
        _feeDivisors[token_] = feeDivisor_;
        emit FeeDivisorUpdated(token_, feeDivisor_);
    }

    // @notice Removes a fee divisor for a token
    // @param token_ - The token for which we remove the fee divisor
    function removeFeeDivisor(CarbonCreditToken token_) onlyOwner public {
        require(hasTokenWithFeeDivisor(token_), 'no feeDivisor set for token');
        uint bundleFeeDivisor = bundle.feeDivisor();
        _tokensWithFeeDivisorOverrides.remove(address(token_));
        _feeDivisors[token_] = bundleFeeDivisor;
        emit FeeDivisorUpdated(token_, bundleFeeDivisor);
    }

    /// @notice Checks if a token has a fee divisor specified in this contract
    /// @param token_ - A carbon credit token
    /// @return Whether we have a token fee divisor or not
    function hasTokenWithFeeDivisor(CarbonCreditToken token_) public view returns (bool) {
        return _tokensWithFeeDivisorOverrides.contains(address(token_));
    }

    /// @notice Number of tokens that have a fee override
    /// @return The number of tokens
    function tokenWithFeeDivisorCount() external view returns (uint256) {
        return _tokensWithFeeDivisorOverrides.length();
    }

    /// @notice A token with a fee divisor
    /// @param index_ - The index position taken from tokenCount()
    /// @dev The ordering may change upon adding / removing
    /// @return Address of the token at the index
    function tokenWithFeeDivisorAtIndex(uint256 index_) external view returns (address) {
        return _tokensWithFeeDivisorOverrides.at(index_);
    }

    /// @notice The fee divisor of a token
    /// @dev This uses the bundles default as a fallback if not specified, so it'll always work
    /// @return The fee divisor
    function feeDivisor(CarbonCreditToken token_) public view returns (uint256) {
        if (hasTokenWithFeeDivisor(token_)) {
            return _feeDivisors[token_];
        }
        return bundle.feeDivisor();
    }

    /// @dev Internal function to calculate the rakeback
    /// @param token_ - The token for which we calculate the rakeback
    /// @param amountBeforeFee_ - The amount before the fee was applied by the bundle
    /// @param amountAfterFee_ - The amount after the fee was applied by the bundle
    /// @return The rakeback provided by this contract
    function _calculateRakeback(CarbonCreditToken token_, uint256 amountBeforeFee_, uint256 amountAfterFee_) internal view returns (uint256) {
        uint256 originalFeeDivisor = bundle.feeDivisor();
        uint256 currentFeeDivisor = feeDivisor(token_);
        if (currentFeeDivisor > originalFeeDivisor) {
            uint256 originalFee = amountBeforeFee_ - amountAfterFee_;
            // NOTE: this is safe because currentFeeDivisor > originalFeeDivisor >= 0
            uint256 feeAmount = amountBeforeFee_ / currentFeeDivisor;
            return originalFee - feeAmount;
        }
        return 0;
    }

    /// @dev Pulls in the tokens from the sender and unbundles it to the specified token
    /// @param token_ - The token the sender wishes to unbundle to
    /// @param amount_ - The amount the sender wishes to unbundle
    /// @return The amount after fees that the user receives
    function _transferFromAndUnbundle(CarbonCreditToken token_, uint256 amount_) internal returns (uint256) {
        bundle.safeTransferFrom(_msgSender(), address(this), amount_);
        uint256 amountAfterFees = bundle.unbundle(token_, amount_);
        uint256 rakeback = _calculateRakeback(token_, amount_, amountAfterFees);
        token_.safeTransferFrom(bundle.owner(), address(this), rakeback);
        return amountAfterFees + rakeback;
    }

    /// @dev Bundles the amount of given tokens into the requested bundle and sends the bundle tokens back
    /// @param bundle_ - The target bundle to swap to
    /// @param token_ - The token the sender wishes to swap to
    /// @param amount_ - The amount the sender wishes to swap
    /// @return The amount after fees that the user receives
    function _bundleAndTransfer(
        CarbonCreditBundleToken bundle_, CarbonCreditToken token_, uint256 amount_
    ) internal returns (uint256) {
        token_.approve(address(bundle_), amount_);
        bundle_.bundle(token_, amount_);
        bundle_.safeTransfer(_msgSender(), amount_);
        return amount_;
    }

    /// @notice Unbundle the given token for the given amount
    /// @dev The sender needs to have given approval for the amount for the bundle
    /// @param token_ - The token the sender wishes to unbundle
    /// @param amount_ - The amount the sender wishes to unbundle
    /// @return The amount after fees that the user receives
    function unbundle(CarbonCreditToken token_, uint256 amount_) external returns (uint256) {
        uint receivedAmount = _transferFromAndUnbundle(token_, amount_);
        token_.safeTransfer(_msgSender(), receivedAmount);

        emit RakebackUnbundle(_msgSender(), address(bundle), address(token_), amount_, receivedAmount);
        return receivedAmount;
    }

    /// @notice Swaps a given GCO2 token between bundles
    /// @param targetBundle_ - The bundle where the GCO2 token should be bundled into
    /// @param token_ - The GCO2 token to swap
    /// @param amount_ - The amount of tokens to swap
    /// @return The amount of tokens arriving in the bundle (after fee)
    function swapBundle(CarbonCreditBundleToken targetBundle_, CarbonCreditToken token_, uint256 amount_) external returns (uint256) {
        uint receivedAmount = _bundleAndTransfer(
            targetBundle_,
            token_,
            _transferFromAndUnbundle(token_, amount_)
        );

        emit BundleSwap(
            _msgSender(), address(bundle), address(targetBundle_), address(token_), amount_, receivedAmount
        );

        return receivedAmount;
    }

    /// @notice Offsets a specific GCO2 token on behalf of the given address
    /// @param token_ - The GCO2 token to offset
    /// @param account_ - The beneficiary to the offset
    /// @param amount_ - The amount of tokens to offset
    /// @return The amount of offsetted tokens after fee
    function offsetSpecificOnBehalfOf(CarbonCreditToken token_, address account_, uint256 amount_) public returns (uint256) {
        uint256 amountToOffset = _transferFromAndUnbundle(token_, amount_);
        token_.offsetOnBehalfOf(
            account_,
            amountToOffset
        );

        emit OffsetSpecific(
            account_, address(bundle), address(token_), amount_, amountToOffset
        );
        return amountToOffset;
    }

    /// @notice Offsets a specific GCO2 token
    /// @param token_ - The GCO2 token to offset
    /// @param amount_ - The amount of tokens to offset
    /// @return The amount of offsetted tokens after fee
    function offsetSpecific(CarbonCreditToken token_, uint256 amount_) external returns (uint256) {
        return offsetSpecificOnBehalfOf(token_, msg.sender, amount_);
    }

    /// @dev Overridden to disable renouncing ownership
    function renounceOwnership() public virtual override onlyOwner {
        revert('renouncing ownership is disabled');
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';
import '../../abstracts/AbstractToken.sol';
import '../CarbonCreditTerminalStation.sol';

/// @author FlowCarbon LLC
/// @title Abstract Token for terminal chains
abstract contract AbstractWrappedToken is AbstractToken {

    CarbonCreditTerminalStation public terminalStation;

    function __AbstractWrappedToken__init(
        string memory name_,
        string memory symbol_,
        CarbonCreditTerminalStation terminalStation_
    ) internal onlyInitializing {
        __AbstractToken_init(name_, symbol_, address(terminalStation_));
        terminalStation = terminalStation_;
    }

    /// @notice mints new tokens
    /// @dev only the terminal station, it's guaranteed to be backed
    /// @param account_ - the receiving address
    /// @param amount_ - the amount to mint
    function mint(address account_, uint256 amount_) external onlyOwner {
        _mint(account_, amount_);
    }

    /// @notice burns tokens
    /// @dev only the terminal station, it's guaranteed to be backed
    /// @param account_ - the burning address
    /// @param amount_ - the amount to burn
    function burn(address account_, uint256 amount_) external onlyOwner {
        _burn(account_, amount_);
    }

    /// @notice Releases the pending balance back to the main chain
    function releasePendingOffsetsToMainChain() external payable  {
        uint256 amount = pendingBalance;
        offsetBalance += amount;
        pendingBalance = 0;
        _forwardOffsets(amount);
    }

    /// @dev the actual forwarding implementation to the terminal station
    /// @param amount_ the amount forwarded
    function _forwardOffsets(uint256 amount_) internal virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

/// @author FlowCarbon LLC
/// @title The common interface of actions across chains
interface IActionInterface {

    /// @notice Emitted on tokens send
    /// @param tokenAddress - the address of the token on source chain
    /// @param destination - the target chain
    /// @param sender - the sending address on origin chain
    /// @param recipient - the receiving address on target chain
    /// @param amount - the amount send
    event TokensSend(address tokenAddress, uint256 destination, address sender, address recipient, uint256 amount);

    /// @notice Emitted on tokens send
    /// @param bundleAddress - the address of the bundle on source chain
    /// @param destination - the target chain
    /// @param sender - the sending address on origin chain
    /// @param recipient - the receiving address on target chain
    /// @param amount - the amount send
    event BundleTokensSend(address bundleAddress, uint256 destination, address sender, address recipient, uint256 amount);

   /// @notice send tokens to a someone on some chain!
   /// @param destination_ - the target chain
   /// @param tokenAddress_ - the token to send
   /// @param recipient_ - the recipient on the remote chain
   /// @param amount_ - the amount of tokens to be send
   function sendTokens(uint256 destination_, address tokenAddress_, address recipient_, uint256 amount_) external payable;

    /// @notice send bundle tokens to a someone on some chain!
    /// @param destination_ - the target chain
    /// @param bundleAddress_ - the token to send
    /// @param recipient_ - the recipient on the remote chain
    /// @param amount_ - the amount of tokens to be send
    function sendBundleTokens(uint256 destination_, address bundleAddress_, address recipient_, uint256 amount_) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

/// @author FlowCarbon LLC
/// @title The common interface of handlers across chains
interface IHandlerInterface {

    /// @notice receives a token
    /// @dev edge case: this fails if the token is not synced, sync and retry in that case
    /// @param originalTokenAddress_ - the address of the token on the main chain
    /// @param recipient_ - the receiver of the token
    /// @param amount_ - the amount of the token
    function handleReceiveTokens(
        address originalTokenAddress_, address recipient_, uint256 amount_
    ) external;

    /// @notice receives a token
    /// @dev edge case: this fails if the token is not synced, sync and retry in that case
    /// @param originalBundleAddress_ - the address of the token on the main chain
    /// @param recipient_ - the receiver of the token
    /// @param amount_ - the amount of the token
    function handleReceiveBundleTokens(
        address originalBundleAddress_, address recipient_, uint256 amount_
    ) external;

}