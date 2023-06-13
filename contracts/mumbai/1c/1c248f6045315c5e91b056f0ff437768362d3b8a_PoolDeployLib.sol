// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ContractLib} from "Util/Contract.sol";
import {Itos2sAMMDiamond} from "../../src/2sAMMDiamond.sol";

library PoolDeployLib {
    /// This is the hash of the creationCode for the 2sAMMDiamond.
    /// This is the same as calling keccak256(type(Itos2sAMMDiamond).creationCode)
    /// @dev WARNING: Computing that hash through a library call gives the wrong answer.
    /// You can either compute it directly in your deployment code, or use this hash.
    /// Changing the code changes the metadata which changes this hash. Update accordingly.
    /// **OUT OF DATE**
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xa81263e12ee7e25c4175e25e127f6dc15f32c26eec67e05510e4fe99eb204b15;

    /// Get the appropriate salt for the desired pool configuration
    function getSalt(address _tokenX, address _tokenY, uint24 tickSpacing) public pure returns (bytes32 salt) {
        (address tokenX, address tokenY) = _tokenX < _tokenY ? (_tokenX, _tokenY) : (_tokenY, _tokenX);
        salt = keccak256(abi.encode(tokenX, tokenY, tickSpacing));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

library ContractLib {
    error NotAContract();

    // @dev It's important to verify an address is a contract if you're going
    // to call methods on it because many transfer functions check the returned
    // data length to determine success and an address with no bytecode will
    // return no data thus appearing like a success.
   function isContract(address addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(addr)
        }
        return (size > 0);
    }

    function assertContract(address addr) internal view {
        if (!isContract(addr)) {
            revert NotAContract();
        }
    }

    /// An address created with CREATE2 is deterministic.
    /// Given the input arguments, we know exactly what the resulting
    /// deployed contract's address will be.
    /// @param deployer The address that created the contract.
    /// @param salt The salt used when creating the contract.
    /// @param initCodeHash The keccak hash of the initCode of the deployed contract.
    function getCreate2Address(
        address deployer,
        bytes32 salt,
        bytes32 initCodeHash
    ) public pure returns (address deployedAddr) {
        deployedAddr = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            deployer,
                            salt,
                            initCodeHash
                        )
                    )
                )
            )
        );
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {I2sAMMDeployer} from "interfaces/I2sAMMDeployer.sol";
import {IDiamond} from "Diamond/interfaces/IDiamond.sol";
import {LibDiamond} from "Diamond/libraries/LibDiamond.sol";

// Facet Cuts
import {IDiamondCut} from "Diamond/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "Diamond/interfaces/IDiamondLoupe.sol";
import {AdminFacet, AdminLib} from "Util/Admin.sol";
import {SwapFacet} from "Swap/SwapFacet.sol";
import {LiqFacet} from "Liq/LiqFacet.sol";

// Supported Interfaces
import {IERC165} from "../lib/Commons/lib/ERC/interfaces/IERC165.sol";
import {IERC173} from "../lib/Commons/lib/ERC/interfaces/IERC173.sol";

// Storage initialization
import {FeeStorageLib} from "Fee/Storage.sol";
import {FeeCalculator, FeeCalculatorImpl, FeeCollector} from "Fee/Fees.sol";
import {SwapStorageLib, ImmutInfoStorage, SwapStorage} from "Swap/Storage.sol";
import {LiqStorageLib} from "Liq/Storage.sol";
import {TickStorageLib} from "Ticks/Storage.sol";

// Helpers
import {TBPImpl} from "Liq/Borrow.sol";
import {SqrtPriceLib, Price} from "Ticks/Tick.sol";
import {Token, TokenImpl} from "Util/Token.sol";
import {LiqDeployMath} from "Liq/Math.sol";
import {LiqTree, LiqTreeImpl} from "Liq/Tree.sol";
import {SafeCast} from "Math/Cast.sol";

// When no function exists for function called
error FunctionNotFound(bytes4 _functionSelector);

contract Itos2sAMMDiamond is IDiamond {
    using TokenImpl for Token;
    using LiqTreeImpl for LiqTree;

    error PoolSeedInsufficient(address tokenX, address tokenY, uint256 amountX, uint256 amountY, uint128 mLiq);

    /// The smallest amount of liquidity a pool can be started with.
    /// Recall that tokens often have 1e18 decimal points of precision. On that scale
    /// a token must be worth trillions of dollars for this minimum to be non-negligeable.
    uint128 public constant SEED_MINIMUM_LIQ = 100;

    /// A 2sAMM pool is deployed through a Itos2sAMMDeployer who holds the
    /// arguments for constructing this pool. There are no arguments in this constructor
    /// so that the contract address is deterministic with CREATE2.
    /// Due to this determinism, a pool can only be constructed if the address has already
    /// been seeded with tokens for its initial liquidity so users are expected to
    /// pre-compute this contracts address and send tokens there. They should send a negligeable
    /// amount just for seeding because that amount will not be returned.
    constructor() {
        (
            I2sAMMDeployer.DeployParams memory params,
            I2sAMMDeployer.DefaultConfiguration memory config,
            I2sAMMDeployer.FacetAddresses memory fAddrs
        ) = I2sAMMDeployer(msg.sender).parameters();

        // Before we can cut, we must have an admin.
        AdminLib.initOwner(msg.sender);

        {
            /* First handle the cuts */

            FacetCut[] memory cuts = new FacetCut[](5);

            bytes4[] memory cutFunctionSelectors = new bytes4[](1);
            cutFunctionSelectors[0] = IDiamondCut.diamondCut.selector;

            cuts[0] = FacetCut({
                facetAddress: address(fAddrs.dCut),
                action: FacetCutAction.Add,
                functionSelectors: cutFunctionSelectors
            });

            bytes4[] memory loupeFunctionSelectors = new bytes4[](4);
            loupeFunctionSelectors[0] = IDiamondLoupe.facets.selector;
            loupeFunctionSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
            loupeFunctionSelectors[2] = IDiamondLoupe.facetAddresses.selector;
            loupeFunctionSelectors[3] = IDiamondLoupe.facetAddress.selector;

            cuts[1] = FacetCut({
                facetAddress: address(fAddrs.dLoupe),
                action: FacetCutAction.Add,
                functionSelectors: loupeFunctionSelectors
            });

            bytes4[] memory adminFunctionSelectors = new bytes4[](5);
            adminFunctionSelectors[0] = AdminFacet.transferOwnership.selector;
            adminFunctionSelectors[1] = AdminFacet.owner.selector;
            adminFunctionSelectors[2] = AdminFacet.adminLevel.selector;
            adminFunctionSelectors[3] = AdminFacet.addAdmin.selector;
            adminFunctionSelectors[4] = AdminFacet.removeAdmin.selector;

            cuts[2] = FacetCut({
                facetAddress: address(fAddrs.admin),
                action: FacetCutAction.Add,
                functionSelectors: adminFunctionSelectors
            });

            bytes4[] memory swapFunctionSelectors = new bytes4[](1);
            swapFunctionSelectors[0] = SwapFacet.swap.selector;

            cuts[3] = FacetCut({
                facetAddress: address(fAddrs.swap),
                action: FacetCutAction.Add,
                functionSelectors: swapFunctionSelectors
            });

            bytes4[] memory liqFunctionSelectors = new bytes4[](7);
            liqFunctionSelectors[0] = LiqFacet.openWideMaker.selector;
            liqFunctionSelectors[1] = LiqFacet.openMaker.selector;
            liqFunctionSelectors[2] = LiqFacet.openTakerCall.selector;
            liqFunctionSelectors[3] = LiqFacet.openTakerPut.selector;
            liqFunctionSelectors[4] = LiqFacet.close.selector;
            liqFunctionSelectors[5] = LiqFacet.value.selector;
            liqFunctionSelectors[6] = LiqFacet.split.selector;

            cuts[4] = FacetCut({
                facetAddress: address(fAddrs.liq),
                action: FacetCutAction.Add,
                functionSelectors: liqFunctionSelectors
            });

            // The magic
            bytes memory nullData;
            LibDiamond.diamondCut(cuts, address(0), nullData);
        }

        {
            // Setup supported interfaces for ERC165
            LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
            ds.supportedInterfaces[type(IERC165).interfaceId] = true;
            ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
            ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
            ds.supportedInterfaces[type(IERC173).interfaceId] = true;
        }

        {
            /* Handle storage initialization */

            // Do this in the constructor so it's impossible to reinitialize.
            // The init code won't even exist on contract.

            // Set Owner
            AdminLib.reassignOwner(params.owner);

            // Setup Fees
            FeeCollector storage feeCollector = FeeStorageLib.load();
            FeeCalculator memory fCalc;
            FeeCalculatorImpl.init(fCalc, config.invAlphaX224, config.betaX96, config.maxUtilX128);
            feeCollector.feeCalc = fCalc;

            // Pool information setup
            ImmutInfoStorage storage infoStorage = SwapStorageLib.infoStorage();
            Token tokenX = TokenImpl.make(params.tokenX);
            Token tokenY = TokenImpl.make(params.tokenY);
            infoStorage.tokenX = tokenX;
            infoStorage.tokenY = tokenY;
            infoStorage.PM = config.PM;

            // Initializating Swap Storage
            // IMPORTANT: We expect the deployer to have sent tokens to this address before deployment
            // to seed the pool with wide liquidity. Since the pool's address is deterministic they
            // are able to send tokens pre-emptively.
            // Someone intercept and deploy the pool ahead of the seeder but there is no monetary gain
            // from doing so and simply saves the seeder gas costs.
            uint256 receivedX = tokenX.balance();
            uint256 receivedY = tokenY.balance();
            (Price sqrtP, uint128 mLiq) = LiqDeployMath.calcWideSqrtPriceAndMLiq(receivedX, receivedY);

            if (mLiq < SEED_MINIMUM_LIQ) {
                revert PoolSeedInsufficient(params.tokenX, params.tokenY, receivedX, receivedY, mLiq);
            }

            // Initialize our swaps with the tokens given.
            // Won't support much swapping at this point.
            SwapStorage storage swapStore = SwapStorageLib.load();
            swapStore.mLiq = mLiq;
            swapStore.sqrtP = sqrtP;

            // Initialize the TickTable
            TickStorageLib.tickTable().spacing = SafeCast.toInt24(params.tickSpacing);

            // Initialize Liq Storage
            // We don't create any positions, but the tree should be aware of the wide liquidity added.
            LiqStorageLib.tree().addWideMLiq(mLiq);

            // The owner should set a rate pusher for the TBPs if they don't want to use the default interest rates.
            LiqStorageLib.xTBP().SPRX64 = TBPImpl.DEFAULT_SPRX64;
            LiqStorageLib.yTBP().SPRX64 = TBPImpl.DEFAULT_SPRX64;
        }
    }

    /* solhint-disable */
    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.facetAddressAndSelectorPosition[msg.sig].facetAddress;
        if (facet == address(0)) {
            revert FunctionNotFound(msg.sig);
        }
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}
/* solhint-enable */

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { DiamondCutFacet } from "Diamond/facets/DiamondCutFacet.sol";
import { DiamondLoupeFacet } from "Diamond/facets/DiamondLoupeFacet.sol";
import { AdminFacet } from "Util/Admin.sol";
import { SwapFacet } from "Swap/SwapFacet.sol";
import { LiqFacet } from "Liq/LiqFacet.sol";

/// An interface for deploying 2sAMMs.
/// @dev 2sAMMs are deployed without constructor arguments to avoid altering
/// the initCode in the CREATE2 command used for deploying.
/// The 2sAMMDiamond knows to call back into this deployer to get the its
/// initialization arguments.
interface I2sAMMDeployer {
    /// The pool parameters to be set on the deployed pool.
    /// @dev Stored temporarily.
    struct DeployParams {
        address owner;
        address factory;
        address tokenX;
        address tokenY;
        uint24 tickSpacing;
    }

    /// The facet configurations used by default for pools deployed by this contract.
    struct DefaultConfiguration {
        address PM;
        uint256 invAlphaX224;
        int128 betaX96;
        uint128 maxUtilX128;
    }

    struct FacetAddresses {
        DiamondCutFacet dCut;
        DiamondLoupeFacet dLoupe;
        AdminFacet admin;
        SwapFacet swap;
        LiqFacet liq;
    }

    /// Get the default parameters for pools deployed by this deployer.
    /// @dev Called by the constructor of the deployed pool.
    /// @return params The informational params of the pool.
    /// @return config The initial configuration of the pool.
    function parameters() external view returns (
        DeployParams memory params,
        DefaultConfiguration memory config,
        FacetAddresses memory fAddrs
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamond {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamond } from "../interfaces/IDiamond.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error NoSelectorsGivenToAdd();
error NoSelectorsProvidedForFacetForCut(address _facetAddress);
error CannotAddSelectorsToZeroAddress(bytes4[] _selectors);
error NoBytecodeAtAddress(address _contractAddress, string _message);
error IncorrectFacetCutAction(uint8 _action);
error CannotAddFunctionToDiamondThatAlreadyExists(bytes4 _selector);
error CannotReplaceFunctionsFromFacetWithZeroAddress(bytes4[] _selectors);
error CannotReplaceImmutableFunction(bytes4 _selector);
error CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(bytes4 _selector);
error CannotReplaceFunctionThatDoesNotExists(bytes4 _selector);
error RemoveFacetAddressMustBeZeroAddress(address _facetAddress);
error CannotRemoveFunctionThatDoesNotExist(bytes4 _selector);
error CannotRemoveImmutableFunction(bytes4 _selector);
error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        bytes4[] selectors;
        mapping(bytes4 => bool) supportedInterfaces;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            bytes4[] memory functionSelectors = _diamondCut[facetIndex].functionSelectors;
            address facetAddress = _diamondCut[facetIndex].facetAddress;
            if(functionSelectors.length == 0) {
                revert NoSelectorsProvidedForFacetForCut(facetAddress);
            }
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamond.FacetCutAction.Add) {
                addFunctions(facetAddress, functionSelectors);
            } else if (action == IDiamond.FacetCutAction.Replace) {
                replaceFunctions(facetAddress, functionSelectors);
            } else if (action == IDiamond.FacetCutAction.Remove) {
                removeFunctions(facetAddress, functionSelectors);
            } else {
                revert IncorrectFacetCutAction(uint8(action));
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if(_facetAddress == address(0)) {
            revert CannotAddSelectorsToZeroAddress(_functionSelectors);
        }
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Add facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            if(oldFacetAddress != address(0)) {
                revert CannotAddFunctionToDiamondThatAlreadyExists(selector);
            }
            ds.facetAddressAndSelectorPosition[selector] = FacetAddressAndSelectorPosition(_facetAddress, selectorCount);
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        DiamondStorage storage ds = diamondStorage();
        if(_facetAddress == address(0)) {
            revert CannotReplaceFunctionsFromFacetWithZeroAddress(_functionSelectors);
        }
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Replace facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            // can't replace immutable functions -- functions defined directly in the diamond in this case
            if(oldFacetAddress == address(this)) {
                revert CannotReplaceImmutableFunction(selector);
            }
            if(oldFacetAddress == _facetAddress) {
                revert CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(selector);
            }
            if(oldFacetAddress == address(0)) {
                revert CannotReplaceFunctionThatDoesNotExists(selector);
            }
            // replace old facet address
            ds.facetAddressAndSelectorPosition[selector].facetAddress = _facetAddress;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        if(_facetAddress != address(0)) {
            revert RemoveFacetAddressMustBeZeroAddress(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition = ds.facetAddressAndSelectorPosition[selector];
            if(oldFacetAddressAndSelectorPosition.facetAddress == address(0)) {
                revert CannotRemoveFunctionThatDoesNotExist(selector);
            }


            // can't remove immutable functions -- functions defined directly in the diamond
            if(oldFacetAddressAndSelectorPosition.facetAddress == address(this)) {
                revert CannotRemoveImmutableFunction(selector);
            }
            // replace selector with last selector
            selectorCount--;
            if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds.facetAddressAndSelectorPosition[lastSelector].selectorPosition = oldFacetAddressAndSelectorPosition.selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.facetAddressAndSelectorPosition[selector];
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        if(contractSize == 0) {
            revert NoBytecodeAtAddress(_contract, _errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { IDiamond } from "./IDiamond.sol";

interface IDiamondCut is IDiamond {    

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { IERC173 } from "../ERC/interfaces/IERC173.sol";

enum AdminLevel {
    NIL, // No clearance. Reject this user. The default 0 value.
    One, // Can only modify parts of the contract that do not risk user funds.
    Two, // Can initiate changes to the contract. Can also veto pending changes to the contract.
    Three // Highest security clearance. Can call everything except reassign owner. Can assign admins.
}

struct AdminRegistry {
    // Full security clearance. Can register admins and reassign itself.
    address owner;

    mapping(address => AdminLevel) admins;
}


/// Utility functions for checking, registering, and deregisterying administrative credentials.
library AdminLib {
    bytes32 constant ADMIN_STORAGE_POSITION = keccak256("v4.admin.diamond.storage");

    error InsufficientCredentials();
    error CannotReinitializeOwner(address existingOwner);

    function adminStore() internal pure returns (AdminRegistry storage adReg) {
        bytes32 position = ADMIN_STORAGE_POSITION;
        assembly {
            adReg.slot := position
        }
    }

    /* Getters */

    function getOwner() external view returns (address) {
        return adminStore().owner;
    }

    // @return lvl Will be cast to uint8 on return to external contracts.
    function getAdminLevel(address addr) external view returns (AdminLevel lvl) {
        return adminStore().admins[addr];
    }

    /* Validating Helpers */

    function validateOwner() internal view {
        if (msg.sender != adminStore().owner) {
            revert InsufficientCredentials();
        }
    }

    /// Revert if the msg.sender is a lower lvl than the lvl parameter.
    function validateLevel(AdminLevel lvl) internal view {
        AdminRegistry storage adReg = adminStore();
        if (adReg.owner == msg.sender)
            return;

        AdminLevel senderLvl = adReg.admins[msg.sender];
        if (senderLvl < lvl)
            revert InsufficientCredentials();
    }

    /// Convenience function so users don't have to import AdminLevel when validating.
    function validateLevel(uint8 lvl) internal view {
        validateLevel(AdminLevel(lvl));
    }

    /* Registry functions */

    /// Called when there is no owner so one can be set for the first time.
    function initOwner(address owner) public {
        AdminRegistry storage adReg = adminStore();
        if (adReg.owner != address(0))
            revert CannotReinitializeOwner(adReg.owner);
        adReg.owner = owner;
    }

    /// Remember to initialize the owner to a contract that can reassign on construction.
    function reassignOwner(address newOwner) public {
        validateOwner();
        adminStore().owner = newOwner;
    }

    function register(address newAdmin, uint8 level) public {
        validateLevel(AdminLevel.Three);
        adminStore().admins[newAdmin] = AdminLevel(level);
    }

    function deregister(address oldAdmin) public {
        validateLevel(AdminLevel.Three);
        adminStore().admins[oldAdmin] = AdminLevel.NIL;
    }
}

/// The exposed facet for external interactions with the AdminLib
contract AdminFacet is IERC173 {
    function transferOwnership(address _newOwner) external override {
        AdminLib.reassignOwner(_newOwner);
    }

    function owner() external override view returns (address owner_) {
        owner_ = AdminLib.getOwner();
    }

    /// Fetch the admin level for an address.
    function adminLevel(address addr) external view returns (uint8 lvl) {
        return uint8(AdminLib.getAdminLevel(addr));
    }

    /// Add an admin to this contract. Only level 3 clearance can call this.
    /// This will overwrite any existing clearance level.
    function addAdmin(address addr, uint8 lvl) external {
        AdminLib.register(addr, lvl);
    }

    /// Remove an admin from this contract. Effectively the same
    /// as an addAdmin call with level 0.
    function removeAdmin(address addr) external {
        AdminLib.deregister(addr);
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

// Storage
import {SwapStorageLib, SwapStorage, ImmutInfoStorage} from "Swap/Storage.sol";
import {FeeStorageLib} from "Fee/Storage.sol";
import {TickStorageLib} from "Ticks/Storage.sol";
// Types
import {TickIndex, TickIndexImpl} from "Ticks/Tick.sol";
import {Price, PriceImpl, SqrtPriceLib, MIN_PRICE, MAX_PRICE} from "Ticks/Tick.sol";
import {TickTable, TickTableImpl} from "Ticks/TickTable.sol";
import {TableIndex} from "Ticks/Table.sol";
import {FeeCalculator, FeeCollector, FeeCalculatorImpl, FeeCollectorImpl} from "Fee/Fees.sol";
import {TickData, TickDataImpl} from "Ticks/Data.sol";
import {IUniswapV3SwapCallback} from "interfaces/IUniV3.sol";
import {I2sAMMSwapper} from "interfaces/I2sAMMSwapper.sol";
import {BidAsk, BidAskImpl, BidAskLib} from "Swap/BidAsk.sol";
import {IterCache} from "Swap/Structs.sol";
// Utils
import {SwapMath} from "Swap/Math.sol";
import {MathUtils} from "Math/Utils.sol";
import {SafeCast} from "Math/Cast.sol";
import {FullMath} from "Math/FullMath.sol";
import {Mutexed} from "Util/Mutex.sol";
import {Token, TokenImpl} from "Util/Token.sol";
import {TransferLib} from "Pool/Transfer.sol";

/**
 * @notice Functionality for swapping token x into token y and vice versa given pool storage.
 *
 */
contract SwapFacet is Mutexed, I2sAMMSwapper {
    using PriceImpl for Price;
    using TickIndexImpl for TickIndex;
    using TickDataImpl for TickData;
    using TickTableImpl for TickTable;
    using FeeCollectorImpl for FeeCollector;
    using FeeCalculatorImpl for FeeCalculator;
    using BidAskImpl for BidAsk;
    using MathUtils for int256;
    using SafeCast for uint256;
    using SafeCast for int256;
    using TokenImpl for Token;

    event Swap(address sender, address receipient, uint256 x, uint256 y, bool xForY, uint160 newPrice);
    event LimitClamped(uint160 limitPrice, uint160 newLimitPrice, bool swapXforY);

    error SwapInputZero();
    error SwapInputPriceLimit(bool xForY, uint160 sqrtPriceX96, uint160 sqrtPriceLimitX96);

    function swap(
        address recipient,
        bool xForY, // sell
        int256 rawAmount,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external mutexLocked returns (uint256 x, uint256 y) {
        if (rawAmount == 0) {
            revert SwapInputZero();
        }

        // Clamp the limit price so we don't cross too far.
        Price sqrtLimitP = Price.wrap(sqrtPriceLimitX96);
        if (xForY && sqrtLimitP.lt(MIN_PRICE)) {
            emit LimitClamped(Price.unwrap(sqrtLimitP), Price.unwrap(MIN_PRICE), xForY);
            sqrtLimitP = MIN_PRICE;
        } else if (!xForY && sqrtLimitP.gt(MAX_PRICE)) {
            emit LimitClamped(Price.unwrap(sqrtLimitP), Price.unwrap(MAX_PRICE), xForY);
            sqrtLimitP = MAX_PRICE;
        }

        SwapStorage storage swapStore = SwapStorageLib.load();
        {
            // We really only allow a swap of at most 2^128 - 1.
            // We expose a uint256 rawAmount to mimic Uniswap interface.
            uint128 amount = rawAmount.abs().toUint128();
            ImmutInfoStorage storage infoStorage = SwapStorageLib.infoStorage();

            SwapStorage memory sCache = swapStore;
            FeeCollector memory fCache = FeeStorageLib.load();

            // Case to the proper swap.
            if (xForY) {
                // Sell
                {
                    bool givenX = rawAmount > 0;
                    (x, y) = swapXForY(sCache, fCache, givenX, amount, sqrtLimitP);
                }
                SwapStorageLib.store(sCache);
                FeeStorageLib.store(fCache);
                /* Committed state before context switch */
                infoStorage.tokenY.transfer(recipient, y);
                TransferLib.swapReceive(infoStorage.tokenX, true, x, y, data);
            } else {
                {
                    bool givenX = rawAmount < 0;
                    (x, y) = swapYForX(sCache, fCache, givenX, amount, sqrtLimitP);
                }
                SwapStorageLib.store(sCache);
                FeeStorageLib.store(fCache);
                /* Committed state before context switch */
                infoStorage.tokenX.transfer(recipient, x);
                TransferLib.swapReceive(infoStorage.tokenY, false, x, y, data);
            }
        }
        emit Swap(msg.sender, recipient, x, y, xForY, swapStore.sqrtP.unwrap());
    }

    /// Sell down the price by supplying X for Y.
    /// @dev Does not commit the result to storage.
    function swapXForY(
        SwapStorage memory sCache,
        FeeCollector memory fCache,
        bool givenX,
        uint128 amount,
        Price limitSP
    ) internal returns (uint256 x, uint256 y) {
        BidAsk storage bidAsk = SwapStorageLib.bidAsk();
        Price bid = bidAsk.getBid(sCache.sqrtP);
        bool useBid = sCache.sqrtP.gt(bid);

        if (limitSP.gt(bid)) {
            revert SwapInputPriceLimit(true, bid.unwrap(), limitSP.unwrap());
        }

        if (givenX) {
            (x, y) = swapXForYGivenX(sCache, fCache, amount, limitSP);
        } // amount is y
        else {
            (x, y) = swapXForYGivenY(sCache, fCache, amount, limitSP);
        }

        // Limit the amount received by the bid.
        // Only necessary if the swap price was better than the bid.
        if (useBid) {
            uint256 bidY = BidAskLib.sellAtBid(bid, x);
            if (bidY < y) {
                fCache.protocolOwnedY += y - bidY;
                y = bidY;
            }
        }
        bidAsk.storePostSwapBid(sCache.sqrtP);
    }

    /// Buy up the price by supplying Y for X.
    /// @dev Does not commit the result to storage.
    function swapYForX(
        SwapStorage memory sCache,
        FeeCollector memory fCache,
        bool givenX,
        uint128 amount,
        Price limitSP
    ) internal returns (uint256 x, uint256 y) {
        BidAsk storage bidAsk = SwapStorageLib.bidAsk();
        Price ask = bidAsk.getAsk(sCache.sqrtP);
        bool useAsk = sCache.sqrtP.lt(ask);

        if (limitSP.lt(ask)) {
            revert SwapInputPriceLimit(false, ask.unwrap(), limitSP.unwrap());
        }

        if (givenX) {
            (x, y) = swapYForXGivenX(sCache, fCache, amount, limitSP);
        } // amount is y
        else {
            (x, y) = swapYForXGivenY(sCache, fCache, amount, limitSP);
        }

        // Limit the amount received by the ask.
        // Only necessary if the swap price was better than the ask.
        if (useAsk) {
            uint256 askX = BidAskLib.buyAtAsk(ask, y);
            if (askX < x) {
                fCache.protocolOwnedX += x - askX;
                x = askX;
            }
        }
        bidAsk.storePostSwapAsk(sCache.sqrtP);
    }

    /// Swap down the price by supplying exactly X in exchange for Y.
    function swapXForYGivenX(SwapStorage memory sCache, FeeCollector memory fCache, uint256 x, Price limitSP)
        internal
        returns (uint256 spentX, uint256 y)
    {
        TickTable storage table = TickStorageLib.tickTable();
        IterCache memory iter;

        spentX = x;
        iter.isDone = false;
        {
            // For sells, we can skip all the way to the last actively used tick because
            // the liquidity is the same all the way there.
            TableIndex tabIdx = table.getTableIndex(SqrtPriceLib.toTick(sCache.sqrtP));
            (, iter.tabIdx) = table.getAtOrPrevTableIndex(tabIdx);
        }

        // Here is loop through ticks.
        // We use the isDone variable to break, but there is an extra preparation step we must do
        // before we enter any next/prev tick so we can't use isDone as our loop condition.
        while (true) {
            iter.liq = sCache.mLiq - sCache.tLiq;

            Price newSP;
            {
                uint256 wholeXFee = fCache.feeCalc.calcFeeAmount(sCache.mLiq, sCache.tLiq, x);
                uint256 effX = x - wholeXFee;
                newSP = SwapMath.calcNewPriceFromAddX(iter.liq, sCache.sqrtP, effX);
            }
            Price nextSP = table.getTickIndex(iter.tabIdx).toSqrtPrice();

            // We can only go as far as the smallest of the limit, the next, and the new SP.
            if (newSP.lt(limitSP)) {
                newSP = limitSP;
            }
            if (newSP.lt(nextSP)) {
                newSP = nextSP;
            } else {
                // Stop if our newSP doesn't go to the next tick.
                iter.isDone = true;
            }

            // Accumulate.
            uint256 usedX = SwapMath.calcXFromPriceDelta(newSP, sCache.sqrtP, iter.liq, true);
            uint256 feeAmount = fCache.feeCalc.calcFeeAmount(sCache.mLiq, sCache.tLiq, usedX);

            x -= usedX + feeAmount;
            y += SwapMath.calcYFromPriceDelta(newSP, sCache.sqrtP, iter.liq, false);
            fCache.collectSwapFees(true, feeAmount, sCache.tLiq, iter.liq);

            // Update price wherever it ends up.
            sCache.sqrtP = newSP;
            // If it ended early. We're still in the same tick and nothing else needs to change.
            if (iter.isDone) {
                break;
            }

            TickData storage data = table.getData(iter.tabIdx);
            if (data.refCount > 0) {
                // If we're moving out of the tick we need to update liquidity.
                data.crossOutOf(sCache, fCache.globalFeeRateAccumulator);
            }
            // There is the interesting case where we are at a tick without any table entries.
            // This happens when we swap into regions with lots of consecutive empty ticks.
            // This is okay! And we should continue to swap. We'll attempt to swap up to the
            // last tick we attempted to search through which is conveniently the specification
            // for our TickTableImpl.get{Prev,Next}TableIndex() functions.
            // We also conveniently know we don't have to make any liquidity adjustments for these ticks.

            // It does not matter here if the prev table index was empty or not.
            (, iter.tabIdx) = table.getPrevTableIndex(iter.tabIdx);
        }
    }

    /// Swap down the price by specifying the amount of Y expected in return for the required X.
    /// @dev Does not commit the result to storage.
    /// Guaranteed to supply at LEAST the amount of y requested.
    function swapXForYGivenY(SwapStorage memory sCache, FeeCollector memory fCache, uint256 y, Price limitSP)
        internal
        returns (uint256 x, uint256 receivedY)
    {
        TickTable storage table = TickStorageLib.tickTable();
        IterCache memory iter;

        receivedY = y;
        iter.isDone = false;
        {
            // For sells, we can skip all the way to the last actively used tick because
            // the liquidity is the same all the way there.
            TableIndex tabIdx = table.getTableIndex(SqrtPriceLib.toTick(sCache.sqrtP));
            (, iter.tabIdx) = table.getAtOrPrevTableIndex(tabIdx);
        }

        while (true) {
            iter.liq = sCache.mLiq - sCache.tLiq;

            // We collect the fees from X, the tokens given in. So no fee adjusted y is needed.
            Price newSP = SwapMath.calcNewPriceFromSubY(iter.liq, sCache.sqrtP, y);

            {
                Price nextSP = table.getTickIndex(iter.tabIdx).toSqrtPrice();
                if (newSP.lt(limitSP)) {
                    newSP = limitSP;
                }
                if (newSP.lt(nextSP)) {
                    newSP = nextSP;
                } else {
                    iter.isDone = true;
                }
            }

            {
                // calcNewPrice overestimates price moves so calcYFromDelta can potentially
                // report numbers larger than the correct amount.
                // So here we cap the output amount to not exceed the remaining output amount
                uint256 yFromDelta = SwapMath.calcYFromPriceDelta(sCache.sqrtP, newSP, iter.liq, false);
                y -= (yFromDelta > y ? y : yFromDelta);
            }

            uint256 usedX = SwapMath.calcXFromPriceDelta(newSP, sCache.sqrtP, iter.liq, true);
            uint256 feeAmount = fCache.feeCalc.calcFeeAmount(sCache.mLiq, sCache.tLiq, usedX);
            x += usedX + feeAmount;
            fCache.collectSwapFees(true, feeAmount, sCache.tLiq, iter.liq);

            sCache.sqrtP = newSP;
            if (iter.isDone) {
                break;
            }

            // Cross out of the tick if possible.
            TickData storage data = table.getData(iter.tabIdx);
            if (data.refCount > 0) {
                data.crossOutOf(sCache, fCache.globalFeeRateAccumulator);
            }
            (, iter.tabIdx) = table.getPrevTableIndex(iter.tabIdx);
        }
    }

    /// Given a target output amount of X, swap up the price by providing Y.
    /// Guaranteed to provide exactly the amount of x requested.
    /// @dev Does not commit the result to storage.
    function swapYForXGivenX(SwapStorage memory sCache, FeeCollector memory fCache, uint256 x, Price limitSP)
        internal
        returns (uint256 receivedX, uint256 y)
    {
        TickTable storage table = TickStorageLib.tickTable();
        IterCache memory iter;

        receivedX = x;
        iter.isDone = false;
        iter.tabIdx = table.getTableIndex(SqrtPriceLib.toTick(sCache.sqrtP));

        while (true) {
            iter.liq = sCache.mLiq - sCache.tLiq;

            Price newSP = SwapMath.calcNewPriceFromSubX(iter.liq, sCache.sqrtP, x);

            // It's possible we don't find a next table index with an entry.
            // That's okay, we just swap up to there and continue our search from there.
            // From here on, iter.tabIdx is always the next index.
            (, iter.tabIdx) = table.getNextTableIndex(iter.tabIdx);
            {
                Price nextSP = table.getTickIndex(iter.tabIdx).toSqrtPrice();

                if (newSP.gt(limitSP)) {
                    newSP = limitSP;
                }
                if (newSP.gt(nextSP)) {
                    newSP = nextSP;
                } else {
                    // We don't leave this tick!
                    iter.isDone = true;
                }
            }

            // Accumulate
            {
                uint256 spentY = SwapMath.calcYFromPriceDelta(sCache.sqrtP, newSP, iter.liq, true);
                uint256 feeAmount = fCache.feeCalc.calcFeeAmount(sCache.mLiq, sCache.tLiq, spentY);

                y += spentY + feeAmount;

                fCache.collectSwapFees(false, feeAmount, sCache.tLiq, iter.liq);
            }

            {
                uint256 xFromDelta = SwapMath.calcXFromPriceDelta(sCache.sqrtP, newSP, iter.liq, false);
                // calcNewPrice overestimates price move so calcXFromDelta can potentially report numbers larger than the correct amount.
                // So here we cap the output amount to not exceed the remaining output amount
                if (xFromDelta > x) {
                    x = 0;
                } else {
                    x -= xFromDelta;
                }
            }

            sCache.sqrtP = newSP;
            if (iter.isDone) {
                break;
            }

            TickData storage data = table.getData(iter.tabIdx);
            if (data.refCount > 0) {
                data.crossInto(sCache, fCache.globalFeeRateAccumulator);
            }
        }
    }

    /// Given an input amount of Y, swap it to into X.
    /// @dev Does not commit the result to storage.
    function swapYForXGivenY(SwapStorage memory sCache, FeeCollector memory fCache, uint256 y, Price limitSP)
        internal
        returns (uint256 x, uint256 spentY)
    {
        TickTable storage table = TickStorageLib.tickTable();
        IterCache memory iter;

        spentY = y;
        iter.isDone = false;
        iter.tabIdx = table.getTableIndex(SqrtPriceLib.toTick(sCache.sqrtP));

        while (true) {
            iter.liq = sCache.mLiq - sCache.tLiq;

            Price newSP;
            {
                uint256 wholeYFee = fCache.feeCalc.calcFeeAmount(sCache.mLiq, sCache.tLiq, y);
                uint256 effY = y - wholeYFee;
                newSP = SwapMath.calcNewPriceFromAddY(iter.liq, sCache.sqrtP, effY);
            }

            // It's possible we don't find a next table index with an entry.
            // That's okay, we just swap up to there and continue our search from there.
            // From here on, iter.tabIdx is always the next index.
            (, iter.tabIdx) = table.getNextTableIndex(iter.tabIdx);

            {
                Price nextSP = table.getTickIndex(iter.tabIdx).toSqrtPrice();

                if (newSP.gt(limitSP)) {
                    newSP = limitSP;
                }
                if (newSP.gt(nextSP)) {
                    newSP = nextSP;
                } else {
                    // We don't leave this tick!
                    iter.isDone = true;
                }
            }

            // Accumulate
            uint256 usedY = SwapMath.calcYFromPriceDelta(sCache.sqrtP, newSP, iter.liq, true);
            uint256 feeAmount = fCache.feeCalc.calcFeeAmount(sCache.mLiq, sCache.tLiq, usedY);

            y -= usedY + feeAmount;
            x += SwapMath.calcXFromPriceDelta(sCache.sqrtP, newSP, iter.liq, false);
            fCache.collectSwapFees(false, feeAmount, sCache.tLiq, iter.liq);

            sCache.sqrtP = newSP;
            if (iter.isDone) {
                break;
            }

            TickData storage data = table.getData(iter.tabIdx);
            if (data.refCount > 0) {
                data.crossInto(sCache, fCache.globalFeeRateAccumulator);
            }
        }
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { PositionManager, PositionManagerImpl } from "Liq/Pos.sol";
import { Position, PositionImpl } from "Liq/Pos.sol";
import { PositionLib, PosID, PositionType } from "Liq/Pos.sol";
import { SwapStorageLib, SwapStorage, ImmutInfoStorage } from "Swap/Storage.sol";
import { LiqStorageLib } from "Liq/Storage.sol";
import { TickIndex, TickIndexImpl, Price, SqrtPriceLib } from "Ticks/Tick.sol";
import { TableIndex } from "Ticks/Table.sol";
import { TickTable, TickTableImpl } from "Ticks/TickTable.sol";
import { TickStorageLib } from "Ticks/Storage.sol";
import { LiqTableLib } from "Liq/Table.sol";
import { LiqMath } from "Liq/Math.sol";
import { SafeCast } from "Math/Cast.sol";
import { PMLib } from "Liq/PM.sol";
import { LiqTree, LiqTreeImpl, EarnTreeImpl } from "Liq/Tree.sol";
import { TransferLib } from "Pool/Transfer.sol";
import { Token, TokenImpl } from "Util/Token.sol";
import { RangeLiq, RangeLiqImpl, RangeBool } from "Liq/Structs.sol";
import { FeeRateSnapshot } from "Fee/Snap.sol";

contract LiqFacet {
    using PositionManagerImpl for PositionManager;
    using LiqTreeImpl for LiqTree;
    using EarnTreeImpl for LiqTree;
    using TokenImpl for Token;
    using PositionImpl for Position;
    using RangeLiqImpl for RangeLiq;
    using TickTableImpl for TickTable;
    using TickIndexImpl for TickIndex;

    event MakerOpened(uint128 liq, int24 lowerTick, int24 upperTick);
    event MakerClosed(uint128 liq, int24 lowerTick, int24 upperTick);
    event WideMakerOpened(uint128 liq);
    event WideMakerClosed(uint128 liq);

    event TakerCallOpened(uint128 liq, int24 lowerTick, int24 upperTick);
    event TakerCallClosed(uint128 liq, int24 lowerTick, int24 upperTick);
    event TakerPutOpened(uint128 liq, int24 lowerTick, int24 upperTick);
    event TakerPutClosed(uint128 liq, int24 lowerTick, int24 upperTick);

    /// Add unconcentrated liquidity
    function openWideMaker(address recipient, uint8 portID, uint128 liq) external returns (PosID posID){
        emit WideMakerOpened(liq);

        SwapStorage storage swaps = SwapStorageLib.load();

        // 1. Update tree liquidity for makers to fetch the fee rate first
        FeeRateSnapshot memory treeEarnSnap = LiqStorageLib.tree().addWideMLiq(liq);

        // 1. Install the position.
        PositionManager storage posMan = LiqStorageLib.posManager();
        Position memory pos = PositionLib.makeWideM(treeEarnSnap);
        posID = posMan.install(pos);
        PMLib.PMInstall(posID, recipient, portID);

        // 2. Update liquidity. No need to update table liquidity.
        swaps.mLiq += liq;

        // 4. Calculate holding requirements
        (uint256 x, uint256 y) = LiqMath.calcWideMakerHoldings(swaps.sqrtP, liq, true);

        // 5. Receive the appropriate amounts.
        ImmutInfoStorage storage info = SwapStorageLib.infoStorage();
        TransferLib.mintReceive(info.tokenX, info.tokenY, x, y);
    }

    /// Open a concentrated liquidity deposit.
    function openMaker(
        address recipient,
        uint8 portID,
        int24 lowerTick,
        int24 upperTick,
        uint128 liq
    ) external returns (PosID posID) {
        emit MakerOpened(liq, lowerTick, upperTick);

        // Validates the lower and upper ticks are spaced.
        RangeLiq memory rLiq = RangeLiqImpl.fromTicks(liq, lowerTick, upperTick);

        TickTable storage table = TickStorageLib.tickTable();
        SwapStorage storage swaps = SwapStorageLib.load();
        RangeBool rBool = rLiq.compare(swaps.sqrtP);

        //1. Update the liq tree and validate its correctness according to max utilization.
        //   This happens first for makers so we can get the earn snapshot.
        FeeRateSnapshot memory treeEarnSnap = LiqStorageLib.tree().addMLiq(rLiq);

        // 1. Create the position book keeping
        {
            PositionManager storage pm = LiqStorageLib.posManager();
            Position memory pos = PositionLib.makeM(
                rLiq, rBool, swaps.sqrtP, treeEarnSnap, table);
            posID = pm.install(pos);
            PMLib.PMInstall(posID, recipient, portID);
        }

        //2. Update the swap liquidity if in range.
        if (rBool == RangeBool.Within)
            swaps.mLiq += liq;

        //3. Update the tick table
        LiqTableLib.addMakerLiq(table, rLiq);

        //5. Tally the amount required to deposit.
        (uint256 neededX, uint256 neededY) = LiqMath.calcMakerHoldings(rLiq, swaps.sqrtP, true);

        //6. Receive the appropriate amounts.
        // We MUST do this last because they may call back into this contract.
        // The above operations have committed their position to our bookkeeping
        // so we can think of it as the position has already been opened, but we
        // may receive the amounts requested at a later time, specifically a few
        // transactions later.
        ImmutInfoStorage storage info = SwapStorageLib.infoStorage();
        TransferLib.mintReceive(info.tokenX, info.tokenY, neededX, neededY);
    }

    /// Open a Taker position with the upside covariant to the pool's price.
    function openTakerCall(
        address recipient,
        uint8 portID,
        int24 lowerTick,
        int24 upperTick,
        uint128 liq,
        bytes calldata data
    ) external returns (PosID posID) {
        emit TakerCallOpened(liq, lowerTick, upperTick);

        RangeLiq memory rLiq = RangeLiqImpl.fromTicks(liq, lowerTick, upperTick);

        // Solc can't drop the param stack vars summarized in rLiq without jumping
        // into a new function.
        return openTakerCallHelper(recipient, portID, data, rLiq);
    }

    /// Open a Taker position with the upside contravariant with the pool's price.
    function openTakerPut(
        address recipient,
        uint8 portID,
        int24 lowerTick,
        int24 upperTick,
        uint128 liq,
        bytes calldata data
    ) external returns (PosID posID) {
        emit TakerPutOpened(liq, lowerTick, upperTick);

        RangeLiq memory rLiq = RangeLiqImpl.fromTicks(liq, lowerTick, upperTick);

        // Solc can't drop the param stack vars summarized in rLiq without jumping
        // into a new function.
        return openTakerPutHelper(recipient, portID, data, rLiq);
    }

    /// Close any position type by supplying the position id.
    function close(address resolver, PosID posID, bytes calldata instructions)
    public returns (int256 x, int256 y) {
        PositionManager storage pm = LiqStorageLib.posManager();
        Position memory pos = pm.uninstall(posID);

        if (pos.posType == PositionType.Maker) {
            (uint256 ux, uint256 uy) = closeMaker(resolver, pos);
            x = SafeCast.toInt256(ux);
            y = SafeCast.toInt256(uy);
        } else if (pos.posType == PositionType.WideMaker) {
            (uint256 ux, uint256 uy) = closeWideMaker(resolver, pos);
            x = SafeCast.toInt256(ux);
            y = SafeCast.toInt256(uy);
        } else if (pos.posType == PositionType.TakerCall) {
            (x, y) = closeTakerCall(resolver, pos, instructions);
        } else {
            (x, y) = closeTakerPut(resolver, pos, instructions);
        }
    }

    /// Value a position. Can be called by other contracts but also
    /// used for IProducer.queryValue.
    function value(uint256 posID) public view returns (int256 x, int256 y) {
        PositionManager storage pm = LiqStorageLib.posManager();
        Position memory pos = pm.get(PosID.wrap(posID));

        if (pos.posType == PositionType.WideMaker) {
            FeeRateSnapshot memory treeEarnSnap = LiqStorageLib.tree().wideEarnSnap();
            SwapStorage storage swaps = SwapStorageLib.load();
            (uint256 ux, uint256 uy) = valueWideMaker(pos, swaps, treeEarnSnap);
            x = SafeCast.toInt256(ux);
            y = SafeCast.toInt256(uy);
        } else {
            TickTable storage table = TickStorageLib.tickTable();
            SwapStorage storage swaps = SwapStorageLib.load();
            RangeLiq memory rLiq = pos.rangeLiq();

            if (pos.posType == PositionType.Maker) {
                LiqTree storage tree = LiqStorageLib.tree();
                FeeRateSnapshot memory earnSnap = tree.earnSnap(rLiq.low, rLiq.high);
                (uint256 ux, uint256 uy) = valueMaker(pos, table, swaps.sqrtP, earnSnap, rLiq);
                x = SafeCast.toInt256(ux);
                y = SafeCast.toInt256(uy);
            } else if (pos.posType == PositionType.TakerCall) {
                (x, y, , ) = valueTakerCall(pos, table, swaps.sqrtP, rLiq);
            } else {
                (x, y, , ) = valueTakerPut(pos, table, swaps.sqrtP, rLiq);
            }
        }
    }

    /// Split a percent of the position into a new position.
    /// @return splitPositionID the Position ID of the new split-off position.
    function split(PosID posID, address owner, uint8 portID, uint128 splitPercentX128) public returns (uint256 splitPositionID) {
        // When splitting the liquidity in our swapStorage, table, and tree don't need to change.
        // The fees also have to be split according to the percent as well.
        // However since everything is stored as rates, we only need to split the liq and borrow amounts
        // to split the fees, which we need to do anyways. And the borrow is just a function of liq
        // so that is automatically split as well.
        // The amount deposited is also already in the pool, so no need to change anything there.

        // Thus we just have to change the position values, and ensure the rounding is correct everywhere.
        // The new positions might sum up to a slightly lower value due to rounding, but not enough
        // to make a difference in liquidations because the difference is dwarfed by market price action.

        // This is true REGARDLESS OF THE POSITION TYPE!!!!

        PositionManager storage pm = LiqStorageLib.posManager();
        Position storage original = pm.get(posID);
        uint256 liq = original.liquidity;
        uint128 splitLiq = uint128((liq * uint256(splitPercentX128)) >> 128);

        Position memory newPos = original;

        // Modify liquidities
        newPos.liquidity = splitLiq;
        original.liquidity -= splitLiq;

        // Register new position.
        PosID newPosID = pm.install(newPos);
        splitPositionID = PMLib.PMInstall(newPosID, owner, portID);

        // The only place where we actually track the number of positions is in TickData,
        // so we'll update those numbers for this positions ticks.
        TickTable storage table = TickStorageLib.tickTable();
        LiqTableLib.splitLiq(table, newPos.low, newPos.high);
    }

    /* Internal functions below */

    /// Helper that saves stack space and actually opens the Taker Call position.
    function openTakerCallHelper(
        address recipient, uint8 portID, bytes calldata data,
        RangeLiq memory rLiq
    ) internal returns (PosID posID) {
        uint256 holdingX;
        uint256 borrowedX;
        uint256 borrowedY;
        {
            SwapStorage storage swaps = SwapStorageLib.load();
            TickTable storage table = TickStorageLib.tickTable();
            RangeBool rBool = rLiq.compare(swaps.sqrtP);

            // 1. Create the position book keeping
            PositionManager storage pm = LiqStorageLib.posManager();
            Position memory pos = PositionLib.makeT(
                PositionType.TakerCall, rLiq, rBool, swaps.sqrtP, table);
            posID = pm.install(pos);
            PMLib.PMInstall(posID, recipient, portID);

            // 2. Update the liquidity if in range.
            if (rBool == RangeBool.Within)
                swaps.tLiq += rLiq.liq;

            // 3. Update the tick table
            LiqTableLib.addTakerLiq(table, rLiq);

            // 4. Tally the amount required to deposit.
            (holdingX, borrowedX, borrowedY) = LiqMath.calcTakerCallAmounts(rLiq, swaps.sqrtP, true);

            // 5. Update the liq tree and validate its correctness according to max utilization.
            LiqTree storage tree = LiqStorageLib.tree();
            tree.addTLiq(rLiq, borrowedX, borrowedY);
        }

        // 7. Receive the appropriate amounts.
        // ALWAYS DO THIS LAST! See openMakerPosition for details.
        ImmutInfoStorage storage info = SwapStorageLib.infoStorage();
        // If borrowedY is zero, then the borrowedX is equal to the heldX and there is no need for any transfers or receives.
        if (borrowedY > 0) {
            info.tokenY.transfer(recipient, borrowedY);
            TransferLib.takerOpenSwapReceive(info.tokenX, true, holdingX - borrowedX, borrowedY, data);

            // 8. Lend the held tokens out on a money market.
            // TODO: lend holdingX
        }
    }

    /// Helper that saves stack space and actually opens the Taker Put position.
    function openTakerPutHelper(
        address recipient, uint8 portID, bytes calldata data,
        RangeLiq memory rLiq
    ) internal returns (PosID posID) {
        uint256 holdingY;
        uint256 borrowedX;
        uint256 borrowedY;
        {
            TickTable storage table = TickStorageLib.tickTable();
            SwapStorage storage swaps = SwapStorageLib.load();
            RangeBool rBool = rLiq.compare(swaps.sqrtP);

            // 1. Create the position book keeping
            PositionManager storage pm = LiqStorageLib.posManager();
            Position memory pos = PositionLib.makeT(
                PositionType.TakerPut, rLiq, rBool, swaps.sqrtP, table);
            posID = pm.install(pos);
            PMLib.PMInstall(posID, recipient, portID);

            // 2. Update the liquidity if in range.
            if (rBool == RangeBool.Within)
                swaps.tLiq += rLiq.liq;

            // 3. Update the tick table
            LiqTableLib.addTakerLiq(table, rLiq);

            // 4. Tally the amount required to deposit.
            (holdingY, borrowedX, borrowedY) = LiqMath.calcTakerPutAmounts(rLiq, swaps.sqrtP, true);

            // 5. Update the liq tree and validate its correctness according to max utilization.
            LiqTree storage tree = LiqStorageLib.tree();
            tree.addTLiq(rLiq, borrowedX, borrowedY);
        }

        // 6. Receive the appropriate amounts.
        ImmutInfoStorage storage info = SwapStorageLib.infoStorage();
        // If borrowedX is zero, then the borrowedY is equal to the heldY and there is no need for any transfers or receives.
        if (borrowedX > 0) {
            info.tokenX.transfer(recipient, borrowedX);
            TransferLib.takerOpenSwapReceive(info.tokenY, false, borrowedX, holdingY - borrowedY, data);

            // 8. Lend the held tokens out on a money market.
            // TODO: lend holdingY
        }
    }

    function closeMaker(
        address resolver,
        Position memory pos
    ) internal returns (uint256 x, uint256 y) {
        TickTable storage table = TickStorageLib.tickTable();
        SwapStorage storage swaps = SwapStorageLib.load();

        RangeLiq memory rLiq = pos.rangeLiq();

        // 1. Makers update Tree Liquidity first to get the fee snapshot
        FeeRateSnapshot memory treeEarnSnap = LiqStorageLib.tree().subMLiq(rLiq);

        // 2. Value position
        (x, y) = valueMaker(pos, table, swaps.sqrtP, treeEarnSnap, rLiq);

        // 3. Update Table Liquidity
        LiqTableLib.removeMakerLiq(table, rLiq);

        // 4. Update Swap Liquidity if necessary
        if (rLiq.contains(swaps.sqrtP))
            swaps.mLiq -= rLiq.liq;

        // 6. Give amounts
        ImmutInfoStorage storage info = SwapStorageLib.infoStorage();
        if (x > 0) {
            info.tokenX.transfer(resolver, x);
        }
        if (y > 0) {
            info.tokenY.transfer(resolver, y);
        }
    }

    function valueMaker(
        Position memory pos,
        TickTable storage table,
        Price currentSP,
        FeeRateSnapshot memory treeSnap,
        RangeLiq memory rLiq
    ) internal view returns (uint256 x, uint256 y) {
        RangeBool rBool = rLiq.compare(currentSP);
        (uint256 xFees, uint256 yFees) = pos.calcMakerFees(rBool, table, treeSnap);

        (x, y) = LiqMath.calcMakerHoldings(rLiq, currentSP, false);
        x += xFees;
        y += yFees;
    }

    function closeWideMaker(address resolver, Position memory pos) internal returns (uint256 x, uint256 y) {
        SwapStorage storage swaps = SwapStorageLib.load();

        // 1. Update Tree liquidity first for Makers
        uint128 liq = pos.liquidity;
        FeeRateSnapshot memory treeEarnSnap = LiqStorageLib.tree().subWideMLiq(liq);

        // 2. Value position
        (x, y) = valueWideMaker(pos, swaps, treeEarnSnap);

        // 3. Update swap liquidity
        swaps.mLiq -= liq;

        // 4. Give amounts
        ImmutInfoStorage storage info = SwapStorageLib.infoStorage();
        if (x > 0) {
            info.tokenX.transfer(resolver, x);
        }
        if (y > 0) {
            info.tokenY.transfer(resolver, y);
        }
    }

    function valueWideMaker(Position memory pos, SwapStorage storage swaps, FeeRateSnapshot memory treeEarnSnap)
    internal view returns (uint256 x, uint256 y) {
        // 1. Collect fees
        (uint256 xFees, uint256 yFees) = pos.calcWideMakerFees(treeEarnSnap);

        // 2. Collect position value.
        (x, y) = LiqMath.calcWideMakerHoldings(swaps.sqrtP, pos.liquidity, false);
        x += xFees;
        y += yFees;
    }

    function closeTakerCall(
        address resolver,
        Position memory pos,
        bytes calldata instructions
    ) internal returns (int256 x, int256 y) {
        {
            TickTable storage table = TickStorageLib.tickTable();
            SwapStorage storage swaps = SwapStorageLib.load();

            RangeLiq memory rLiq = pos.rangeLiq();

            // 1. Value position
            uint256 borrowedX;
            uint256 borrowedY;
            (x, y, borrowedX, borrowedY) = valueTakerCall(pos, table, swaps.sqrtP, rLiq);

            // 2. Update Table Liquidity
            LiqTableLib.removeTakerLiq(table, rLiq);

            // 3. Update Swap Liquidity if necessary
            if (rLiq.contains(swaps.sqrtP))
                swaps.tLiq -= rLiq.liq;

            // 4. Update Tree Liquidity
            LiqTree storage tree = LiqStorageLib.tree();
            tree.subTLiq(rLiq, borrowedX, borrowedY);
        }

        // 5. Give amounts
        ImmutInfoStorage storage info = SwapStorageLib.infoStorage();
        // It's only possible for X to be positive.
        if (x > 0) {
            info.tokenX.transfer(resolver, uint256(x));
        }
        TransferLib.takerExerciseReceive(resolver, info.tokenX, info.tokenY, -x, -y, instructions);
    }

    function valueTakerCall(
        Position memory pos,
        TickTable storage table,
        Price currentSP,
        RangeLiq memory rLiq
    ) internal view returns (int256 x, int256 y, uint256 makerX, uint256 makerY) {
        RangeBool rBool = rLiq.compare(currentSP);
        (uint256 xFees, uint256 yFees) = pos.calcTakerFees(rLiq.lowSP, rLiq.highSP, rBool, table);

        uint256 takerX;
        (takerX, makerX, makerY) =
        LiqMath.calcTakerCallAmounts(rLiq, currentSP, false);
        x = SafeCast.toInt256(takerX);
        x -= SafeCast.toInt256(makerX + xFees);
        y = -SafeCast.toInt256(makerY + yFees);
    }

    function closeTakerPut(
        address resolver,
        Position memory pos,
        bytes calldata instructions
    ) internal returns (int256 x, int256 y) {
        {
            TickTable storage table = TickStorageLib.tickTable();
            SwapStorage storage swaps = SwapStorageLib.load();

            RangeLiq memory rLiq = pos.rangeLiq();

            // 1. Value position
            uint256 borrowedX;
            uint256 borrowedY;
            (x, y, borrowedX, borrowedY) = valueTakerPut(pos, table, swaps.sqrtP, rLiq);

            // 2. Update Table Liquidity
            LiqTableLib.removeTakerLiq(table, rLiq);

            // 3. Update Swap Liquidity if necessary
            if (rLiq.contains(swaps.sqrtP))
                swaps.tLiq -= rLiq.liq;

            // 4. Update Tree Liquidity
            LiqTree storage tree = LiqStorageLib.tree();
            tree.subTLiq(rLiq, borrowedX, borrowedY);
        }

        // 5. Give amounts
        ImmutInfoStorage storage info = SwapStorageLib.infoStorage();
        // It's only possible for Y to be positive.
        if (y > 0) {
            info.tokenY.transfer(resolver, uint256(y));
        }
        TransferLib.takerExerciseReceive(resolver, info.tokenX, info.tokenY, -x, -y, instructions);
    }

    function valueTakerPut(
        Position memory pos,
        TickTable storage table,
        Price currentSP,
        RangeLiq memory rLiq
    ) internal view returns (int256 x, int256 y, uint256 makerX, uint256 makerY) {
        RangeBool rBool = rLiq.compare(currentSP);
        (uint256 xFees, uint256 yFees) = pos.calcTakerFees(rLiq.lowSP, rLiq.highSP, rBool, table);

        // 2. Collect position value.
        uint256 takerY;
        (takerY, makerX, makerY) =
        LiqMath.calcTakerPutAmounts(rLiq, currentSP, false);
        x = -SafeCast.toInt256(makerX + xFees);
        y = SafeCast.toInt256(takerY);
        y -= SafeCast.toInt256(makerY + yFees);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { FeeCollector } from "Fee/Fees.sol";

library FeeStorageLib {
    bytes32 constant FEE_STORAGE_POSITION = keccak256("v4.fee.diamond.storage");

    // This is the number of slots the storage type takes up (struct byte size / 32)
    // CAREFUL: This needs to be updated when the storage type changes because the Solidity compiler
    // doesn't currently expose struct sizes.
    uint256 constant NUM_SLOTS = 9;

    function load() internal pure returns (FeeCollector storage fs) {
        bytes32 position = FEE_STORAGE_POSITION;
        assembly {
            fs.slot := position
        }
    }

    /// A custom storage function for writing back FeeCollector values to storage.
    /// This is meant for conventional use AFTER initialization and will not initialize variables
    /// that are semantically immutable.
    /// @dev We only write back certain variables because members like the FeeCal are expected to
    /// not change during the lifetime of this contract.
    /// TODO explore ways of storing the entire struct back without going entry by entry.
    /// see below for example code.
    function store(FeeCollector memory fCache) internal {
        FeeCollector storage stored = load();
        stored.protocolOwnedX = fCache.protocolOwnedX;
        stored.protocolOwnedY = fCache.protocolOwnedY;
        stored.globalFeeRateAccumulator = fCache.globalFeeRateAccumulator;
    }

    // One day we can explore doing something like this to avoid using multiple SSTORES
    // for variables that share the same slot in memory.
    // bytes32 position = FEE_STORAGE_POSITION;
    // for (uint256 i = 0; i < NUM_SLOTS; ++i) {
    //     assembly ("memory-safe") {
    //         let loaded := mload(add(fCache, i))
    //         sstore(add(position, i), loaded)
    //     }
    // }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { X128 } from "Math/Ops.sol";
import { UnsafeMath } from "Math/UnsafeMath.sol";
import { SafeCast } from "Math/Cast.sol";
import { Accum, AccumImpl } from "Util/Accum.sol";

/// Type used to calculate swap fees.
struct FeeCalculator {
    uint256 invAlphaX224;
    uint128 betaX96;
    uint128 maxUtil; // X128 since always less than 1.
}

/**
 * @notice Math utilities for calculating swap fees
 * @dev The FeeCalculator should be used in memory since we read it once.
 **/
library FeeCalculatorImpl {
    using SafeCast for uint256;
    using SafeCast for int256;

    uint128 private constant BETA_OFFSET = 1 << 96;
    uint128 private constant ONEX96 = type(uint96).max;

    error OverUtilization(uint128 maxUtil, uint128 util);

    /// @notice Initialization function to be called on contract setup on its FeeCalculator.
    /// @param betaX96 is the beta term but notice it's a signed int because beta can be negative.
    /// To accomodate the signed bit we only use X96 in a 128 bit number.
    /// @param maxUtilX128 is always positive and less than 1 so we use the full 128 bits for the decimal places.
    /// This way both beta and maxUtil can fit into one storage slot.
    /// @param invAlphaX224 is X224 because it gets divided by the util units and the result should be in the
    /// same units as beta which is the units the fee rate will be in. Thus 96 + 128 = 224.
    /// @dev To avoid casts back and forth and doing operations with a signed value and unsigned values, we offset
    /// beta by an amount and subtract the offset when actually calculating the fee rate.
    function init(FeeCalculator memory self, uint256 invAlphaX224, int128 betaX96, uint128 maxUtilX128) internal pure {
        self.invAlphaX224 = invAlphaX224;
        self.betaX96 = int256(betaX96 + int128(BETA_OFFSET)).toUint128();
        self.maxUtil = maxUtilX128;
    }

    /// @notice Calculate the fee rate to be paid at this tick according to liquidity utilization based on takers.
    /// @dev We're calculating feeRate = beta + invAlpha / (maxUtil - util)
    /// This means feeRate and the two summands have the same x96 units.
    function calcFeeRate(
        FeeCalculator memory self,
        uint128 mLiq,
        uint128 tLiq
    ) internal pure returns (uint96 feeRateX96) {
        // utilizations are always X128
        uint128 util = ((uint256(tLiq) << 128) / mLiq).toUint128(); // Implicitly checks tLiq < mLiq;

        if (util > self.maxUtil) {
            revert OverUtilization(self.maxUtil, util);
        }

        uint256 fullFeeRate = self.betaX96 + self.invAlphaX224 / (self.maxUtil - util) - BETA_OFFSET;

        // We don't allow fee rates over one of course since swaps just become a money pit.
        if (fullFeeRate > ONEX96) {
            fullFeeRate = ONEX96;
        }

        feeRateX96 = uint96(fullFeeRate);
    }

    /// Calc the nominal amount of fees applicable to the given traded value.
    function calcFeeAmount(
        FeeCalculator memory self,
        uint128 mLiq,
        uint128 tLiq,
        uint256 val
    ) internal pure returns (uint256 feeAmount) {
        // Widen to 128 to use X128 lib.
        uint128 feeRateX96 = calcFeeRate(self, mLiq, tLiq);
        feeAmount = X128.mul256RoundUp(feeRateX96 << 32, val);
    }
}

/// Type used to track fees earned by ticks
struct FeeRateAccumulator {
    Accum MX; // Maker earned X
    Accum MY;
    Accum TX; // Taker owed X
    Accum TY;
}

/**
 * @notice Convenience functions for accumulating fees earned by ticks
 **/
library FeeRateAccumulatorImpl {
    using AccumImpl for Accum;

    /// Subtract this accumulator from another, and store the results in this one.
    /// @dev We're subtracting an in-memory accumulator from an in-storage accumulator.
    /// This is used for crossing table ticks.
    function subFrom(FeeRateAccumulator storage self, FeeRateAccumulator memory other) internal {
        self.MX = other.MX.diffAccum(self.MX);
        self.MY = other.MY.diffAccum(self.MY);
        self.TX = other.TX.diffAccum(self.TX);
        self.TY = other.TY.diffAccum(self.TY);
    }
}

/// Overall type used to interface fees by both swaps and liquidity ops
struct FeeCollector { // 9 * 32 Bytes
    FeeCalculator feeCalc; // 512 bits;

    uint128 protocolTakeRate; // X128, 128bits;
    uint128 _extraSpacing;

    /* 256 */

    uint256 protocolOwnedX;
    uint256 protocolOwnedY;

    // Accumulator variables
    // These are stored last so that we can extend the struct with rewards if needed.
    FeeRateAccumulator globalFeeRateAccumulator; // 1024 bits
}

/// Main functions for collecting fees from swaps
library FeeCollectorImpl {
    using AccumImpl for Accum;

    error CollectSizeTooLarge();
    // If this is encountered, we just have to add liquidity to the current tick
    // to "fix" the state, until a code patch is pushed.
    error ImproperSwapState();

    /// Collect the given fees from the swapper, and then charge the appropriate amount to Takers.
    /// @param liq This is mLiq - tLiq, we use the overall net liq here for convenience
    /// @dev since the fee is the amount paid by the trader, we calculate fee*tLiq/liq to get the
    /// fees charged to Takers.
    /// If liq is 0 this will have division error. We should never be collecting fees when there is no
    function collectSwapFees(
        FeeCollector memory self,
        bool isX,
        uint256 traderFees,
        uint128 tLiq,
        uint128 liq
    ) internal pure {
        // We avoid Fullmath muldiv here by restricting fees to a uint128.
        // It is HIGHLY unlikely fees will be over uint128's max so instead of eating an extra 400 gas
        // to accomodate it, we revert.
        if (traderFees > type(uint128).max) {
            // Could report the largest collect/swap size later if it's important.
            revert CollectSizeTooLarge();
        }

        if (liq == 0) {
            // There should be no fees to collect.
            if (traderFees != 0) {
                revert ImproperSwapState();
            }
            return;
        }

        uint256 takerFeeRateX128 = UnsafeMath.divRoundingUp((traderFees << 128), liq);
        uint256 takerFees = X128.mul256RoundUp(tLiq, takerFeeRateX128);

        uint256 totalFees = takerFees + traderFees;
        // Rounds down.
        uint256 protocolTake = X128.mul256(self.protocolTakeRate, totalFees);

        uint256 makerFees = totalFees - protocolTake;
        uint256 makerFeeRate = makerFees / (tLiq + liq);

        uint256 takerFeeRate;
        uint256 mod128 = 1 << 128;
        assembly {
            takerFeeRate := add(shr(128, takerFeeRateX128), gt(mod(takerFeeRateX128, mod128), 0))
        }

        if (isX) {
            self.globalFeeRateAccumulator.MX = self.globalFeeRateAccumulator.MX.add(makerFeeRate);
            self.globalFeeRateAccumulator.TX = self.globalFeeRateAccumulator.TX.add(takerFeeRate);
            self.protocolOwnedX += protocolTake;
        } else {
            self.globalFeeRateAccumulator.MY = self.globalFeeRateAccumulator.MY.add(makerFeeRate);
            self.globalFeeRateAccumulator.TY = self.globalFeeRateAccumulator.TY.add(takerFeeRate);
            self.protocolOwnedY += protocolTake;
        }
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { Token } from "Util/Token.sol";
import { Price } from "Ticks/Tick.sol";
import { TableIndex } from "Ticks/Table.sol";
import { BidAsk } from "Swap/BidAsk.sol";

/**
 * @notice
 */
library SwapStorageLib {
    bytes32 constant SWAP_STORAGE_POSITION = keccak256("v4.swap.diamond.storage");
    bytes32 constant INFO_STORAGE_POSITION = keccak256("v4.info.diamond.storage");
    bytes32 constant BIDASK_STORAGE_POSITION = keccak256("v4.bidask.diamond.storage");

    /// Load swap relevant data.
    /// @dev We aren't guaranteed that functions get inlined so we'll redundantly write these stubs for now.
    function load() internal pure returns (SwapStorage storage ss) {
        bytes32 position = SWAP_STORAGE_POSITION;
        assembly {
            ss.slot := position
        }
    }

    /// Write back swap relevant data.
    /// @dev for now we do it field by field, but we can explore more clever ways of writing
    /// back slots into storage that are field agnostic.
    function store(SwapStorage memory sCache) internal {
        SwapStorage storage ss = load();
        // These two fields could be written back with one SSTORE if we can figure out the assembly
        // to do it.
        ss.mLiq = sCache.mLiq;
        ss.tLiq = sCache.tLiq;

        ss.sqrtP = sCache.sqrtP;
    }

    /// Load the semantically immutable informational fields for this AMM.
    /// @dev we may consider moving this to another file since it is used beyond just swaps.
    function infoStorage() internal pure returns (ImmutInfoStorage storage iis) {
        bytes32 position = INFO_STORAGE_POSITION;
        assembly {
            iis.slot := position
        }
    }

    /// Load the bidAsk struct for exploit prevention.
    function bidAsk() internal pure returns (BidAsk storage bas) {
        bytes32 position = BIDASK_STORAGE_POSITION;
        assembly {
            bas.slot := position
        }
    }
}

/// This is not really immutable at the moment. We'll have to figure out how to
/// use immutable storage in Diamond Patterns.
struct ImmutInfoStorage {
    Token tokenX; // 160 bits
    Token tokenY; // 160
    address PM; // The external PositionManager
}

struct SwapStorage {
    uint128 mLiq;
    uint128 tLiq;

    // The price of the pool. Swapping changes this price.
    Price sqrtP; // 160 bits

    /*
      We could store the TableIndex so LiqFacet can use it without
      computing it every time.
      We choose not to because we would either store:
      1. The TableIndex the swap last landed on.
      2. The TableIndex corresponding to the current price.
      These are NOT the same.

      1. can be a tick well below 2. 1. is either an initialized tick
      or the furthest tick we searched. Adding liquidiy can change which
      tick is the largest initialized tick below the current sqrtP. Thus
      storing 1. is unreliable.

      2. must be computed at the end of the swap for around ~3000 gas (Price to Tick)
      and stored for another ~5000 gas and then read for 2100 gas. Ultimately
      what we need to know for LiqFacet is where the current price is relative
      to a range. It is cheaper to convert two tableIndex's (the range) into
      prices to do the comparison (< 1000 gas each) than to even do the read.
      Thus we avoid ever computing the current TableIndex and always use the sqrt price
      outside of modifying the TickTable and LiquidityTree.
    */
}

// SPDX-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { PositionManager } from "Liq/Pos.sol";
import { LiqTree } from "Liq/Tree.sol";
import { TBP } from "Liq/Borrow.sol";

library LiqStorageLib {
    bytes32 constant POS_STORAGE_POSITION = keccak256("v4.pos.diamond.storage");
    bytes32 constant TREE_STORAGE_POSITION = keccak256("v4.tree.diamond.storage");
    bytes32 constant XTBP_STORAGE_POSITION = keccak256("v4.xtbp.diamond.storage");
    bytes32 constant YTBP_STORAGE_POSITION = keccak256("v4.ytbp.diamond.storage");

    // @dev We don't have a store function right now because position manager is just interacted
    // with directly from storage.
    function posManager() internal pure returns (PositionManager storage pm) {
        bytes32 position = POS_STORAGE_POSITION;
        assembly {
            pm.slot := position
        }
    }

    function tree() internal pure returns (LiqTree storage lTree) {
        bytes32 position = TREE_STORAGE_POSITION;
        assembly {
            lTree.slot := position
        }
    }

    /// Fetches the Taker Borrow Pool for the x token.
    function xTBP() internal pure returns (TBP storage tbp) {
        bytes32 position = XTBP_STORAGE_POSITION;
        assembly {
            tbp.slot := position
        }
    }

    /// Fetches the Taker Borrow Pool for the y token.
    function yTBP() internal pure returns (TBP storage tbp) {
        bytes32 position = YTBP_STORAGE_POSITION;
        assembly {
            tbp.slot := position
        }
    }

}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { TickTable } from "Ticks/TickTable.sol";

library TickStorageLib {
    bytes32 constant TICKTABLE_STORAGE_POSITION = keccak256("v4.ticktable.diamond.storage");

    function tickTable() internal pure returns (TickTable storage table) {
        bytes32 position = TICKTABLE_STORAGE_POSITION;
        assembly {
            table.slot := position
        }
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { Accum, AccumImpl } from "Util/Accum.sol";

// @notice The data structure for tracking interest accrued by Taker borrows.
// @dev Note that we don't write down the borrow amount.
// That is stored in the Position struct. We convenient don't need it to calculate
// the cumulativeEarningsPerToken.
// We calculate cumulative (borrow * APR * time / borrow) thus the borrow cancels.
struct TBP {
    Accum cumulativeEarningsPerTokenX32; // 256 bits

    // The current interest rate as an X64 number.
    // This is Seconds Percentage Rate.
    // This should be the APR divided by 365 * 24 * 60 * 60.
    // We support a min rate of 0.01% APR which is roughly 3e-12 SPR.
    // And a max rate of 100,000% APR which is 3e-5 SPR.
    // Thus as decimal bits, the first significant bit will be after the 14th decimal
    // bit and leading bit will never be after the 39th decimal.
    // Thus an X64, 64 bit number is more than sufficient.
    uint64 SPRX64;

    // Last Unix timstamp at which any node in our tree has accumulated tsecs.
    // We update this timestamp whenever any node in our subtree updates its tLiq.
    uint64 lastTimestamp;

    // The address who can update the SPRX64. This is validated in the TBPFacet.
    address ratePusher;
}

library TBPImpl {
    using AccumImpl for Accum;

    /// Throw error if the new timestamp is younger than the old timestamp.
    error TimestampManipulation(uint64 newTime, uint64 oldTime);

    event TBPUpdatedSPR(uint64 newSPRX64, uint64 timestamp);

    /// TBPs are initialized with this borrow rate. An admin should set the rate pusher
    /// to fetch a real borrow rate.
    /// This default is chosen for tokens that don't have a reliable rate oracle, which skews towards the higher borrow-cost tokens.
    /// Right now this reflects a 15% APR.
    /// .15 / (365 * 24 * 60 * 60) * 2^64
    uint64 constant DEFAULT_SPRX64 = 87741362604;

    // 0.5 in X64
    uint256 constant X64HALF = 1 << 63;

    /// Update the current rate with a new second percent rate.
    /// This also collects the fee to be up-to-date.
    function updateSPR(TBP storage self, uint64 newSPRX64) internal returns (Accum cumEarnPerTokenX32) {
        emit TBPUpdatedSPR(newSPRX64, uint64(block.timestamp));

        cumEarnPerTokenX32 = collect(self);
        self.SPRX64 = newSPRX64;
    }

    /// Collects the fees up to the current time and returns the updated fee accumulation.
    function collect(TBP storage self) internal returns (Accum cumEarnPerTokenX32) {
        self.cumulativeEarningsPerTokenX32 = value(self);
        self.lastTimestamp = uint64(block.timestamp);
        return self.cumulativeEarningsPerTokenX32;
    }

    /// When the rate doesn't change, we don't actually need to collect any fees as long
    /// as we don't change the timestamp either.
    /// Thus to keep certain methods view methods, we use this function to get an up to date
    /// value of the cumulative earn without actually collecting and modifying storage.
    function value(TBP storage self) internal view returns (Accum cumEarnPerTokenX32) {
        uint64 newTime = uint64(block.timestamp);
        if (newTime < self.lastTimestamp) {
            revert TimestampManipulation(newTime, self.lastTimestamp);
        }

        uint256 collectedX64 = self.SPRX64 * (newTime - self.lastTimestamp);
        uint256 collectedX32 = (collectedX64 >> 32);
        assembly {
            collectedX32 := add(collectedX32, gt(and(collectedX64, X64HALF), 0))
        }
        cumEarnPerTokenX32 = self.cumulativeEarningsPerTokenX32.add(collectedX32);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

type TickIndex is int24;
type Price is uint160; // Price is a 64X96 value.

/// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128.
/// Tick indices are inclusive of the min tick.
int24 constant MIN_TICK = -887272;
/// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
/// Tick indices are exclusive of the max tick.
int24 constant MAX_TICK = -MIN_TICK;

/// @dev The minimum sqrt price we can have. Equivalent to toSqrtPrice(MIN_TICK). Inclusive.
uint160 constant MIN_SQRT_RATIO = 4295128739;
/// @dev The maximum sqrt price we can have. Equivalent to toSqrtPrice(MAX_TICK). Exclusive.
uint160 constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
Price constant MIN_PRICE = Price.wrap(MIN_SQRT_RATIO);
Price constant MAX_PRICE = Price.wrap(MAX_SQRT_RATIO);

library TickLib {
    /// How to create a TickIndex for user facing functions
    function newTickIndex(int24 num) public pure returns (TickIndex res) {
        res = TickIndex.wrap(num);
        TickIndexImpl.validate(res);
    }
}

/**
 * @title Tick to Price conversions
 * @author Terence An and UniswapV3 (https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/TickMath.sol)
 * @notice Converts between square root of price and TickIndex for prices in the range of 2^-128 to 2^128.
 * Essentially Uniswap's GPL implementation of TickMath with very minor edits.
 **/
library TickIndexImpl {
    int24 constant INC_LIMIT = MAX_TICK - 1;

    error TickIndexOutOfBounds();

    function validate(TickIndex ti) internal pure {
        int24 num = TickIndex.unwrap(ti);
        if (num >= MAX_TICK || num < MIN_TICK) {
            revert TickIndexOutOfBounds();
        }
    }

    /// @notice Returns if the TickIndex is within the given range
    /// @dev This is inclusive on the lower end, and exclusive on the upper end like all Tick operations.
    function inRange(TickIndex self, TickIndex lower, TickIndex upper) internal pure returns (bool) {
        int24 num = TickIndex.unwrap(self);
        return (TickIndex.unwrap(lower) <= num) && (num < TickIndex.unwrap(upper));
    }

    /// Decrements the TickIndex by 1
    function dec(TickIndex ti) internal pure returns (TickIndex) {
        int24 num = TickIndex.unwrap(ti);
        require(num > MIN_TICK);
        unchecked { return TickIndex.wrap(num - 1); }
    }

    /// Increments the TickIndex by 1
    function inc(TickIndex ti) internal pure returns (TickIndex) {
        int24 num = TickIndex.unwrap(ti);
        require(num < INC_LIMIT);
        unchecked { return TickIndex.wrap(num + 1); }
    }

    /* Comparisons */

    /// Returns if self is less than other.
    function isLT(TickIndex self, TickIndex other) internal pure returns (bool) {
        return TickIndex.unwrap(self) < TickIndex.unwrap(other);
    }

    function isEq(TickIndex self, TickIndex other) internal pure returns (bool) {
        return TickIndex.unwrap(self) == TickIndex.unwrap(other);
    }


    /**
     * @notice Calculates sqrt(1.0001^tick) * 2^96
     * @dev Throws if |tick| > max tick
     * @param ti TickIndex wrapping a tick representing the price as 1.0001^tick.
     * @return sqrtP A Q64.96 representation of the sqrt of the price represented by the given tick.
     **/
    function toSqrtPrice(TickIndex ti) internal pure returns (Price sqrtP) {
        uint160 sqrtPriceX96;
        int256 tick = int256(TickIndex.unwrap(ti));
        uint256 absTick = tick < 0 ? uint256(-tick) : uint256(tick);
        require(absTick <= uint256(int256(MAX_TICK)), "TickIndexImpl:SqrtMax");

        // We first handle it as if it were a negative index to allow a later trick for the reciprocal.
        // Iteratively multiply by the precomputed Q128.128 of 1.0001 to various negative powers
        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        // Get the reciprocal if the index was positive.
        if (tick > 0) ratio = type(uint256).max / ratio;

        // This divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        unchecked { sqrtPriceX96 = uint160((ratio >> 32) + (uint32(ratio) == 0 ? 0 : 1)); }
        sqrtP = Price.wrap(sqrtPriceX96);
    }

    /**
     * @notice Calculates sqrt(1.0001^-tick) * 2^96
     * @dev Calls into toSqrtPrice. Not currently used.
     **/
    function toRecipSqrtPrice(TickIndex ti) internal pure returns (Price sqrtRecip) {
        TickIndex inv = TickIndex.wrap(-TickIndex.unwrap(ti));
        sqrtRecip = toSqrtPrice(inv);
        // This is surprisingly equally accurate afaik.
        // sqrtPriceX96 = uint160((1<< 192) / uint256(toSqrtPrice(ti)));
    }
}

library PriceImpl {
    function unwrap(Price self) internal pure returns (uint160) {
        return Price.unwrap(self);
    }

    /* Comparison functions */
    function eq(Price self, Price other) internal pure returns (bool) {
        return Price.unwrap(self) == Price.unwrap(other);
    }

    function gt(Price self, Price other) internal pure returns (bool) {
        return Price.unwrap(self) > Price.unwrap(other);
    }

    function gteq(Price self, Price other) internal pure returns (bool) {
        return Price.unwrap(self) >= Price.unwrap(other);
    }

    function lt(Price self, Price other) internal pure returns (bool) {
        return Price.unwrap(self) < Price.unwrap(other);
    }

    function lteq(Price self, Price other) internal pure returns (bool) {
        return Price.unwrap(self) <= Price.unwrap(other);
    }

    function max(Price self, Price other) internal pure returns (Price) {
        return unwrap(self) > unwrap(other) ? self : other;
    }
}

library SqrtPriceLib {
    error PriceOutOfBounds(uint160 sqrtPX96);

    function make(uint160 sqrtPX96) internal pure returns (Price sqrtP) {
        if (sqrtPX96 < MIN_SQRT_RATIO || MAX_SQRT_RATIO <= sqrtPX96) {
            revert PriceOutOfBounds(sqrtPX96);
        }
        return Price.wrap(sqrtPX96);
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtP A Q64.96 value representing the sqrt of the tick's price.
    /// @return ti The greatest tick whose price is less than or equal to the input price.
    function toTick(Price sqrtP) internal pure returns (TickIndex ti) {
        uint160 sqrtPriceX96 = Price.unwrap(sqrtP);
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        unchecked {
        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        int24 tick = (tickLow == tickHi ?
                      tickLow :
                      (Price.unwrap(TickIndexImpl.toSqrtPrice(TickIndex.wrap(tickHi))) <= sqrtPriceX96 ?
                       tickHi : tickLow));
        ti = TickIndex.wrap(tick);
        TickIndexImpl.validate(ti);
        }
    }

    /// Determine if a price is within the range we operate the AMM in.
    function isValid(Price self) internal pure returns (bool) {
        uint160 num = Price.unwrap(self);
        return  MIN_SQRT_RATIO <= num && num < MAX_SQRT_RATIO;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

import { IERC20Minimal } from "../ERC/interfaces/IERC20Minimal.sol";
import { ContractLib } from "./Contract.sol";

type Token is address;

library TokenImpl {
    error TokenBalanceInvalid();
    error TokenTransferFailure();

    /// Wrap an address into a Token and verify it's a contract.
    // @dev It's important to verify addr is a contract before we
    // transfer to it or else it will be a false success.
    function make(address _addr) internal view returns (Token) {
        ContractLib.assertContract(_addr);
        return Token.wrap(_addr);
    }

    /// Unwrap into an address
    function addr(Token self) internal pure returns (address) {
        return Token.unwrap(self);
    }

    /// Query the balance of this token for the caller.
    function balance(Token self) internal view returns (uint256) {
        (bool success, bytes memory data) =
            addr(self).staticcall(abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, address(this)));
        if (!(success && data.length >= 32)) {
            revert TokenBalanceInvalid();
        }
        return abi.decode(data, (uint256));
    }

    /// Transfer this token from caller to recipient.
    function transfer(Token self, address recipient, uint256 amount) internal {
        if (amount == 0) return; // Short circuit

        (bool success, bytes memory data) =
            addr(self).call(abi.encodeWithSelector(IERC20Minimal.transfer.selector, recipient, amount));
        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) {
            revert TokenTransferFailure();
        }
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { SwapMath } from "Swap/Math.sol";
import { Price, PriceImpl, SqrtPriceLib } from "Ticks/Tick.sol";
import { Q64X96 } from "Math/Ops.sol";
import { RangeLiq } from "Liq/Structs.sol";

// For LibDeployMath
import { FullMath } from "Math/FullMath.sol";
import { MathUtils } from "Math/Utils.sol";
import { SafeCast } from "Math/Cast.sol";

library LiqMath {
    using PriceImpl for Price;

    // @notice Calculate the token holdings for a Maker position.
    // @param roundUp Round up if we're opening the position or calculating borrows.
    // We round up user owed values and round down protocol owed values depending on the action.
    // This is to protect protocol solvency.
    function calcMakerHoldings(
        RangeLiq memory rLiq,
        Price currentSP,
        bool roundUp
    ) internal pure returns (uint256 x, uint256 y) {
        // On open, we round up the owed amount. On close we return the rounded down amount.
        return calcMakerHoldingsHelper(rLiq.lowSP, rLiq.highSP, currentSP, rLiq.liq, roundUp);
    }

    // @notice Underlying function to compute a Maker position's holdings.
    // This takes the raw values so its more accessible for Position to use.
    function calcMakerHoldingsHelper(
        Price lowSP,
        Price highSP,
        Price currentSP,
        uint128 liq,
        bool roundUp
    ) internal pure returns (uint256 x, uint256 y) {
        if (currentSP.lt(lowSP)) {
            x = SwapMath.calcXFromPriceDelta(lowSP, highSP, liq, roundUp);
        } else if (currentSP.lt(highSP)) {
            x = SwapMath.calcXFromPriceDelta(currentSP, highSP, liq, roundUp);
            y = SwapMath.calcYFromPriceDelta(lowSP, currentSP, liq, roundUp);
        } else {
            y = SwapMath.calcYFromPriceDelta(lowSP, highSP, liq, roundUp);
        }
    }

    /// Calculate the holdings for a wide maker position.
     /// @dev We calculate x holdings as L/sqrt(P) and y holdings as Lsqrt(p)
    function calcWideMakerHoldings(Price currentSP, uint128 liq, bool roundUp)
    internal pure returns (uint256 x, uint256 y) {
        uint160 sp = currentSP.unwrap();
        x = Q64X96.div(liq, sp, roundUp);
        y = Q64X96.mul(sp, liq, roundUp);
    }

    // @notice Determine the holding and borrowed balance of a Taker Call position.
    // @param isOpen If we're opening the position or closing. Also if we round holdings up or down.
    // @returns heldX The amount of X we need to open the taker call position. Any amount
    // not fulfilled by the borrows needs to be supplied by the user. Taker call positions
    // just hold X under the hood.
    // @returns makerX The amount of X belonging to the complementary Maker position. This is
    // what is borrowed on open, and what needs to be repaid on close. This amount changes over time.
    // @returns makerY The amount of Y belonging to the complementary Maker position. This is
    // what is borrowed on open, and what needs to be repaid on close. This amount changes over time.
    function calcTakerCallAmounts(
        RangeLiq memory rLiq,
        Price currentSP,
        bool isOpen
    ) internal pure returns (uint256 heldX, uint256 makerX, uint256 makerY) {
        Price lowSP = rLiq.lowSP;
        Price highSP = rLiq.highSP;
        uint128 liq = rLiq.liq;

        // On open we round up the borrows and holdings.
        // On close we round up the borrows and round down the holdings.

        heldX = SwapMath.calcXFromPriceDelta(lowSP, highSP, liq, isOpen);
        (makerX, makerY) = calcMakerHoldingsHelper(lowSP, highSP, currentSP, liq, true);
    }

    // @notice Determine the holding and borrowed balance of a Taker Put position.
    // @param isOpen If we're opening the position or closing. Also if we round holdings up or down.
    // @returns heldX The amount of X we need to open the taker put position. Any amount
    // not fulfilled by the borrows needs to be supplied by the user. Taker put positions
    // just hold Y under the hood.
    // @returns makerX The amount of X belonging to the complementary Maker position. This is
    // what is borrowed on open, and what needs to be repaid on close. This amount changes over time.
    // @returns makerY The amount of Y belonging to the complementary Maker position. This is
    // what is borrowed on open, and what needs to be repaid on close. This amount changes over time.
    function calcTakerPutAmounts(
        RangeLiq memory rLiq,
        Price currentSP,
        bool isOpen
    ) internal pure returns (uint256 heldY, uint256 makerX, uint256 makerY) {
        Price lowSP = rLiq.lowSP;
        Price highSP = rLiq.highSP;
        uint128 liq = rLiq.liq;

        // On open we round up the borrows and holdings.
        // On close we round up the borrows and round down the holdings.

        heldY = SwapMath.calcYFromPriceDelta(lowSP, highSP, liq, isOpen);
        (makerX, makerY) = calcMakerHoldingsHelper(lowSP, highSP, currentSP, liq, true);
    }

    // @notice Use this when we decrease the Taker Borrow Pool's balance. This DOES NOT
    // indicate how much Taker's repay or receive when borrowing. That is still determined
    // by the calcTaker functions. It just so happens on open, the borrowed values between
    // this function and the calcTaker functions are the same. On close, the borrowed amounts
    // from Makers and the borrow balancein the TBP are different.
    // @param originalSP The square root of the price the Taker position originally opened at.
    // @dev Currently unused, because calculating Taker amounts is sufficient.
    function calcTBPBorrow(
        Price lowSP,
        Price highSP,
        Price originalSP,
        uint128 liq
    ) internal pure returns (uint256 TBPX, uint256 TBPY) {
        (TBPX, TBPY) = calcMakerHoldingsHelper(lowSP, highSP, originalSP, liq, true);
    }
}

/// Helper library for liquidity related math that is specific to the deployment process.
library LiqDeployMath {
    // Deployers can seed the deployed pool with token amounts to start the pool.
    // See 2sAMMDiamond constructor for seed minimums.
    // We use the seeded amounts to determine the starting price and liquidity.
    // @dev The starting price and liquidity need to be computed together so we can
    // validate their implied quantities are not larger than the actual quantities.
    // This means there is the potential for lowering liquidity to satisfy
    // numerical imprecision in the price's square root.
    function calcWideSqrtPriceAndMLiq(uint256 amountX, uint256 amountY) internal pure returns (Price sqrtP, uint128 mLiq) {
        // First convert amounts into square roots because computing the ratio directly as X192 (2 * X96)
        // can easily overflow.
        uint256 sqrtX = MathUtils.sqrt(amountX); // Rounds down
        uint256 sqrtY = MathUtils.sqrt(amountY); // Rounds down

        uint256 sqrtPriceX96 = FullMath.mulDiv(1 << 96, sqrtX, sqrtY); // Rounds down the price
        sqrtP = SqrtPriceLib.make(SafeCast.toUint160(sqrtPriceX96));

        // Now there is some imprecision with the price. But this isn't an amount users get back,
        // this is just to give a pool the bare minimum in liquidity.

        // Due to this imprecision we calculate the mLiq in two ways and take the one that is smaller.
        // The chosen mLiq implies a certain amount of each token that can be traded against, and we
        // need to make sure that implied amount is less than the actual amount.
        uint128 yL = SafeCast.toUint128((amountY << 96) / sqrtPriceX96);
        uint128 xL = SafeCast.toUint128((amountX * sqrtPriceX96) >> 96);

        mLiq = xL < yL ? xL : yL;
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { TableIndex } from "Ticks/Table.sol";
import { Accum, AccumImpl } from "Util/Accum.sol";
import { RangeLiq } from "Liq/Structs.sol";
import { FeeRateSnapshot } from "Fee/Snap.sol";

// This is the underlying library for the range tree mechanics.
// import { LiqTree, RangeTreeImpl } from "Tree/Tree.sol";

// Replace with real liq tree when that is ready.
struct LiqTree {
    uint128 wideMLiq;
}

/// Utility functions for LiqFacet when opening and closing positions
library LiqTreeImpl {
    // using RangeTreeImpl for LiqTree;

    /// Adds Wide Maker Liquidity and returns a snapshot of the fees.
    function addWideMLiq(LiqTree storage self, uint128 liq) internal returns (FeeRateSnapshot memory snap) {
        // self.addWideMLiq(liq);
    }

    /// Adds Maker Liquidity and returns a snapshot of the fees.
    function addMLiq(LiqTree storage self, RangeLiq memory rLiq) internal returns (FeeRateSnapshot memory snap) {
        // self.addMLiq(TableIndex.unwrap(rLiq.low), TableIndex.unwrap(rLiq.high));
    }

    /// Adds Taker Liquidity, validates the liquidity limits, and borrows the given amounts
    function addTLiq(LiqTree storage self, RangeLiq memory rLiq, uint256 borrowedX, uint256 borrowedY) internal {
        // self.addTLiqAndValidate(TableIndex.unwrap(rLiq.low), TableIndex.unwrap(rLiq.high));
    }

    /// Removes Wide Maker Liquidity, validates the liquidity limits, and returns a snapshot of the fees.
    function subWideMLiq(LiqTree storage self, uint128 liq) internal returns (FeeRateSnapshot memory snap) {
        // self.subWideMLiq(liq);
    }

    /// Removes Maker Liquidity, validates the liquidity limits, and returns a snapshot of the fees.
    function subMLiq(LiqTree storage self, RangeLiq memory rLiq) internal returns (FeeRateSnapshot memory snap) {
        // self.subMLiqAndValidate(TableIndex.unwrap(rLiq.low), TableIndex.unwrap(rLiq.high));
    }

    /// Removes Taker liquidity and repays the borrowed amounts.
    function subTLiq(LiqTree storage self, RangeLiq memory rLiq, uint256 borrowedX, uint256 borrowedY) internal {
        // self.subTLiq(TableIndex.unwrap(rLiq.low), TableIndex.unwrap(rLiq.high));
    }
}

/// Utility functions for querying fee accumulators for given ranges.
/// Used for valuing makers since we're not modifying the maker position
/// and can't get the earn rate any other way.
library EarnTreeImpl {
    // using RangeTreeImpl for LiqTree;

    function earnSnap(LiqTree storage self, TableIndex low, TableIndex high)
    internal view returns (FeeRateSnapshot memory snap) {
        // (uint256 xSnap, uint256 ySnap) = self.queryCumEarnRates(low, high);
        // snap.X = AccumImpl.from(xSnap);
        // snap.Y = AccumImpl.from(ySnap);
    }

    function wideEarnSnap(LiqTree storage self) internal view returns (FeeRateSnapshot memory snap) {
        // (uint256 xSnap, uint256 ySnap) = self.queryCumEarnRates(low, high);
        // snap.X = AccumImpl.from(xSnap);
        // snap.Y = AccumImpl.from(ySnap);
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

/// Library for safe casting
library SafeCast {
    /// Casting too large an int to a signed int with the given maximum value.
    error UnsafeICast(uint256 val, int256 max);
    /// Casting too large an int to an unsigned int with the given maximum value.
    error UnsafeUCast(uint256 val, uint256 max);
    /// Casting a negative number to an unsigned int.
    error NegativeUCast(int256 val);

    function toUint256(int256 i) internal pure returns (uint256) {
        if (i < 0) {
            revert NegativeUCast(i);
        }
        return uint256(i);
    }

    function toInt256(uint256 u) internal pure returns (int256) {
        if (u > uint256(type(int256).max)) {
            revert UnsafeICast(u, type(int256).max);
        }
        return int256(u);
    }

    function toInt128(uint256 u) internal pure returns (int128) {
        if (u > uint256(uint128(type(int128).max))) {
            revert UnsafeICast(u, type(int128).max);
        }
        return int128(uint128(u));
    }

    function toUint128(uint256 u) internal pure returns (uint128) {
        if (u > type(uint128).max) {
            revert UnsafeUCast(u, type(uint128).max);
        }
        return uint128(u);
    }

    function toUint128(int256 i) internal pure returns (uint128) {
        return toUint128(toUint256(i));
    }

    function toUint160(uint256 u) internal pure returns (uint160) {
        if (u > type(uint160).max) {
            revert UnsafeUCast(u, type(uint160).max);
        }
        return uint160(u);
    }

    function toInt24(uint24 u) internal pure returns (int24) {
        if (u > uint24(type(int24).max)) {
            revert UnsafeICast(u, type(int24).max);
        }
        return int24(u);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { AdminLib } from "../../Util/Admin.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

contract DiamondCutFacet is IDiamondCut {
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        AdminLib.validateLevel(3);
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// The functions in DiamondLoupeFacet MUST be added to a diamond.
// The EIP-2535 Diamond standard requires these functions.

import { LibDiamond } from  "../libraries/LibDiamond.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IERC165 } from "../../ERC/interfaces/IERC165.sol";

contract DiamondLoupeFacet is IDiamondLoupe, IERC165 {
    // Diamond Loupe Functions
    ////////////////////////////////////////////////////////////////////
    /// These functions are expected to be called frequently by tools.
    //
    // struct Facet {
    //     address facetAddress;
    //     bytes4[] functionSelectors;
    // }
    /// @notice Gets all facets and their selectors.
    /// @return facets_ Facet
    function facets() external override view returns (Facet[] memory facets_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        // create an array set to the maximum size possible
        facets_ = new Facet[](selectorCount);
        // create an array for counting the number of selectors for each facet
        uint16[] memory numFacetSelectors = new uint16[](selectorCount);
        // total number of facets
        uint256 numFacets;
        // loop through function selectors
        for (uint256 selectorIndex; selectorIndex < selectorCount; selectorIndex++) {
            bytes4 selector = ds.selectors[selectorIndex];
            address facetAddress_ = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            bool continueLoop = false;
            // find the functionSelectors array for selector and add selector to it
            for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                if (facets_[facetIndex].facetAddress == facetAddress_) {
                    facets_[facetIndex].functionSelectors[numFacetSelectors[facetIndex]] = selector;
                    numFacetSelectors[facetIndex]++;
                    continueLoop = true;
                    break;
                }
            }
            // if functionSelectors array exists for selector then continue loop
            if (continueLoop) {
                continueLoop = false;
                continue;
            }
            // create a new functionSelectors array for selector
            facets_[numFacets].facetAddress = facetAddress_;
            facets_[numFacets].functionSelectors = new bytes4[](selectorCount);
            facets_[numFacets].functionSelectors[0] = selector;
            numFacetSelectors[numFacets] = 1;
            numFacets++;
        }
        for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
            uint256 numSelectors = numFacetSelectors[facetIndex];
            bytes4[] memory selectors = facets_[facetIndex].functionSelectors;
            // setting the number of selectors
            assembly {
                mstore(selectors, numSelectors)
            }
        }
        // setting the number of facets
        assembly {
            mstore(facets_, numFacets)
        }
    }

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return _facetFunctionSelectors The selectors associated with a facet address.
    function facetFunctionSelectors(address _facet) external override view returns (bytes4[] memory _facetFunctionSelectors) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        uint256 numSelectors;
        _facetFunctionSelectors = new bytes4[](selectorCount);
        // loop through function selectors
        for (uint256 selectorIndex; selectorIndex < selectorCount; selectorIndex++) {
            bytes4 selector = ds.selectors[selectorIndex];
            address facetAddress_ = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            if (_facet == facetAddress_) {
                _facetFunctionSelectors[numSelectors] = selector;
                numSelectors++;
            }
        }
        // Set the number of selectors in the array
        assembly {
            mstore(_facetFunctionSelectors, numSelectors)
        }
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external override view returns (address[] memory facetAddresses_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        // create an array set to the maximum size possible
        facetAddresses_ = new address[](selectorCount);
        uint256 numFacets;
        // loop through function selectors
        for (uint256 selectorIndex; selectorIndex < selectorCount; selectorIndex++) {
            bytes4 selector = ds.selectors[selectorIndex];
            address facetAddress_ = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            bool continueLoop = false;
            // see if we have collected the address already and break out of loop if we have
            for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                if (facetAddress_ == facetAddresses_[facetIndex]) {
                    continueLoop = true;
                    break;
                }
            }
            // continue loop if we already have the address
            if (continueLoop) {
                continueLoop = false;
                continue;
            }
            // include address
            facetAddresses_[numFacets] = facetAddress_;
            numFacets++;
        }
        // Set the number of facet addresses in the array
        assembly {
            mstore(facetAddresses_, numFacets)
        }
    }

    /// @notice Gets the facet address that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external override view returns (address facetAddress_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddress_ = ds.facetAddressAndSelectorPosition[_functionSelector].facetAddress;
    }

    // This implements ERC-165.
    function supportsInterface(bytes4 _interfaceId) external override view returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.supportedInterfaces[_interfaceId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { MIN_TICK, MAX_TICK, TickIndex } from "Ticks/Tick.sol";
import { TableIndex, TableIndexImpl, TableIndexJoin } from "Ticks/Table.sol";
import { Bitmap, BitmapImpl } from "Ticks/Bitmap.sol";
import { TickData } from "Ticks/Data.sol";

struct TickTable {
    /// Mapping from ticks to TickData
    /// @dev We use mapping instead of a fixed array here so that we can extend the TickData type.
    mapping(TableIndex => TickData) table;

    /// Map from table indices to a bitmap of which ticks are initialized.
    /// @dev TODO: we can consider switching this to a fixed array to save gas.
    mapping(int16 => Bitmap) bitmaps;

    /// @notice The tick spacing used. Aka the divisor for ticks to table indices.
    /// @dev Would like to make this immutable but with a struct it's all or nothing.
    /// A int despite always being positive to reduce casts in the math.
    int24 spacing;
}


/**
 * @title TickTableImpl
 * @author Terence An
 * @notice TickTable type implementation. Manages Tick interactions.
 * @custom:security High
 **/
library TickTableImpl {
    using BitmapImpl for Bitmap;
    using TableIndexImpl for TableIndex;

    error UnspacedTickIndex(int24 spacing, int24 tick);

    /*
      The MAX_TOP and MIN_TOP are gross overestimates of the bounds. They're only present in the event
      that something has catastrophically gone wrong. Instead bounds checking should happen at the
      TickIndex level.
    */

    /// Highest the top 16 bits the TableIndex can be. Overestimates by a factor of "spacing". Inclusive.
    /// Note this is inclusive while MAX_TICK is not.
    int16 constant MAX_TOP = int16(MAX_TICK >> 8);

    /// Lowest the top 16 bits the TableIndex can be. Overestimates by a factor of "spacing". Inclusive.
    int16 constant MIN_TOP = int16(MIN_TICK >> 8);

    /// The number of bitmaps to search for the subsequent initialized tick. Currently set to 4 which is roughly
    /// an 11% slippage in price which should be more than reasonable.
    int16 constant SUBSEQUENT_TOPS = 4;


    /* TableIndex conversion functions */

    /// Convert TickIndex to the index we use to fetch TickData. The bitmap's "table index".
    function getTableIndex(TickTable storage self, TickIndex ti) internal view returns(TableIndex) {
        int24 tick = TickIndex.unwrap(ti);
        if (tick < 0) {
            // Solidity rounds negative numbers towards 0.
            unchecked { return TableIndex.wrap(((tick + 1) / self.spacing) - 1); }
        } else {
            return TableIndex.wrap(tick / self.spacing);
        }
    }

    function getTickIndex(TickTable storage self, TableIndex bi) internal view returns (TickIndex) {
        unchecked { return TickIndex.wrap(TableIndex.unwrap(bi) * self.spacing); }
    }

    function validateTickIndexSpacing(TickTable storage self, TickIndex ti) internal view {
        if (TickIndex.unwrap(ti) % self.spacing != 0)
            revert UnspacedTickIndex(self.spacing, TickIndex.unwrap(ti));
    }

    /* Bitmaps-only table iteration functions */

    /// @notice Get the table index of the next initialized tick.
    /// @dev It is cheaper to iterate in TableIndex and avoids rounding ambiguity.
    function getNextTableIndex(TickTable storage self, TableIndex bi) internal view returns (bool, TableIndex) {
        return getAtOrNextTableIndex(self, bi.inc());
    }

    /// @notice Workhorse for getting next tick
    /// @dev At most search a fixed number of subsequent bitmaps before giving up.
    /// @return exists Indicator if a next initialized tick exists.
    /// @return next The next table index greater than or equal to the given one if found. If not, the max index searched.
    function getAtOrNextTableIndex(TickTable storage self, TableIndex bi) internal view returns(bool exists, TableIndex next) {
        (int16 top, uint8 bot) = bi.split();
        // Search initial bitmap
        (bool found, uint8 nextBot) = self.bitmaps[top].getAtOrNext(bot);
        if (found) {
            return (true, TableIndexJoin(top, nextBot));
        }

        // Search all subsequent bitmaps
        int16 maxTop = top + SUBSEQUENT_TOPS;
        unchecked {
        for (int16 i = top + 1; i <= maxTop && i <= MAX_TOP; ++i) {
            (found, nextBot) = self.bitmaps[i].getAtOrNext(0);
            if (found) {
                return (true, TableIndexJoin(i, nextBot));
            }
        }

        // No next tick found
        return (false, TableIndexJoin(maxTop, type(uint8).max));
        }
    }

    /// @notice Get the table index of the previous initialized tick.
    /// @dev It is cheaper to iterate in TableIndex and avoids rounding ambiguity.
    function getPrevTableIndex(TickTable storage self, TableIndex bi) internal view returns(bool, TableIndex) {
        return getAtOrPrevTableIndex(self, bi.dec());
    }

    /// @notice Workhorse for getting prev tick
    /// @dev At most search a fixed number of subsequent bitmaps before giving up.
    /// @return exists Indicator if a prev initialized tick exists.
    /// @return next The prev table index less than or equal to the given one if found. If not, the min index searched.
    function getAtOrPrevTableIndex(TickTable storage self, TableIndex bi) internal view returns(bool exists, TableIndex next) {
        (int16 top, uint8 bot) = bi.split();
        // Search initial bitmap
        (bool found, uint8 prevBot) = self.bitmaps[top].getAtOrPrev(bot);
        if (found) {
            return (true, TableIndexJoin(top, prevBot));
        }

        // Search 4 subsequent bitmaps
        int16 minTop = top - SUBSEQUENT_TOPS;
        unchecked {
        for (int16 i = top - 1; i >= minTop && i >= MIN_TOP; --i) {
            (found, prevBot) = self.bitmaps[i].getAtOrPrev(type(uint8).max);
            if (found) {
                return (true, TableIndexJoin(i, prevBot));
            }
        }

        // No next tick exists
        return (false, TableIndexJoin(minTop, 0));
        }
    }

    /* Table interacting functions */

    /// First convert your TickIndex to a TableIndex to then fetch TickData here.
    function getData(TickTable storage self, TableIndex bi) internal view returns(TickData storage) {
        return self.table[bi];
    }

    /* Bitmap interaction functions */

    /// Sets the bit in the TickTable bitmap to indicate the index has data.
    /// This allows the get{Next,Prev} TableIndex iteration functions to find this TableIndex.
    function setBit(TickTable storage self, TableIndex bi) internal {
        (int16 top, uint8 bot) = bi.split();
        self.bitmaps[top].trySet(bot);
    }

    /// Clears the bit in the TickTable bitmap to indicate the index has no data to inspect.
    /// This removes this index from the result of the get{Next,Prev} TableIndex iteration functions to.
    function clearBit(TickTable storage self, TableIndex bi) internal {
        (int16 top, uint8 bot) = bi.split();
        self.bitmaps[top].clear(bot);
    }

    /// Indicates if a bit in the TickTable bitmap is set and the Tick is initialized or not.
    function isSet(TickTable storage self, TableIndex bi) internal view returns (bool) {
        (int16 top, uint8 bot) = bi.split();
        return self.bitmaps[top].isSet(bot);
    }

    /// TODO: REVISIT THIS. MAYBE WE CAN DELETE OR RELEGATE TO TESTING.
    /// @notice Save the given TickData at the given table index.
    /// @dev CAUTION. Always only add one reference to the data at time before saving. Saving multiple new
    /// references will cause the bitmaps entry to remain blank.
    /// This used to work by saving memory to storage, that way is safer but in theory more gas costly.
    /// We should revisit this.
    /// @param data We don't need this param but we always have the data pointer when calling this function
    /// so just provide the argument to save us a separate lookup.
    function ensureBitmap(TickTable storage self, TableIndex bi, TickData storage data) internal {
        if (data.refCount == 0) {
            // Deleting this entry.
            require(data.mLiqDelta == 0);
            require(data.tLiqDelta == 0);
            (int16 top, uint8 bot) = bi.split();
            self.bitmaps[top].clear(bot);
        } else if (data.refCount == 1) {
            // Doesn't matter if the ref count went up or down to 1.
            // As a gas compromise we don't check storage, just set the bitmap anyways.
            // BE VERY CAREFUL HERE. WE ASSUME SAVES HAPPEN INCREMENTALLY.
            // I.e. if you add two references and then save, the bitmap will not be set.
            (int16 top, uint8 bot) = bi.split();
            self.bitmaps[top].trySet(bot);
        }
    }

    /// Utility function for testing convenience.
    /// @dev Uses an in-memory TickData since it's testing.
    function saveData(TickTable storage self, TableIndex bi, TickData memory memData) internal {
        self.table[bi] = memData;
        TickData storage data = self.table[bi];
        ensureBitmap(self, bi, data);
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

type TableIndex is int24;

/**
 * @title TableIndexImpl
 * @notice TickTable type implementation. Make clear how we access tables.
 * @dev TableIndex is just the Tick Index divided by spacing and rounded down.
 **/
library TableIndexImpl {
    // Split into the two ints used to access the bitmap.
    function split(TableIndex bi) internal pure returns(int16 top, uint8 bot) {
        int24 i = TableIndex.unwrap(bi);
        top = int16(i >> 8);
        bot = uint8(int8(i));
    }

    /// @notice Increment by 1
    /// @dev unchecked is a little dangerous here since we may go over the theoretical max TableIndex.
    /// We don't actually store the Table Index bounds anywhere. They are just the tick index bounds divided
    /// by spacing. We make sure to check tick index bounds to avoid this issue. Table indices going out of bounds
    /// doesn't fundamentally break anything.
    function inc(TableIndex bi) internal pure returns(TableIndex) {
        unchecked { return TableIndex.wrap(TableIndex.unwrap(bi) + 1); }
    }

    /// @notice Decrement by 1
    /// @dev unchecked is a little dangerous here since we may go below the theoretical min TableIndex.
    /// We don't actually store the Table Index bounds anywhere. They are just the tick index bounds divided
    /// by spacing. We make sure to check tick index bounds to avoid this issue. Table indices going out of bounds
    /// doesn't fundamentally break anything.
    function dec(TableIndex bi) internal pure returns(TableIndex) {
        unchecked { return TableIndex.wrap(TableIndex.unwrap(bi) - 1); }
    }

    function isLT(TableIndex self, TableIndex other) internal pure returns(bool) {
        return TableIndex.unwrap(self) < TableIndex.unwrap(other);
    }

    function isEq(TableIndex self, TableIndex other) internal pure returns(bool) {
        return TableIndex.unwrap(self) == TableIndex.unwrap(other);
    }

    function isLTE(TableIndex self, TableIndex other) internal pure returns (bool) {
        return TableIndex.unwrap(self) <= TableIndex.unwrap(other);
    }
}

/// The Inverse of TableIndexImpl.split. Free function since it can't be in the library.
function TableIndexJoin(int16 top, uint8 bot) pure returns(TableIndex) {
    unchecked { return TableIndex.wrap(int24((uint24(uint16(top)) << 8) + bot)); }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { TableIndex, TableIndexImpl } from "Ticks/Table.sol";
import { FeeRateAccumulator, FeeRateAccumulatorImpl } from "Fee/Fees.sol";
import { SwapStorage } from "Swap/Storage.sol";
import { U128Ops } from "Math/Ops.sol";


/// @notice The information stored at each tick
/// @dev Each TickData belongs to the lower price of its range.
struct TickData {
    /// Change in Maker liquidity when crossing into this tick from the left.
    int128 mLiqDelta;
    /// Change in Taker liquidity when crossing into this tick from the left.
    int128 tLiqDelta;

    /// The total number of maker and taker positions that reference this tick.
    /// Used to clear ticks that we no longer have to iterate through
    uint128 refCount;

    /// @notice The cumulative fee rate owed to Makers and by Takers for the non-active side.
    /// @dev IMPORTANT! Notice that this value does not need initialization. This is important to understand.
    /// First you should understand the outside/inside fee mechanics and then read below.
    /// Given any tick, we can denote two values, a and b. a + b = F where F is the total number of fees collected
    /// so far. Regardless of the initial values of a and b, as long a + b = F is true for all ticks, and b increases
    /// when F increases while the price is below the tick and a increases with F while the price is above the tick
    /// then the values we use to compute regional fees, a2-a1, b1-b2, F-a1-b2, can be used for checkpointing fees.
    FeeRateAccumulator outsideFeeRateAccumulator;

    //TODO: Add token rewards.
    //TODO: Determine if we need the extra Uniswap Tick.Info members.
}


/**
 * @notice Methods for interacting with TickData. Correct use is up to the user.
 **/
library TickDataImpl {
    using FeeRateAccumulatorImpl for FeeRateAccumulator;
    using TableIndexImpl for TableIndex;

    /***********************
     * Liquidity Utilities *
     ***********************/

    /// @dev Note that even if we add to an uninitialized tick, we assume the fees are all accumulated inside
    /// so we avoid initializing the outsideFee variables. We do however return information for the table to
    /// @return isNew Indicates to the caller this is a tick with new data.
    /// This should be reported to the TickTable bookkeeping.
    function addMakerLiq(TickData storage data, int128 liq) internal returns (bool isNew) {
        data.mLiqDelta += liq;
        uint128 refs = data.refCount;
        isNew = refs == 0;
        data.refCount = refs + 1;
    }

    /// @return isNew Indicates to the caller this is a tick with new data.
    /// This should be reported to the TickTable bookkeeping.
    function addTakerLiq(TickData storage data, int128 liq) internal returns (bool isNew) {
        data.tLiqDelta += liq;
        uint128 refs = data.refCount;
        isNew = refs == 0;
        data.refCount = refs + 1;
    }

    /// @return isEmpty Indicates to the caller this tick now has no data and should be cleared
    /// in the TickTable bookkeeping.
    function removeMakerLiq(TickData storage data, int128 liq) internal returns (bool isEmpty) {
        // Will revert on over/underflow;
        data.mLiqDelta -= liq;
        uint128 refs = data.refCount;
        isEmpty = refs == 1;
        data.refCount = refs - 1;
    }

    /// @return isEmpty Indicates to the caller this tick now has no data and should be cleared
    /// in the TickTable bookkeeping.
    function removeTakerLiq(TickData storage data, int128 liq) internal returns (bool isEmpty) {
        data.tLiqDelta -= liq;
        uint128 refs = data.refCount;
        isEmpty = refs == 1;
        data.refCount = refs - 1;
    }

    /// Increment the refCount of this tick. This is only used in the scenario where a position
    /// using this tick is split into two. Liquidity numbers don't have to change.
    /// @dev This TickData cannot possibly be new.
    function incRefCount(TickData storage data) internal {
        data.refCount += 1;
    }

    /******************
     * Swap Utilities *
     ******************/

    /// Update state and tick when crossing into this tick.
    function crossInto(
        TickData storage data,
        SwapStorage memory swapStore,
        FeeRateAccumulator memory globalAccumulator
    ) internal {
        data.outsideFeeRateAccumulator.subFrom(globalAccumulator);
        swapStore.mLiq = U128Ops.add(swapStore.mLiq, data.mLiqDelta);
        swapStore.tLiq = U128Ops.add(swapStore.tLiq, data.tLiqDelta);
    }

    /// Update state and tick when crossing out of this tick.
    function crossOutOf(
        TickData storage data,
        SwapStorage memory swapStore,
        FeeRateAccumulator memory globalAccumulator
    ) internal {
        data.outsideFeeRateAccumulator.subFrom(globalAccumulator);
        swapStore.mLiq = U128Ops.sub(swapStore.mLiq, data.mLiqDelta);
        swapStore.tLiq = U128Ops.sub(swapStore.tLiq, data.tLiqDelta);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copied from the UniswapV3 repo. Files were under GPL-2.0-or-later license.
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#mint
/// @notice Any contract that calls IUniswapV3PoolActions#mint must implement this interface
interface IUniswapV3MintCallback {
    /// @notice Called to `msg.sender` after minting liquidity to a position from IUniswapV3Pool#mint.
    /// @dev In the implementation you must pay the pool tokens owed for the minted liquidity.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#mint call
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;
}

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

/// @title Callback for IUniswapV3PoolActions#flash
/// @notice Any contract that calls IUniswapV3PoolActions#flash must implement this interface
interface IUniswapV3FlashCallback {
    /// @notice Called to `msg.sender` after transferring to the recipient from IUniswapV3Pool#flash.
    /// @dev In the implementation you must repay the pool the tokens sent by flash plus the computed fee amounts.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param fee0 The fee amount in token0 due to the pool by the end of the flash
    /// @param fee1 The fee amount in token1 due to the pool by the end of the flash
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#flash call
    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

interface I2sAMMSwapper {

    /// @param xForY If true, we are selling X, if false the caller is buying X.
    /// @param rawAmount A positive value means the number of tokens given, negative is tokens expected to receive.
    /// So for example, an xForY with a negative value means the amount refers to the Y received.
    /// @param recipient The recipient of the tokens after the swap
    /// @param xForY Are we swapping tokenX for tokenY?
    /// @param sqrtPriceLimitX96 Price where the order will stop filling
    /// @return amountX If xForY, this is the amount the caller has paid in x. Else it's the amount they recieved
    /// from the swap
    /// @return amountY If xForY, this is the amount of y the caller has recieved from the swap. Else it's the amount
    /// paid in y.
    function swap(
        address recipient,
        bool xForY, // sell
        int256 rawAmount,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (uint256 amountX, uint256 amountY);
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { Price, PriceImpl } from "Ticks/Tick.sol";
import { FullMath } from "Math/FullMath.sol";

/// Stores the within-block bid and ask.
/// @dev 2 slots
struct BidAsk {
    // @TODO (terence): Change this appropriately for L2 blocks.
    // The block number this bidask applies to.
    uint64 blockNum;

    Price bidSP;
    Price askSP;
}


/// BidAsk is used to prevent sandwich attacks and repetitive burn attacks.
/// Previous swaps within the same block set the bid and ask.
/// The Bid is the lowest price swapped to in this block and the ask is the highest
/// price swapped to within the current block.
library BidAskImpl {
    using PriceImpl for Price;

    /// Fetch the effective bid price.
    /// @param sqrtP The current swap price. Used at the start of a new block.
    function getBid(BidAsk storage self, Price sqrtP) internal returns (Price bid) {
        uint64 newBlock = uint64(block.number);
        // If this is the first swap in this block, the bid and ask don't apply yet.
        if (newBlock != self.blockNum) {
            self.blockNum = newBlock;
            self.bidSP = sqrtP;
            self.askSP = sqrtP;
            return sqrtP;
        } else {
            return self.bidSP;
        }
    }

    /// Fetch the effective Ask price.
    /// @param sqrtP The current swap price. Used at the start of a new block.
    function getAsk(BidAsk storage self, Price sqrtP) internal returns (Price ask) {
        uint64 newBlock = uint64(block.number);
        // If this is the first swap in this block, the bid and ask don't apply yet.
        if (newBlock != self.blockNum) {
            self.blockNum = newBlock;
            self.bidSP = sqrtP;
            self.askSP = sqrtP;
            return sqrtP;
        } else {
            return self.askSP;
        }
    }

    /// After a sell swap, we set the bid to the new price if its lower.
    function storePostSwapBid(
        BidAsk storage self,
        Price postSP
    ) internal {
        if (postSP.lt(self.bidSP)) {
            self.bidSP = postSP;
        }
    }

    /// After a sell swap, we set the bid to the new price if its greater.
    function storePostSwapAsk(
        BidAsk storage self,
        Price postSP
    ) internal {
        if (postSP.gt(self.askSP)) {
            self.askSP = postSP;
        }
    }
}

/// Helpers for working with BidAsk results.
library BidAskLib {
    /// Calculate the y we should return to a user as if they
    /// sold their entire x at the bid.
    function sellAtBid(
        Price bidSP, uint256 x
    ) internal pure returns (uint256 y) {
        uint160 bidX96 = Price.unwrap(bidSP);
        (uint256 bot, uint256 top) = FullMath.mul512(bidX96, bidX96); // 320 used bits, X192

        // At most 64 bits are used in top. Let's shift in those 64 bits and drop to X128.
        uint256 pX128 = (bot >> 64) + (top << 192);

        // Since we really only allow swapping uint128 of x, we know
        // this is guaranteed to fit into the result.
        (bot, top) = FullMath.mul512(x, pX128);
        // Drop the X128 and shift in top's 128 bits.
        y = (bot >> 128) + (top << 128);
    }

    /// Calculate the x we should return to a user as if they
    /// bought their entire y at the ask.
    function buyAtAsk(
        Price askSP, uint256 y
    ) internal pure returns (uint256 x) {
        uint160 askX96 = Price.unwrap(askSP);
        // The second divide is okay because we know y is really at most 128 bits so
        // the muldiv at most gives a 224 result.
        x = FullMath.mulDiv(y, 1 << 192, askX96) / askX96;
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { TableIndex } from "Ticks/Table.sol";

/// Used when calculating swaps to save stack pointers
struct IterCache {
    // The table index the sqrtP is currently in
    TableIndex tabIdx; // 24 bits
    // Use explicit spacing to give each used element its own slot.
    uint232 _spacing0;

    // The liquidity of the current tick.
    uint128 liq;
    uint128 _spacing1;

    // If the iteration has completed and we can stop.
    bool isDone;
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

// Types
import { Price, PriceImpl, MIN_PRICE, MAX_PRICE } from "Ticks/Tick.sol";
// Utils
import { X96 } from "Math/Ops.sol";
import { MathUtils } from "Math/Utils.sol";
import { SafeCast } from "Math/Cast.sol";
import { FullMath } from "Math/FullMath.sol";
import { UnsafeMath } from "Math/UnsafeMath.sol";


library SwapMath {
    using PriceImpl for Price;
    using SafeCast for uint256;

    error InsufficientX(uint256 requestedX);
    error InsufficientY(uint256 requestedY);

    /// @notice Calculate the new price resulting from additional X
    /// @dev We round up to minimize price impact of X.
    /// We want to compute L\sqrt(P) / (L + x\sqrt(P))
    /// If liq is 0, slippage is infinite, and we snap to the minimum valid price.
    /// @param x The amount of x being exchanged. If 0 this reverts.
    function calcNewPriceFromAddX(
        uint128 liq,
        Price oldSqrtPrice,
        uint256 x
    ) public pure returns (Price newSqrtPrice) {
        if (liq == 0) {
            return MIN_PRICE;
        }

        // We're adding x, pushing down the price, we need to round up the price.
        uint256 liqX96 = uint256(liq) << 96;
        uint160 rp = Price.unwrap(oldSqrtPrice);
        uint256 xrp;
        unchecked {
            xrp = x * rp;
        }
        if ((xrp / x) == rp) { // If we don't overflow
            uint256 denom;
            unchecked {
                denom = xrp + liqX96;
            }
            if (denom > liqX96) { // Check the denom hasn't overflowed
                // Will always fit since denom >= liqX96
                return Price.wrap(uint160(FullMath.mulDivRoundingUp(liqX96, rp, denom)));
            }
        }
        // This will also always fit since liqx96/rp is 64 bits.
        return Price.wrap(uint160(UnsafeMath.divRoundingUp(liqX96, (liqX96 / rp) + x)));
    }

    /// @notice Calculate the new price resulting from removing X
    /// @dev We round up to maximize price impact from removing X.
    /// We want to compute L\sqrt(P) / (L - x\sqrt(P))
    /// If liq is 0, slippage is infinite, and we snap to the maximum valid price.
    function calcNewPriceFromSubX(
        uint128 liq,
        Price oldSqrtPrice,
        uint256 x
    ) public pure returns (Price newSqrtPrice) {
        if (liq == 0) {
            return MAX_PRICE;
        }
        uint256 liqX96 = uint256(liq) << 96;

        // We're removing x, pushing up the price. They expect a certain amount of x out,
        // so we have to round up.
        uint160 rp = Price.unwrap(oldSqrtPrice);
        uint256 xrp;
        unchecked {
            xrp = x * rp;
        }
        if ((xrp / x) == rp) { // If we don't overflow
            uint256 shortDenom;
            unchecked {
                shortDenom = liqX96 - xrp;
            }
            if (shortDenom < liqX96) { // Check the denom hasn't underflowed
                // This might go over so we have to safe cast.
                return Price.wrap(FullMath.mulDivRoundingUp(liqX96, rp, shortDenom).toUint160());
            }
        }
        uint256 ratio = liqX96 / rp;
        if (ratio < x) {
            revert InsufficientX(x);
        }
        uint256 denom;
        unchecked { // Already checked
            denom = ratio - x;
        }
        return Price.wrap(uint160(UnsafeMath.divRoundingUp(liqX96, denom)));
    }

    /// @notice Calculate the new price resulting from adding Y
    /// @dev We round down to minimize price impact of adding Y.
    /// We want to compute y / L + \sqrt(P).
    /// If liq is 0, slippage is infinite, and we snap to the maximum valid price.
    function calcNewPriceFromAddY(
        uint128 liq,
        Price oldSqrtPrice,
        uint256 y
    ) public pure returns (Price newSqrtPrice) {
        if (liq == 0) {
            return MAX_PRICE;
        }

        // We're adding y which buys x and pushes the price up. Round down to minimize x bought.
        uint256 rp = Price.unwrap(oldSqrtPrice); // 160, but used as 256 to save gas

        // If y is small enough, we don't have to resort to full division.
        uint256 delta = ((y <= type(uint160).max)
                         ? (y << 96) / liq
                         : FullMath.mulDiv(X96.SHIFT, y, liq));
        return Price.wrap((delta + rp).toUint160()); // Error on overflow.
    }

    /// @notice Calculate the new price resulting from subtracing Y
    /// @dev We round down to maximize the price impact of removing Y.
    /// We want to compute \sqrt(P) - y / L.
    /// If liq is 0, slippage is infinite, and we snap to the minimum valid price.
    function calcNewPriceFromSubY(
        uint128 liq,
        Price oldSqrtPrice,
        uint256 y
    ) public pure returns (Price newSqrtPrice) {
        if (liq == 0) {
            return MIN_PRICE;
        }

        // We're adding y which buys x and pushes the price up. Round down to minimize x bought.
        uint256 rp = Price.unwrap(oldSqrtPrice); // 160, but used as 256 to save gas

        // If y is small enough, we don't have to resort to full division.
        uint256 delta = ((y <= type(uint160).max)
                         ? (y << 96) / liq
                         : FullMath.mulDiv(X96.SHIFT, y, liq));

        if (delta >= rp) {
            revert InsufficientY(y);
        }
        unchecked {
            return Price.wrap(uint160(rp - delta));
        }
    }

    /// @notice Given a price change, determine the corresponding change in X in absolute terms.
    /// @dev We are computing L(\sqrt{p} - \sqrt{p'}) / \sqrt{pp'} where p > p'
    /// If this is called for a zero liquidity region, the returned delta is 0.
    function calcXFromPriceDelta(
        Price lowSP,
        Price highSP,
        uint128 liq,
        bool roundUp
    ) internal pure returns (uint256 deltaX) {
        if (liq == 0) {
            return 0;
        }

        uint160 pX96 = highSP.unwrap();
        uint160 ppX96 = lowSP.unwrap();
        if (pX96 < ppX96) {
            (pX96, ppX96) = (ppX96, pX96);
        }

        uint256 diffX96 = pX96 - ppX96;
        uint256 liqX96 = uint256(liq) << 96;
        if (roundUp) {
            return UnsafeMath.divRoundingUp(FullMath.mulDivRoundingUp(liqX96, diffX96, pX96), ppX96);
        } else {
            return FullMath.mulDiv(liqX96, diffX96, pX96) / ppX96;
        }
    }

    /// @notice Given a price change, determine the corresponding change in Y in absolute terms.
    /// @dev We are computing L(\sqrt{p'} - \sqrt{p}) where p' > p;
    /// If this is called for a zero liquidity region, the returned delta is 0.
    function calcYFromPriceDelta(
        Price lowSP,
        Price highSP,
        uint128 liq,
        bool roundUp
    ) internal pure returns (uint256 deltaY) {
        if (liq == 0) {
            return 0;
        }

        uint160 pX96 = lowSP.unwrap();
        uint160 ppX96 = highSP.unwrap();
        if (ppX96 < pX96) {
            (pX96, ppX96) = (ppX96, pX96);
        }

        uint256 diffX96 = ppX96 - pX96;
        uint256 denom = X96.SHIFT;
        if (roundUp) {
            return FullMath.mulDivRoundingUp(liq, diffX96, denom);
        } else {
            return FullMath.mulDiv(liq, diffX96, denom);
        }
    }

}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

library MathUtils {

    function abs(int256 self) internal pure returns (int256) {
        return self >= 0 ? self : -self;
    }

    /// @notice Calculates the square root of x using the Babylonian method.
    ///
    /// @dev See https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    /// Copied from PRBMath: https://github.com/PaulRBerg/prb-math/blob/83b3a0dcd4aaca779d0632118772f00611340e79/src/Common.sol
    ///
    /// Notes:
    /// - If x is not a perfect square, the result is rounded down.
    /// - Credits to OpenZeppelin for the explanations in comments below.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as a uint256.
    /// @custom:smtchecker abstract-function-nondet
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // For our first guess, we calculate the biggest power of 2 which is smaller than the square root of x.
        //
        // We know that the "msb" (most significant bit) of x is a power of 2 such that we have:
        //
        // $$
        // msb(x) <= x <= 2*msb(x)$
        // $$
        //
        // We write $msb(x)$ as $2^k$, and we get:
        //
        // $$
        // k = log_2(x)
        // $$
        //
        // Thus, we can write the initial inequality as:
        //
        // $$
        // 2^{log_2(x)} <= x <= 2*2^{log_2(x)+1}
        // sqrt(2^k) <= sqrt(x) < sqrt(2^{k+1})
        // 2^{k/2} <= sqrt(x) < 2^{(k+1)/2} <= 2^{(k/2)+1}
        // $$
        //
        // Consequently, $2^{log_2(x) /2} is a good first approximation of sqrt(x) with at least one correct bit.
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 2 ** 128) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 2 ** 64) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 2 ** 32) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 2 ** 16) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 2 ** 8) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 2 ** 4) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 2 ** 2) {
            result <<= 1;
        }

        // At this point, `result` is an estimation with at least one bit of precision. We know the true value has at
        // most 128 bits, since it is the square root of a uint256. Newton's method converges quadratically (precision
        // doubles at every iteration). We thus need at most 7 iteration to turn our partial result with one bit of
        // precision into the expected uint128 result.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;

            // If x is not a perfect square, round the result toward zero.
            uint256 roundedResult = x / result;
            if (result >= roundedResult) {
                result = roundedResult;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @author Uniswap Team
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = uint256(-int256(denominator)) & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        unchecked {
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4

            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
        }
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }

    /// Calculates a 512 bit product of two 256 bit numbers.
    /// @return r0 The lower 256 bits of the result.
    /// @return r1 The higher 256 bits of the result.
    function mul512(uint256 a, uint256 b)
    internal pure returns(uint256 r0, uint256 r1) {
        assembly {
            let mm := mulmod(a, b, not(0))
            r0 := mul(a, b)
            r1 := sub(sub(mm, r0), lt(mm, r0))
        }
    }

    /// Short circuit mulDiv if the multiplicands don't overflow.
    /// Use this when you expect the input values to be small in most cases.
    /// @dev This charges an extra ~20 gas on top of the regular mulDiv if used, but otherwise costs 30 gas
    function shortMulDiv(
        uint256 m0,
        uint256 m1,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        uint256 num;
        unchecked {
            num = m0 * m1;
        }
        if (num / m0 == m1) {
            return num / denominator;
        } else {
            return mulDiv(m0, m1, denominator);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

/// @notice A classic concurrency lock
/// @dev This is a struct because we want to operate on this in storage so it gets
/// shared across calls into the contract.
struct Mutex {
    bool locked; // Defaults to 0 (false).
}

library MutexImpl {
    error MutexContention();
    // Somewhere in the code, it is possible to unlock twice. This means someone might be
    // able to exploit by sneaking a lock in between the two unlocks.
    error DoubleUnlock();

    function lock(Mutex storage self) internal {
        if (self.locked) {
            revert MutexContention();
        }
        self.locked = true;
    }

    function unlock(Mutex storage self) internal {
        if (!self.locked) {
            revert DoubleUnlock();
        }
        self.locked = false;
    }

    function isLocked(Mutex storage self) internal view returns (bool) {
        return self.locked;
    }
}

library MutexLib {
    bytes32 constant MUTEX_STORAGE_POSITION = keccak256("v4.mutex.diamond.storage");

    function mutexStorage() internal pure returns (Mutex storage m) {
        bytes32 position = MUTEX_STORAGE_POSITION;
        assembly {
            m.slot := position
        }
    }
}

contract Mutexed {
    using MutexImpl for Mutex;

    /// Modifier for a global locking mechanism.
    /// @dev We can explore taking in an arg to specify one of many locks if necessary.
    modifier mutexLocked {
        Mutex storage m = MutexLib.mutexStorage();
        m.lock();
        _;
        m.unlock();
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { Token, TokenImpl } from "Util/Token.sol";
import { IUniswapV3MintCallback, IUniswapV3SwapCallback } from "interfaces/IUniV3.sol";
import { ITakerOpener, ITakerCloser } from "interfaces/ITaker.sol";
import { AMMSpecLib } from "interfaces/IResolution.sol";
import { SafeCast } from "Math/Cast.sol";

// @notice A convenience library for handling our transfer operations.
// This way the rest of the codebase doesn't have to think really carefully
// about safe transfer logic.
// @dev
library TransferLib {
    using TokenImpl for Token;
    using SafeCast for uint256;

    error MintInsufficientReceive(address token, uint256 expected, uint256 received);
    error SwapInsufficientReceive(address token, uint256 expected, uint256 received);
    error TakerInsufficientReceive(address token, uint256 expected, uint256 received);

    /// Receive quantities of both tokens through the Uniswap MintCallback interface.
    function mintReceive(
        Token tokenX, Token tokenY,
        uint256 x, uint256 y
    ) internal {
        bytes memory data = AMMSpecLib.serialize();

        uint256 beforeX = tokenX.balance();
        uint256 beforeY = tokenY.balance();
        IUniswapV3MintCallback(msg.sender).uniswapV3MintCallback(x, y, data);

        uint256 received = tokenX.balance() - beforeX;
        if (x > received) {
            revert MintInsufficientReceive(tokenX.addr(), x, received);
        }
        received = tokenY.balance() - beforeY;
        if (y > received) {
            revert MintInsufficientReceive(tokenY.addr(), y, received);
        }
    }

    /// Receive an amount of one token through the Uniswap SwapCallback interface.
    /// This is usually prefaced by sending the user an amount of another token.
    /// We report the sent amount and requested amount in the callback.
    /// @param isX Is the token we expect to receive x?
    /// @param x the amount of token x we either sent (if neg) or expect to receive (if pos).
    /// @param y the amount of token y we either sent (if neg) or expect to receive (if pos).
    /// @param data A bytes representation of the pool's construction salt. Used to validate this is the desired contract.
    /// For opening a position, the user sets this value and we pass it back to them.
    /// This way the user validates the pool is the one they expect.
    /// For closing a position, the resolver validates the pool, but chooses and
    /// validates the position in other ways.
    function swapReceive(
        Token token,
        bool isX,
        uint256 x, uint256 y,
        bytes calldata data
    ) internal {
        // We if send more than 2^255-1 of a token we just revert.
        int256 iX = x.toInt256();
        int256 iY = y.toInt256();

        uint256 before = token.balance();
        uint256 amount;
        if (isX) {
            amount = x;
            IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(iX, -iY, data);
        } else {
            amount = y;
            IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(-iX, iY, data);
        }
        uint256 received = token.balance() - before; // after is a reserved keyword
        if (received < amount) {
            revert SwapInsufficientReceive(token.addr(), amount, received);
        }
    }

    /// Expect receipt of a certain amount of tokens while possibly providing some tokens
    /// when opening a taker position.
    /// @param data A bytes representation of the pool's construction salt. Used to validate this is the desired contract.
    /// For opening a position, the user sets this value and we pass it back to them.
    /// This way the user validates the pool is the one they expect.
    /// For closing a position, the resolver validates the pool, but chooses and
    /// validates the position in other ways.
    function takerOpenSwapReceive(
        Token token,
        bool isX,
        uint256 x, uint256 y,
        bytes calldata data
    ) internal {
        // We if send more than 2^255-1 of a token we just revert.
        int256 iX = x.toInt256();
        int256 iY = y.toInt256();

        uint256 before = token.balance();
        uint256 amount;
        if (isX) {
            amount = x;
            ITakerOpener(msg.sender).takerOpenSwapCallback(iX, -iY, data);
        } else {
            amount = y;
            ITakerOpener(msg.sender).takerOpenSwapCallback(-iX, iY, data);
        }
        uint256 received = token.balance() - before; // after is a reserved keyword
        if (received < amount) {
            revert TakerInsufficientReceive(token.addr(), amount, received);
        }
    }

    /// When closing a Taker position, we expect receipt of one token, and possibly receipt
    /// or transfer of the other.
    /// @param resolver Unlike other CBs, this is for closing and must be directed at the Resolver contract.
    /// @param x Send x if negative, otherwise expect receipt of x.
    /// @param y Send y if negative, otherwise expect receipt of y.
    function takerExerciseReceive(
        address resolver,
        Token tokenX,
        Token tokenY,
        int256 x, int256 y,
        bytes calldata instructions
    ) internal {
        if (x < 0) {
            tokenX.transfer(msg.sender, uint256(-x));
        } else if (y < 0) {
            tokenY.transfer(msg.sender, uint256(-y));
        }
        // They won't both be negative.

        bytes memory data = AMMSpecLib.serialize();

        // Request what we need.
        uint256 xBefore;
        uint256 yBefore;
        if (x > 0) xBefore = tokenX.balance();
        if (y > 0) yBefore = tokenY.balance();
        ITakerCloser(resolver).takerCloseSwapCallback(x, y, data, instructions);
        if (x > 0) {
            uint256 xAfter = tokenX.balance();
            if (xAfter >= xBefore + uint256(x))
                revert TakerInsufficientReceive(tokenX.addr(), uint256(x), xAfter - xBefore);
        }
        if (y > 0) {
            uint256 yAfter = tokenY.balance();
            if (yAfter >= yBefore + uint256(y))
                revert TakerInsufficientReceive(tokenY.addr(), uint256(y), yAfter - yBefore);
        }
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { Price } from "Ticks/Tick.sol";
import { TableIndex, TableIndexImpl } from "Ticks/Table.sol";
import { TickTable } from "Ticks/TickTable.sol";
import { TableFeeLib } from "Fee/Table.sol";
import { FeeCollector, FeeRateAccumulator } from "Fee/Fees.sol";
import { FeeStorageLib } from "Fee/Storage.sol";
import { LiqStorageLib } from "Liq/Storage.sol";
import { LiqTree } from "Liq/Tree.sol";
import { LiqMath } from "Liq/Math.sol";
import { Accum, AccumImpl } from "Util/Accum.sol";
import { X32 } from "Math/Ops.sol";
import { TBP, TBPImpl } from "Liq/Borrow.sol";
import { RangeLiq, RangeLiqImpl, RangeBool } from "Liq/Structs.sol";
import { FeeRateSnapshot } from "Fee/Snap.sol";

type PosID is uint256;

/// Storage for position tracking
struct PositionManager {
    // We assign positions ID's incrementally.
    // With 2^256 possible IDs, if we create 1 trillion new positions per second,
    // it would still take >3e57 years to run out of IDs.
    // By that time if this contract is still in use we deserve problems.
    uint256 positionCount;

    /// Every position can be queried by its position ID.
    /// Users are expected to track their own position IDs.
    mapping(PosID => Position) posMap;
}

/// Utility library for interaction with positions.
library PositionManagerImpl {
    event InstalledPosition(uint256 posID, int24 lowTBIdx, int24 highTBIdx, uint128 liq, PositionType pType);
    event UninstalledPosition(uint256 posID, int24 lowTBIdx, int24 highTBIdx, uint128 liq, PositionType pType);

    /// Thrown when someone tries to uninstall a non-existant position.
    error PositionNotFound(uint256 posID);

    /// Generate a new position ID to use.
    function getNewPosID(PositionManager storage self) private returns (PosID newPosID) {
        newPosID = PosID.wrap(self.positionCount);
        // 2^256 is soooo high we'll never increment to that numbeer.
        unchecked {
            self.positionCount += 1;
        }
    }

    function install(PositionManager storage self, Position memory pos) internal returns (PosID newPosID) {
        newPosID = getNewPosID(self);
        self.posMap[newPosID] = pos;
        emit InstalledPosition(PosID.unwrap(newPosID),
                               TableIndex.unwrap(pos.low),
                               TableIndex.unwrap(pos.high),
                               pos.liquidity, pos.posType);
    }

    function uninstall(PositionManager storage self, PosID posID) internal returns (Position memory pos) {
        pos = self.posMap[posID];

        // Check if the position was actually there. Pos liquidity can't be zero.
        if (pos.liquidity == 0)
            revert PositionNotFound(PosID.unwrap(posID));

        delete self.posMap[posID];
        emit UninstalledPosition(PosID.unwrap(posID),
                                 TableIndex.unwrap(pos.low),
                                 TableIndex.unwrap(pos.high),
                                 pos.liquidity, pos.posType);
    }

    /// Returns essentially a mutable reference to the position stored at posID.
    function get(PositionManager storage self, PosID posID) internal view returns (Position storage pos) {
        pos = self.posMap[posID];
    }
}

/// The type of position the 2sAMM can open.
/// @dev We can have at most 127 different types before we have to change the Position struct.
enum PositionType {
    Maker, // A regular maker position.
    WideMaker, // A maker position covering the infinite price range.
    TakerCall, // A Taker that has opted to lend the reserved assets.
    TakerPut // A Taker that opted to hold the reserved assets and avoid illiquidity risk.
}

/// Positions tell us how a user affects the liquidity in a pool so we can retrieve their assets
/// and also snapshot AMM swap earnings/fees, and reservation time earnings/fees.
struct Position {
    // Price at the time the position was opened
    Price originalSP; // 160 bits

    // Lower table tick is inclusive
    TableIndex low; // 24 bits
    // Upper table tick is exclusive
    TableIndex high; // 24 bits

    PositionType posType; // 8 bits

    /* 256 */

    uint128 liquidity; // 128 bits

    /* 256 */

    FeeRateSnapshot tableFeeSnapshot; // 512 bits

    /* 256 */
    // For Takers, this rate is a perToken value.
    // For Makers, this rate is a perLiq value.
    FeeRateSnapshot cumEarnRateX32Snap; // 512 bits
}

library PositionLib {
    using TableIndexImpl for TableIndex;
    using TBPImpl for TBP;

    /// Create a new Maker Position
    /// @param rangeBool Where the current tabIdx is relative to the given rLiq.
    function makeM(
        RangeLiq memory rLiq,
        RangeBool rangeBool,
        Price currentSP,
        FeeRateSnapshot memory treeEarnSnap,
        TickTable storage table
    ) internal view returns (Position memory pos) {
        pos.originalSP = currentSP;

        // TODO
        // Can save gas if we use a common struct between position and range liq values.
        pos.low = rLiq.low;
        pos.high = rLiq.high;

        pos.posType = PositionType.Maker;

        pos.liquidity = rLiq.liq;

        // Take snapshots
        FeeCollector storage feeCollector = FeeStorageLib.load();
        FeeRateAccumulator storage globalAccum = feeCollector.globalFeeRateAccumulator;

        pos.tableFeeSnapshot = TableFeeLib.getMRangeFee(
            table, rLiq.low, rLiq.high, rangeBool, globalAccum.MX, globalAccum.MY);

        pos.cumEarnRateX32Snap = treeEarnSnap;
    }

    /// Create a new Taker Position
    /// @param rangeBool Where the current tabIdx is relative to the given rLiq.
    function makeT(
        PositionType posType,
        RangeLiq memory rLiq,
        RangeBool rangeBool,
        Price currentSP,
        TickTable storage table
    ) internal view returns (Position memory pos) {
        pos.originalSP = currentSP;

        // TODO
        // Can save gas if we use a common struct between position and range liq values.
        pos.low = rLiq.low;
        pos.high = rLiq.high;

        pos.posType = posType;

        pos.liquidity = rLiq.liq;

        // Take snapshots
        FeeCollector storage feeCollector = FeeStorageLib.load();
        FeeRateAccumulator storage globalAccum = feeCollector.globalFeeRateAccumulator;

        pos.tableFeeSnapshot = TableFeeLib.getTRangeFee(
            table, rLiq.low, rLiq.high, rangeBool, globalAccum.TX, globalAccum.TY);

        // Slight optimization to avoid reading/writing storage unnecessarily
        if (rangeBool == RangeBool.Below) {
            // If the current tick is lower than the low tick,
            // our complementary Maker is entirely in X.
            TBP storage xtbp = LiqStorageLib.xTBP();
            pos.cumEarnRateX32Snap.X = xtbp.value();
        } else if (rangeBool == RangeBool.Above) {
            // If the current tick is higher than the high tick,
            // our complmentary Maker is entirely in Y.
            TBP storage ytbp = LiqStorageLib.yTBP();
            pos.cumEarnRateX32Snap.Y = ytbp.value();
        } else { // We have a mix
            TBP storage xtbp = LiqStorageLib.xTBP();
            TBP storage ytbp = LiqStorageLib.yTBP();
            pos.cumEarnRateX32Snap.X = xtbp.value();
            pos.cumEarnRateX32Snap.Y = ytbp.value();
        }
    }

    /// Specific factory function for WideMaker positions.
    function makeWideM(FeeRateSnapshot memory treeEarnSnap) internal view returns (Position memory pos) {
        // No need for original price or ticks.

        pos.posType = PositionType.WideMaker;

        FeeCollector storage feeCollector = FeeStorageLib.load();
        FeeRateAccumulator storage globalAccum = feeCollector.globalFeeRateAccumulator;
        pos.tableFeeSnapshot.X = globalAccum.MX;
        pos.tableFeeSnapshot.Y = globalAccum.MY;

        pos.cumEarnRateX32Snap = treeEarnSnap;
    }
}

library PositionImpl {
    using AccumImpl for Accum;
    using TBPImpl for TBP;

    /// The Taker fees are too high to repay at once. This will basically never happen.
    /// But if it ever does the solution is to just split the position first.
    error TakerTimeFeeOverflow(uint256 top, uint256 bot, uint256 rateX32, uint256 borrowed);

    /// Determine the fees earned by this Maker position.
    /// The time and volatility fees are summed together.
    /// @param rangeBool Where the current table index is relative to the given low and high SPs.
    function calcMakerFees(
        Position memory self,
        RangeBool rangeBool,
        TickTable storage table,
        FeeRateSnapshot memory treeEarnSnap
    ) internal view returns (uint256 xFee, uint256 yFee) {

        FeeRateSnapshot memory currentFees;

        { // Oh now stupid the Solidity compiler is...
            FeeCollector storage feeCollector = FeeStorageLib.load();
            FeeRateAccumulator storage globalAccum = feeCollector.globalFeeRateAccumulator;

            TableIndex low = self.low;
            TableIndex high = self.high;

            currentFees = TableFeeLib.getMRangeFee(
                table, low, high, rangeBool, globalAccum.MX, globalAccum.MY
            );
        }

        // Table Fees are a per liq rate.
        uint256 xFeeRate = currentFees.X.diff(self.tableFeeSnapshot.X);
        uint256 yFeeRate = currentFees.Y.diff(self.tableFeeSnapshot.Y);

        // Add tree perLiq fees as well.
        xFeeRate += treeEarnSnap.X.diff(self.cumEarnRateX32Snap.X);
        yFeeRate += treeEarnSnap.Y.diff(self.cumEarnRateX32Snap.Y);

        // Revert on overflow. Earning more than 2^256 in fees is absolute batshit insane.
        xFee += xFeeRate * self.liquidity;
        yFee += yFeeRate * self.liquidity;
    }

    /// Determine the fees owed by this Taker position.
    /// The time and volatility fees are summed together.
    /// @param rangeBool Where the current table index is relative to the given low and high SPs.
    function calcTakerFees(
        Position memory self,
        Price lowSP,
        Price highSP,
        RangeBool rangeBool,
        TickTable storage table
    ) internal view returns (uint256 xFee, uint256 yFee) {

        FeeRateSnapshot memory currentFees;
        { // Again this is for the stack depth, because Solc needs some hand holding.
            FeeCollector storage feeCollector = FeeStorageLib.load();
            FeeRateAccumulator storage globalAccum = feeCollector.globalFeeRateAccumulator;
            currentFees = TableFeeLib.getTRangeFee(
                table, self.low, self.high, rangeBool, globalAccum.TX, globalAccum.TY
            );
        }
        uint256 xFeeRate = currentFees.X.diff(self.tableFeeSnapshot.X);
        uint256 yFeeRate = currentFees.Y.diff(self.tableFeeSnapshot.Y);
        // Revert on overflow. Paying more than 2^256 in fees is absolute batshit insane.
        xFee += xFeeRate * self.liquidity;
        yFee += yFeeRate * self.liquidity;

        // We use the original price to determine the amounts borrowed.
        (uint256 borrowedX, uint256 borrowedY) =
        LiqMath.calcMakerHoldingsHelper(lowSP, highSP, self.originalSP, self.liquidity, true);

        if (borrowedX > 0) {
            TBP storage xtbp = LiqStorageLib.xTBP();
            uint256 rateX32 = xtbp.value().diff(self.cumEarnRateX32Snap.X);
            (uint256 botX, uint256 topX) = X32.mul512(rateX32, borrowedX);
            if (topX > 0) {
                revert TakerTimeFeeOverflow(topX, botX, rateX32, borrowedX);
            }
            xFee += botX;
        }
        if (borrowedY > 0) {
            TBP storage ytbp = LiqStorageLib.yTBP();
            uint256 rateX32 = ytbp.value().diff(self.cumEarnRateX32Snap.Y);
            (uint256 botY, uint256 topY) = X32.mul512(rateX32, borrowedY);
            if (topY > 0) {
                revert TakerTimeFeeOverflow(topY, botY, rateX32, borrowedY);
            }
            yFee += botY;
        }
    }

    /// Calculate fee earnings for a wide maker position.
    function calcWideMakerFees(Position memory self, FeeRateSnapshot memory treeEarnSnap)
    internal view returns (uint256 xFee, uint256 yFee) {
        // Position type should have been verified before calling this function.

        FeeCollector storage feeCollector = FeeStorageLib.load();
        FeeRateAccumulator storage globalAccum = feeCollector.globalFeeRateAccumulator;
        uint256 xFeeRate = globalAccum.MX.diff(self.tableFeeSnapshot.X);
        uint256 yFeeRate = globalAccum.MY.diff(self.tableFeeSnapshot.Y);

        // Add tree perLiq fees as well.
        xFeeRate += treeEarnSnap.X.diff(self.cumEarnRateX32Snap.X);
        yFeeRate += treeEarnSnap.Y.diff(self.cumEarnRateX32Snap.Y);

        // Revert on overflow. Paying more than 2^256 in fees is absolute batshit insane.
        xFee += xFeeRate * self.liquidity;
        yFee += yFeeRate * self.liquidity;
    }

    function rangeLiq(Position memory self) internal view returns (RangeLiq memory rLiq) {
        return RangeLiqImpl.fromTables(self.liquidity, self.low, self.high);
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { TableIndex, TableIndexImpl } from "Ticks/Table.sol";
import { TickTable, TickTableImpl } from "Ticks/TickTable.sol";
import { TickData, TickDataImpl } from "Ticks/Data.sol";
import { SafeCast } from "Math/Cast.sol";
import { RangeLiq } from "Liq/Structs.sol";

/// Helper functions for the liquidity table when interacting with the TickTable
library LiqTableLib {
    using TickTableImpl for TickTable;
    using TableIndexImpl for TableIndex;
    using TickDataImpl for TickData;
    using SafeCast for uint128;

    /// Add Maker liquidity to a range of ticks
    function addMakerLiq(TickTable storage table, RangeLiq memory rLiq) internal {
        require(rLiq.low.isLT(rLiq.high));

        int128 liq = rLiq.liq.toInt128();
        TickData storage data = table.getData(rLiq.low);
        bool isNew = data.addMakerLiq(liq);
        if (isNew) {
            table.setBit(rLiq.low);
        }

        data = table.getData(rLiq.high);
        isNew = data.addMakerLiq(-liq);
        if (isNew) {
            table.setBit(rLiq.high);
        }
    }

    /// Add Taker liquidity to a range of ticks
    function addTakerLiq(TickTable storage table, RangeLiq memory rLiq) internal {
        require(rLiq.low.isLT(rLiq.high));

        int128 liq = rLiq.liq.toInt128();
        TickData storage data = table.getData(rLiq.low);
        bool isNew = data.addTakerLiq(liq);
        if (isNew) {
            table.setBit(rLiq.low);
        }

        data = table.getData(rLiq.high);
        isNew = data.addTakerLiq(-liq);
        if (isNew) {
            table.setBit(rLiq.high);
        }
    }

    /// Remove Maker liquidity from a range of ticks
    function removeMakerLiq(TickTable storage table, RangeLiq memory rLiq) internal {
        require(rLiq.low.isLT(rLiq.high));

        int128 liq = rLiq.liq.toInt128();
        TickData storage data = table.getData(rLiq.low);
        bool isEmpty = data.removeMakerLiq(liq);
        if (isEmpty) {
            table.clearBit(rLiq.low);
        }

        data = table.getData(rLiq.high);
        isEmpty = data.removeMakerLiq(-liq);
        if (isEmpty) {
            table.clearBit(rLiq.high);
        }
    }

    /// Remove Taker liquidity from a range of ticks
    function removeTakerLiq(TickTable storage table, RangeLiq memory rLiq) internal {
        require(rLiq.low.isLT(rLiq.high));

        int128 liq = rLiq.liq.toInt128();
        TickData storage data = table.getData(rLiq.low);
        bool isEmpty = data.removeTakerLiq(liq);
        if (isEmpty) {
            table.clearBit(rLiq.low);
        }

        data = table.getData(rLiq.high);
        isEmpty = data.removeTakerLiq(-liq);
        if (isEmpty) {
            table.clearBit(rLiq.high);
        }
    }

    /// When a position is split, none of the liquidity values need to change,
    /// but we do have to modify the ref counts of the TickDatas
    function splitLiq(TickTable storage table, TableIndex low, TableIndex high) internal {
        TickData storage data = table.getData(low);
        data.incRefCount();
        data = table.getData(high);
        data.incRefCount();
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { PosID } from "Liq/Pos.sol";
import { SwapStorageLib, ImmutInfoStorage } from "Swap/Storage.sol";
import { PositionSource } from "interfaces/PositionManagerStructs.sol";
import { IPositionManager } from "interfaces/IPositionManager.sol";


/// Helpers for interacting with the portfolio manager.
library PMLib {
    /// Helper function for installing our positions with the PortfolioManager
    function PMInstall(PosID posID, address owner, uint8 portfolio)
    internal returns (uint256 positionID) {
        ImmutInfoStorage storage info = SwapStorageLib.infoStorage();
        return IPositionManager(info.PM).installAsset(
            PositionSource.AMM,
            owner,
            PosID.unwrap(posID),
            portfolio);
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;
import { TickIndex, TickIndexImpl, TickLib } from "Ticks/Tick.sol";
import { PriceImpl, Price } from "Ticks/Tick.sol";
import { TableIndex, TableIndexImpl } from "Ticks/Table.sol";
import { TickTable, TickTableImpl } from "Ticks/TickTable.sol";
import { TickStorageLib } from "Ticks/Storage.sol";
import { SwapStorageLib, SwapStorage } from "Swap/Storage.sol";

/// Transient struct used by LiqFacet for constructing positions and modifying liquidity.
struct RangeLiq {
    // We give each entry its own slot because we're not storing this so space is cheap
    // and we want it to be cheaply read and written to. So we make it the first
    // in a 256 bit slot.
    // This remains cheap as our as our memory usage is limited to below the quadratic range.
    uint128 liq;
    uint128 _padding0;
    /* 256 */
    TableIndex low; // 24
    uint232 _padding1;
    /* 256 */
    TableIndex high; // 24
    uint232 _padding2;
    /* 256 */
    Price lowSP; // 160
    uint96 _padding3;
    /* 256 */
    Price highSP; // 160
    uint96 _padding4;
    /* 256 */


}

library RangeLiqImpl {
    using PriceImpl for Price;
    using TickIndexImpl for TickIndex;
    using TickTableImpl for TickTable;
    using TableIndexImpl for TableIndex;

    /// Used by external functions to get a RangeLiq object to work with.
    function fromTicks(uint128 liq, int24 lowerTick, int24 upperTick) internal view returns (RangeLiq memory rLiq) {
        rLiq.liq = liq;

        // validates range
        TickIndex lowTickIndex = TickLib.newTickIndex(lowerTick);
        TickIndex highTickIndex = TickLib.newTickIndex(upperTick);

        // validates spacing
        TickTable storage table = TickStorageLib.tickTable();
        table.validateTickIndexSpacing(lowTickIndex);
        table.validateTickIndexSpacing(highTickIndex);

        rLiq.lowSP = lowTickIndex.toSqrtPrice();
        rLiq.highSP = highTickIndex.toSqrtPrice();

        rLiq.low = table.getTableIndex(lowTickIndex);
        rLiq.high = table.getTableIndex(highTickIndex);
    }

    /// Used by Position to provide a RangeLiq object to work with.
    function fromTables(uint128 liq, TableIndex low, TableIndex high) internal view returns (RangeLiq memory rLiq) {
        rLiq.liq = liq;
        rLiq.low = low;
        rLiq.high = high;

        TickTable storage table = TickStorageLib.tickTable();
        TickIndex lowerTick = table.getTickIndex(low);
        TickIndex upperTick = table.getTickIndex(high);

        rLiq.lowSP = lowerTick.toSqrtPrice();
        rLiq.highSP = upperTick.toSqrtPrice();
    }

    /// Return true if the table index is within the RangeLiq's range.
    function contains(RangeLiq memory self, TableIndex tabIdx) internal pure returns (bool) {
        return (self.low.isLTE(tabIdx) && tabIdx.isLT(self.high));
    }

    /// Return true if the price is within the RangeLiq's range.
    function contains(RangeLiq memory self, Price sqrtP) internal pure returns (bool) {
        return (self.lowSP.lteq(sqrtP) && sqrtP.lt(self.highSP));
    }

    /// Returns the Range bool for comparing a price to the range.
    function compare(RangeLiq memory self, Price sqrtP) internal pure returns (RangeBool) {
        if (sqrtP.lt(self.lowSP)) {
            return RangeBool.Below;
        } else if (sqrtP.lt(self.highSP)) {
            return RangeBool.Within;
        } else {
            return RangeBool.Above;
        }
    }
}

/// Enum for indicating where a value is relative to a given range.
/// Primarily used for indicating if the current price is within
/// a price range.
enum RangeBool {
    Below, // The comparison was below the range.
    Within, // The comparison value was within the range.
    Above // The comparison value was above the range.
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { Accum } from "Util/Accum.sol";

/// A snapshot of the inside fee rate at the time a position was opened/last updated.
struct FeeRateSnapshot {
    Accum X;
    Accum Y;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { FullMath } from "Math/FullMath.sol";

library X32 {
    // Multiply two 256 bit numbers to a 512 number, but one of the 256's is X32.
    function mul512(uint256 a, uint256 b)
    internal pure returns (uint256 bot, uint256 top) {
        (uint256 rawB, uint256 rawT) = FullMath.mul512(a, b);
        bot = (rawB >> 32) + (rawT << 224);
        top = rawT >> 32;
    }
}

library X64 {
    // Multiply two 256 bit numbers to a 512 number, but one of the 256's is X32.
    function mul512(uint256 a, uint256 b)
    internal pure returns (uint256 bot, uint256 top) {
        (uint256 rawB, uint256 rawT) = FullMath.mul512(a, b);
        bot = (rawB >> 64) + (rawT << 192);
        top = rawT >> 64;
    }
}

/**
 * @notice Utility for Q64.96 operations
 **/
library Q64X96 {

    uint256 constant PRECISION = 96;

    uint256 constant HALF96 = uint256(1 << 95);

    error Q64X96Overflow(uint160 a, uint256 b);

    /// Multiply an X96 precision number by an arbitrary uint256 number.
    /// Returns with the same precision as b.
    /// The result takes up 256 bits. Will error on overflow.
    function mul(uint160 a, uint256 b, bool roundUp) internal pure returns(uint256) {
        (uint256 bot, uint256 top) = FullMath.mul512(a, b);
        uint256 round = (roundUp && (bot & HALF96 != 0)) ? 1 : 0;
        if ((top >> 96) > 0) {
            revert Q64X96Overflow(a, b);
        }
        return (bot >> 96 + round) + (top << 160);
    }

    /// Divide a uint160 by a Q64X96 number.
    /// Returns with the same precision as num.
    /// @dev uint160 is chosen because once the 96 bits of precision are cancelled out,
    /// the result is at most 256 bits.
    function div(uint160 num, uint160 denom, bool roundUp)
    internal pure returns (uint256 res) {
        uint256 fullNum = uint256(num) << PRECISION;
        res = fullNum / denom;
        if (roundUp && (res * denom < fullNum)) {
            res += 1;
        }
    }
}

library X96 {
    uint256 constant PRECISION = 96;
    uint256 constant SHIFT = 1 << 96;
}

library X128 {
    uint256 constant PRECISION = 128;

    uint256 constant MAX = type(uint128).max;

    /// Multiply a 256 bit number by a 128 bit number. Either of which is X128.
    /// @dev This rounds results down.
    function mul256(uint128 a, uint256 b) internal pure returns (uint256) {
        (uint256 bot, uint256 top) = FullMath.mul512(a, b);
        return (bot >> 128) + (top << 128);
    }

    /// Multiply a 256 bit number by a 128 bit number. Either of which is X128.
    /// @dev This rounds results up.
    function mul256RoundUp(uint128 a, uint256 b) internal pure returns (uint256 res) {
        (uint256 bot, uint256 top) = FullMath.mul512(a, b);
        uint256 modmax = MAX;
        assembly {
            res := add(add(shr(128, bot), shl(128, top)), gt(mod(bot, modmax), 0))
        }
    }

    /// Multiply a 256 bit number by a 256 bit number, either of which is X128, to get 384 bits.
    /// @dev This rounds results down.
    /// @return bot The bottom 256 bits of the result.
    /// @return top The top 128 bits of the result.
    function mul512(uint256 a, uint256 b) internal pure returns (uint256 bot, uint256 top) {
        (uint256 _bot, uint256 _top) = FullMath.mul512(a, b);
        bot = (_bot >> 128) + (_top << 128);
        top = _top >> 128;
    }
}

/// Convenience library for interacting with Uint128s by other types.
library U128Ops {

    function add(uint128 self, int128 other) public pure returns (uint128) {
        if (other >= 0) {
            return self + uint128(other);
        } else {
            return self - uint128(-other);
        }
    }

    function sub(uint128 self, int128 other) public pure returns (uint128) {
        if (other >= 0) {
            return self - uint128(other);
        } else {
            return self + uint128(-other);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math functions that do not check inputs or outputs
/// @notice Contains methods that perform common math functions but do not do any overflow or underflow checks
library UnsafeMath {
    /// @notice Returns ceil(x / y)
    /// @dev division by 0 returns 0
    /// @param x The dividend
    /// @param y The divisor
    /// @return z The quotient, ceil(x / y)
    function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

type Accum is uint256;

/// Type accum is an accumulator variable that can overflow and wrap around.
/// It is used for values that grow in size but can't grow so fast that a user could reasonably wrap around.
/// For example a user might collect fees over the lifetime of their positions. 2^256 is so large
/// that it is practically impossible for them to wrap all the way around.
/// However we want to do this safely so we wrap this in a type that doesn't allow subtraction.
library AccumImpl {
    /// Construct accumulator from a uint value
    function from(uint256 num) public pure returns (Accum) {
        return Accum.wrap(num);
    }

    /// Construct accumulator from a signed int.
    function from(int256 num) public pure returns (Accum) {
        // We can just cast to a uint because all ints wrap around the same way which
        // is the only property we need here.
        return Accum.wrap(uint256(num));
    }

    /// Add to the accumulator.
    /// @param addend the value being added
    /// @return acc The new accumulated value
    function add(Accum self, uint256 addend) internal pure returns (Accum acc) {
        unchecked {
            return Accum.wrap(Accum.unwrap(self) + addend);
        }
    }

    /// Calc the difference between self and other. This tells us how much has accumulated.
    /// @param other the value being subtracted from the accumulation
    /// @return difference The difference between other and self which is always positive.
    function diff(Accum self, Accum other) internal pure returns (uint256) {
        unchecked { // underflow is okay
            return Accum.unwrap(self) - Accum.unwrap(other);
        }
    }

    /// Also calculates the difference between self and other, telling us the total accumlation.
    /// @return diffAccum The difference between self and other but as an Accum
    function diffAccum(Accum self, Accum other) internal pure returns (Accum) {
        return Accum.wrap(diff(self, other));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Minimal ERC20 interface for Uniswap
/// @notice Contains a subset of the full ERC20 interface that is used in Uniswap V3
interface IERC20Minimal {
    /// @notice Returns the balance of a token
    /// @param account The account for which to look up the number of tokens it has, i.e. its balance
    /// @return The number of tokens held by the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers the amount of token from the `msg.sender` to the recipient
    /// @param recipient The account that will receive the amount transferred
    /// @param amount The number of tokens to send from the sender to the recipient
    /// @return Returns true for a successful transfer, false for an unsuccessful transfer
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Returns the current allowance given to a spender by an owner
    /// @param owner The account of the token owner
    /// @param spender The account of the token spender
    /// @return The current allowance granted by `owner` to `spender`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets the allowance of a spender from the `msg.sender` to the value `amount`
    /// @param spender The account which will be allowed to spend a given amount of the owners tokens
    /// @param amount The amount of tokens allowed to be used by `spender`
    /// @return Returns true for a successful approval, false for unsuccessful
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`
    /// @param sender The account from which the transfer will be initiated
    /// @param recipient The recipient of the transfer
    /// @param amount The amount of the transfer
    /// @return Returns true for a successful transfer, false for unsuccessful
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @notice Event emitted when tokens are transferred from one address to another, either via `#transfer` or `#transferFrom`.
    /// @param from The account from which the tokens were sent, i.e. the balance decreased
    /// @param to The account to which the tokens were sent, i.e. the balance increased
    /// @param value The amount of tokens that were transferred
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Event emitted when the approval amount for the spender of a given owner's tokens changes.
    /// @param owner The account that approved spending of its tokens
    /// @param spender The account for which the spending allowance was modified
    /// @param value The new allowance from the owner to the spender
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.13;

/// A generic bitmap used by the TickTable.
struct Bitmap {
    uint256 num;
}

/**
 * @title BitmapImpl
 * @notice Utility for tracking set bits in a bit map;
 **/
library BitmapImpl {

    function isSet(Bitmap storage self, uint8 idx) internal view returns(bool set) {
        return ((self.num >> idx) & 0x1 == 1);
    }

    function trySet(Bitmap storage self, uint8 idx) internal {
        self.num |= uint(1) << idx;
    }

    function clear(Bitmap storage self, uint8 idx) internal {
        self.num &= ~(uint(1) << idx);
    }

    function getAtOrNext(Bitmap storage self, uint8 idx) internal view returns(bool exists, uint8 nextIdx) {
        uint8 shift = idx;
        uint256 shifted = self.num >> shift;
        if (shifted == 0) {
            return (false, 0);
        }

        uint8 lsb = getLSBIdx(Bitmap({num: shifted}));
        unchecked {
            return (true, lsb + shift);
        }
    }

    function getAtOrPrev(Bitmap storage self, uint8 idx) internal view returns(bool exists, uint8 prevIdx) {
        unchecked {
        uint8 shift = 255 - idx;
        uint256 shifted = self.num << shift;
        if (shifted == 0) {
            return (false, 0);
        }

        uint8 msb = getMSBIdx(Bitmap({num: shifted}));
        return (true, msb - shift);
        }
    }

    /// Get idx of the most significant bit
    function getMSBIdx(Bitmap memory self) internal pure returns(uint8 idx) {
        uint256 num = self.num;
        require(num != 0);

        unchecked {
        idx = 0;
        if (num > type(uint128).max) {
            idx += 128;
            num >>= 128;
        }
        if (num > type(uint64).max) {
            idx += 64;
            num >>= 64;
        }
        if (num > type(uint32).max) {
            idx += 32;
            num >>= 32;
        }
        if (num > type(uint16).max) {
            idx += 16;
            num >>= 16;
        }
        if (num > type(uint8).max) {
            idx += 8;
            num >>= 8;
        }
        if (num > 15) {
            idx += 4;
            num >>= 4;
        }
        if (num > 3) {
            idx += 2;
            num >>= 2;
        }
        if (num > 1) {
            idx += 1;
        }
        }
    }

    /// Get idx of the least significant bit
    function getLSBIdx(Bitmap memory self) internal pure returns(uint8 idx) {
        uint256 num = self.num;
        require(num != 0);

        unchecked {
        idx = 0;
        if (num & type(uint128).max == 0) {
            idx += 128;
            num >>= 128;
        }
        if (num & type(uint64).max == 0) {
            idx += 64;
            num >>= 64;
        }
        if (num & type(uint32).max == 0) {
            idx += 32;
            num >>= 32;
        }
        if (num & type(uint16).max == 0) {
            idx += 16;
            num >>= 16;
        }
        if (num & type(uint8).max == 0) {
            idx += 8;
            num >>= 8;
        }
        if (num & 0x0F == 0) {
            idx += 4;
            num >>= 4;
        }
        if (num & 0x03 == 0) {
            idx += 2;
            num >>= 2;
        }
        if (num & 0x01 == 0) {
            idx += 1;
        }
        }
    }

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

/// Taker related callbacks.
interface ITakerOpener {

    /// Swap assets when opening a Taker position.
    /// Gives one of one asset, and requests one of the other from an Opening contract.
    /// These two assets are not of the same value. The asset demanded is always of greater value.
    /// @param xDelta The amount of x the AMM expects to receive. Negative, if x was given to user.
    /// @param yDelta The amount of y the AMM expects to receive. Negative, if y was given to user.
    /// @param data Information about the pool, to verify the sender is valid.
    function takerOpenSwapCallback(
        int256 xDelta,
        int256 yDelta,
        bytes calldata data
    ) external;
}

interface ITakerCloser {
    /// Swap assets when closing a Taker position.
    /// Gives one of one asset, and requests one of the other from a Resolver contract.
    /// These two assets are not of the same value. The asset demanded is always of greater value.
    /// @param xDelta The amount of x the AMM expects to receive. Negative, if x was given to user.
    /// @param yDelta The amount of y the AMM expects to receive. Negative, if y was given to user.
    /// @param data Information about the pool, to verify the sender is valid.
    /// @param instructions Information about how the user would like to close this position.
    function takerCloseSwapCallback(
        int256 xDelta,
        int256 yDelta,
        bytes calldata data,
        bytes calldata instructions
    ) external;
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { SwapStorageLib, ImmutInfoStorage } from "Swap/Storage.sol";
import { TickTable } from "Ticks/TickTable.sol";
import { TickStorageLib } from "Ticks/Storage.sol";
import { Token, TokenImpl } from "Util/Token.sol";

struct AMMSpec {
    address tokenX;
    address tokenY;
    uint24 tickSpacing;
}

library AMMSpecLib {
    using TokenImpl for Token;

    function serialize() internal view returns (bytes memory spec) {
        ImmutInfoStorage storage info = SwapStorageLib.infoStorage();
        TickTable storage table = TickStorageLib.tickTable();

        AMMSpec memory aSpec;
        aSpec.tokenX = info.tokenX.addr();
        aSpec.tokenY = info.tokenY.addr();
        // Internally spacing is always positive. Just int to make math convenient.
        aSpec.tickSpacing = uint24(table.spacing);

        spec = abi.encode(aSpec);
    }

    function deserialize(bytes calldata spec) internal pure returns (AMMSpec memory aSpec) {
        return abi.decode(spec, (AMMSpec));
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

import { TableIndex, TableIndexImpl } from "Ticks/Table.sol";
import { TickTable, TickTableImpl } from "Ticks/TickTable.sol";
import { TickData } from "Ticks/Data.sol";
import { Accum, AccumImpl } from "Util/Accum.sol";
import { FeeRateSnapshot } from "Fee/Snap.sol";
import { RangeBool } from "Liq/Structs.sol";


/// Utility functions for querying fees from the TickTable.
/// @dev We use sqrtPrice when  because table->SP is much cheaper than SP->table.
library TableFeeLib {
    using TableIndexImpl for TableIndex;
    using TickTableImpl for TickTable;
    using AccumImpl for Accum;

    /// Calculate the inside fee accumulation for Maker earnings since contract deployement in a given range
    /// @dev Recall the inside feeRate is the feeRate for the range usually calculated as the
    /// difference of two outside feeRates or the global rate minus two outside fee rates.
    /// Because it is the result of differences it can be negative.
    function getMRangeFee(
        TickTable storage table,
        TableIndex low,
        TableIndex high,
        RangeBool rBool,
        Accum globalMX,
        Accum globalMY) internal view returns (FeeRateSnapshot memory makerSnap) {
        require(low.isLT(high), "MRF");

        // Data we fetch should be set. Fortunately this should happen
        // from a previous step where liquidity is added.
        TickData storage lowData = table.getData(low);
        TickData storage highData = table.getData(high);

        if (rBool == RangeBool.Below) {
            makerSnap.X = lowData.outsideFeeRateAccumulator.MX.diffAccum(highData.outsideFeeRateAccumulator.MX);
            makerSnap.Y = lowData.outsideFeeRateAccumulator.MY.diffAccum(highData.outsideFeeRateAccumulator.MY);
        } else if (rBool == RangeBool.Within) {
            makerSnap.X = globalMX.diffAccum(lowData.outsideFeeRateAccumulator.MX).diffAccum(highData.outsideFeeRateAccumulator.MX);
            makerSnap.Y = globalMY.diffAccum(lowData.outsideFeeRateAccumulator.MY).diffAccum(highData.outsideFeeRateAccumulator.MY);
        } else {
            makerSnap.X = highData.outsideFeeRateAccumulator.MX.diffAccum(lowData.outsideFeeRateAccumulator.MX);
            makerSnap.Y = highData.outsideFeeRateAccumulator.MY.diffAccum(lowData.outsideFeeRateAccumulator.MY);
        }
    }

    /// Calculate the inside fee accumulation for Taker debts since contract deployement in a given range
    /// @dev Recall the inside feeRate is the feeRate for the range usually calculated as the
    /// difference of two outside feeRates or the global rate minus two outside fee rates.
    /// Because it is the result of differences it can be negative.
    function getTRangeFee(
        TickTable storage table,
        TableIndex low,
        TableIndex high,
        RangeBool rBool,
        Accum globalTX,
        Accum globalTY) internal view returns (FeeRateSnapshot memory takerSnap) {
        require(low.isLT(high), "TRF");

        // Data we fetch should be set. Fortunately this should happen
        // in a follow up step where liquidity is added to the table.
        TickData storage lowData = table.getData(low);
        TickData storage highData = table.getData(high);

        if (rBool == RangeBool.Below) {
            takerSnap.X = lowData.outsideFeeRateAccumulator.TX.diffAccum(highData.outsideFeeRateAccumulator.TX);
            takerSnap.Y = lowData.outsideFeeRateAccumulator.TY.diffAccum(highData.outsideFeeRateAccumulator.TY);
        } else if (rBool == RangeBool.Within) {
            takerSnap.X = globalTX.diffAccum(lowData.outsideFeeRateAccumulator.TX).diffAccum(highData.outsideFeeRateAccumulator.TX);
            takerSnap.Y = globalTY.diffAccum(lowData.outsideFeeRateAccumulator.TY).diffAccum(highData.outsideFeeRateAccumulator.TY);
        } else {
            takerSnap.X = highData.outsideFeeRateAccumulator.TX.diffAccum(lowData.outsideFeeRateAccumulator.TX);
            takerSnap.Y = highData.outsideFeeRateAccumulator.TY.diffAccum(lowData.outsideFeeRateAccumulator.TY);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * @notice An enum representing the source of a position.
 * 1. AMM - Position originating from an AMM
 * 2. Reserve - Position originating from a reserve
 * 3. Pocketbook - Position originating from a pocketbook
 */
enum PositionSource {
    AMM,
    Reserve,
    Pocketbook
}

/**
 * @notice A struct representing a group of collateral or debt tokens
 * @param source The source of the asset
 * @param sourceAddress The address of the producer
 * @param tokens The address of the token in the pair.
 * @param amounts The amount of each token. note amounts are reported as signed integers.
 */
struct Record {
    PositionSource source;
    address sourceAddress;
    address[] tokens;
    int256[] amounts;
}

/**
 * @notice A struct to hold the user's portfolio data
 * @param totalCollateral The total collateral of the user
 * @param totalDebt The total debt of the user
 * @param healthFactor The health factor of the user -- totalCollateral / totalDebt
 * @param utilization The utilization of the user -- totalDebt / totalCollateral
 */
struct PortfolioData {
    uint256 totalCollateral;
    uint256 totalDebt;
    uint256 healthFactor;
    uint256 utilization;
}

/**
 *  @notice A struct representing the calldata for a liquidation.
 *  @param positionId The id of the position to liquidate.
 *  @param amount The amount of the position to liquidate.
 *  @param reassignment Whether to reassign the position or to close and uninstall it.
 */
struct LiquidatePortfolio {
    uint256 positionId;
    uint256 amount;
    bool reassignment;
}

/**
 *  @notice A struct to hold the parameters for the Liquidate function
 *  @dev This struct is used to pass the parameters for the Liquidate function
 *  @param borrower The borrower address
 *  @param liquidator The liquidator address
 *  @param portfolio The portfolio number
 */
struct LiquidateParams {
    address borrower;
    address liquidator;
    uint8 portfolio;
}

/**
 * @notice A struct to hold the local variables for the Liquidate function
 * @dev This struct is used to pass the local variables for the Liquidate function
 * @param baseAmountIn The amount of the base token to supply to the AMM
 * @param baseAmountOut The amount of the base token to receive from the AMM
 * @param debtToRepay The amount of debt to cover calculated with Q(1 - TU * P) = 1 - TU / BU, Q * D
 * @param collateralToRedeem The amount of collateral to receive calculated with Q * D * P
 * @param debtBurned The amount of the debt token that has been burned
 */
struct ExecuteLiquidateLocalVars {
    uint256 baseAmountIn;
    uint256 baseAmountOut;
    uint256 debtToRepay;
    uint256 collateralToRedeem;
    uint256 debtBurned;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Record, PortfolioData, LiquidatePortfolio} from "interfaces/PositionManagerStructs.sol";
import {LiquidateParams, PositionSource} from "interfaces/PositionManagerStructs.sol";

interface IPositionManager {
    error InputLengthMismatch();
    error ExecutionFailed(uint256 commandIndex);
    error InvalidCommand();
    error PortfolioUndercollateralized();
    error PositionNotFound();
    error InsufficientCollateralToClosePosition(uint256 provided, uint256 required);

    event Liquidate(address borrower, uint256 amountIn, uint256 amountOut);

    /**
     * @notice adds the address of a producer to the list of producers
     * @dev should only be callable by the authority
     * @param _producer The address of the producer
     */
    function registerProducer(address _producer) external;

    /**
     * @notice removes the address of a producer from the list of producers
     * @dev should only be callable by the authority
     * @param _producer The address of the producer
     */
    function removeProducer(address _producer) external;

    /**
     * @notice registers a token with the position manager. adds a lookup for the pyth price feed.
     * @dev should only be callable by the authority
     * @param _token The address of the token
     * @param _feed The bytes32 of the price feed
     */
    function registerToken(address _token, bytes32 _feed) external;

    /**
     * @notice Uninstalls a position from the protocol.
     * @dev only callable by the position manager itself.
     * 1. called when owner of a position wishes to exit.
     * 2. called when a position is liquidated.
     * @param _source The source of the position.
     * @param _owner The owner of the position.
     * @param _assetId The assetId of the position.
     * @param _portfolio The portfolio the position is in.
     * @return positionID The ID of the newly installed position.
     */
    function installAsset(
        PositionSource _source,
        address _owner,
        uint256 _assetId,
        uint8 _portfolio
    ) external returns (uint256 positionID);

    /**
     * @notice enables the user to exit a set of positions by providing collateral accounts to close along with debt accounts to pay off.
     * note its possible if the entity trying to exit this position does not correctly order the positions, the exit will fail.
     * @dev model taken from the universal router in uniswap v3.
     * @param commands The calldata for the commands to dispatch in order of execution.
     * @param inputs The calldata for the inputs to the commands.
     * @param _portfolio The portfolio to exit from.
     */
    function exit(bytes calldata commands, bytes[] calldata inputs, uint8 _portfolio) external;

    /**
     * @notice Liquidate a portfolio by supplying tokens to the Position Manager.
     * The liquidator can either take on positions or resolve them during liquidation.
     * 1. Normal Liquidation: the assets received are removed from the protocol producers
     * and distributed to the liquidator.
     * 2. Reassignment Liquidation: the assets received by the liquidator are retained by the protocol
     * but reassigned to the liquidator's portfolio.
     * @dev Calldata determines the type of liquidation for each position.
     */
    function liquidate(
        LiquidatePortfolio[] calldata _in,
        LiquidatePortfolio[] calldata _out,
        LiquidateParams calldata _params
    ) external;

    /**
        @notice a fuction used by producers to request funds from the position manager during position resolution.
        @dev should only be callable by a producer.
     */
    function request(address[] memory tokens, uint256[] memory amounts) external;

    /**
     * @notice Queries the value of a portfolio in native tokens.
     * @param _portfolioId The portfolio to query.
     * @return assets The assets in the portfolio.
     */
    function queryValuesNative(uint256 _portfolioId) external returns (Record[] memory assets);

    /**
     * @notice Queries the value of a portfolio in USD.
     * @param _portfolioId The portfolio to query.
     * @return portfolio The value of the assets in the portfolio in USD.
     */
    function queryValuesUSD(uint256 _portfolioId) external returns (PortfolioData memory portfolio);
}