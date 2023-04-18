// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Positions {
    bytes32 constant PIGGY_FACTORY_STORAGE_POSITION = keccak256("diamond.standard.Piggy.factory.storage");
    bytes32 constant PIGGY_REFERRAL_SYSTEM_STORAGE_POSITION = keccak256("diamond.standard.piggy.referral.system.storage");
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../../../modules/piggy-factory-module/services/piggybank.service.sol";

library PiggyFactorySchema {
    struct PiggyFactoryStorage {
        address[] banks;
        mapping(address => address[]) individualBanks;
        address protocolAddress;
        bool protocolAddressAdded;
        address proxy;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library PiggyBankErrors {
    error NOT_OWNER();
    error INIT_CALLED();
    error ADDRESS_ZERO();
    error NO_FUND_IN_BANK();
    error NOT_ZERO_AMOUNT();
    error CANT_STAKE_ZERO_AMOUNT();
    error LOCK_PERIOD_NOT_REACHED();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library PiggyFactoryErrors {
    error PROTOCOL_ADDRESS_NOT_ADDED();
    error PROXY_ADDRESS_NOT_SET();
    error PROXY_ADDRESS_ALREADY_SET();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library PiggyBankEvents {

    event EthDeposit(uint indexed amount);
    event EthWithdraw(uint indexed amount);
    event StableTokenDeposit(address indexed tokenAddress, uint indexed amount);
    event StableTokenWithdraw(address indexed tokenAddress, uint indexed amount);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../modules/piggy-factory-module/services/piggybank.service.sol";

library PiggyFactoryEvents {
    event newClone(address indexed, uint256 indexed position, string indexed purpose);
    event protocolAddressUpdated(address indexed newAddress);
    event proxyAddressIsSet(address indexed proxy);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../std/diamond-cut-module/controllers/IDiamondCut.controller.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

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

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPiggyBank {
    function init(
        address ownerAddress,
        address _protocolAddress,
        uint256 _timeLock,
        string memory _savingPurpose
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPiggyFactory {
    function createBank(uint256 _timeLock, string memory _savingPurpose) external;

    function bankCount() external view returns (uint256 totalBank);

    function getBanks() external view returns (address[] memory allBanks);

    function getUserBanks(address _address) external view returns (address[] memory);

    function updateProtocolAddress(address _devAddress) external;

    function showProtocolAddress() external view returns (address addr);

    function isProtocolAddressSet() external view returns (bool);

    function setProxy(address _proxy) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PiggyFactoryProvider as provider} from "./providers/piggy-factory.provider.sol";
import {IPiggyFactory} from "./controllers/IPiggyFactory.controller.sol";

contract PiggyFactory is IPiggyFactory {
    /// @notice This function creates a new piggy bank for a user
    /// @dev This function uses minimal proxy to clone the proxy contract and it takes two parameters (_timeLock and _savingPurpose)
    /// @param _timeLock: This is the period of time amount deposited into this bank will be held (locked)
    /// @param _savingPurpose: The purpose of this saving
    function createBank(uint256 _timeLock, string memory _savingPurpose) external override {
        provider.createBank(_timeLock, _savingPurpose);
    }

    /// @notice This function updates the protocol address which is meant to receive fees and commissions
    /// @dev This function can only be called by the contract owner to update or set the protocol address
    /// @param _protocolAddress: Address of the protocol that receives fees and commissions
    function updateProtocolAddress(address _protocolAddress) external override {
        provider.updateProtocolAddress(_protocolAddress);
    }

    /// @notice This function sets the proxy address (address of the deployed piggy bank contract that will be cloned for each user)
    /// @dev This function can only be called by the contract owner to set the addres of the proxy contract (address of the piggy bank contract)
    /// @param _proxy: Address of the proxy (piggy bank) contract that will be cloned each time a user creates a piggy bank
    function setProxy(address _proxy) external override {
        provider.setProxy(_proxy);
    }

    /// @notice This function returns bank count
    /// @dev This is a view function the returns the total number of piggy banks that have been cloned
    function bankCount() external view override returns (uint256 totalBank) {
        totalBank = provider.bankCount();
    }

    /// @notice This function returns an array of banks addresses that has been cloned
    /// @dev This is a view function the returns an array of all the piggy banks that have been cloned
    function getBanks() external view override returns (address[] memory allBanks) {
        allBanks = provider.getBanks();
    }

    /// @notice This function returns an array of banks addresses that has been created by a user
    /// @dev This is a view function the returns an array of all the piggy banks that a user has created
    function getUserBanks(address _address) external view override returns (address[] memory) {
        return provider.getUserBanks(_address);
    }

    /// @notice This function returns the protocol address that was set
    /// @dev This is a view function the returns protocol address. It returns adddress(0) if protocol address is not set
    function showProtocolAddress() external view override returns (address addr) {
        addr = provider.showProtocolAddress();
    }

    /// @notice This function returns whether protocol address is set or not
    /// @dev This is a view function the returns a boolean value (true or false) whether the protocol address is set
    function isProtocolAddressSet() external view override returns (bool) {
        return provider.isProtocolAddressSet();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PiggyFactorySchema as Schema} from "../../../global/dto/schemas/piggyFactory.schema.sol";
import {Positions} from "../../../global/dto/positions.sol";
import {PiggyFactoryErrors as Errors} from "../../../global/errors/piggy-factory.errors.sol";
import {PiggyFactoryEvents as FactoryEvents} from "../../../global/events/piggy-factory.event.sol";
import {IERC20} from "../controllers/IERC20.controller.sol";
import {IPiggyBank} from "../controllers/IPiggyBank.controller.sol";
import {LibDiamond} from "../../../main/providers//LibDiamond.sol";

library PiggyFactoryProvider {
    function PiggyFactoryStorage() internal pure returns (Schema.PiggyFactoryStorage storage PFS) {
        bytes32 position = Positions.PIGGY_FACTORY_STORAGE_POSITION;

        assembly {
            PFS.slot := position
        }
    }

    //****************************//
    //       WRITE FUNCTIONS      //
    //****************************//

    function createBank(uint256 _timeLock, string memory _savingPurpose) internal returns (address proxy_) {
        Schema.PiggyFactoryStorage storage PFS = PiggyFactoryStorage();

        if (PFS.protocolAddressAdded == false) {
            revert Errors.PROTOCOL_ADDRESS_NOT_ADDED();
        }

        if (PFS.proxy == address(0)) {
            revert Errors.PROXY_ADDRESS_NOT_SET();
        }

        bytes20 targetInBytes = bytes20(PFS.proxy);

        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetInBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            proxy_ := create(0, clone, 0x37)
        }

        address ownerAddress = msg.sender;

        PFS.banks.push(proxy_);
        uint256 length = PFS.banks.length;
        PFS.individualBanks[msg.sender].push(proxy_);

        IPiggyBank(proxy_).init(ownerAddress, PFS.protocolAddress, _timeLock, _savingPurpose);

        emit FactoryEvents.newClone(proxy_, length, _savingPurpose);
    }

    function updateProtocolAddress(address _protocolAddress) internal {
        LibDiamond.enforceIsContractOwner();
        Schema.PiggyFactoryStorage storage PFS = PiggyFactoryStorage();
        PFS.protocolAddress = _protocolAddress;
        PFS.protocolAddressAdded = true;

        emit FactoryEvents.protocolAddressUpdated(_protocolAddress);
    }

    function setProxy(address _proxy) internal {
        LibDiamond.enforceIsContractOwner();
        Schema.PiggyFactoryStorage storage PFS = PiggyFactoryStorage();
        if (PFS.proxy != address(0)) {
            revert Errors.PROXY_ADDRESS_ALREADY_SET();
        }

        PFS.proxy = _proxy;

        emit FactoryEvents.proxyAddressIsSet(_proxy);
    }

    //****************************//
    //       VIEW FUNCTIONS       //
    //****************************//

    function bankCount() internal view returns (uint256 totalBank) {
        Schema.PiggyFactoryStorage storage PFS = PiggyFactoryStorage();
        totalBank = PFS.banks.length;
    }

    function getBanks() internal view returns (address[] memory allBanks) {
        Schema.PiggyFactoryStorage storage PFS = PiggyFactoryStorage();
        allBanks = PFS.banks;
    }

    function getUserBanks(address _address) internal view returns (address[] memory) {
        Schema.PiggyFactoryStorage storage PFS = PiggyFactoryStorage();
        return PFS.individualBanks[_address];
    }

    function showProtocolAddress() internal view returns (address addr) {
        Schema.PiggyFactoryStorage storage PFS = PiggyFactoryStorage();
        addr = PFS.protocolAddress;
    }

    function isProtocolAddressSet() internal view returns (bool) {
        Schema.PiggyFactoryStorage storage PFS = PiggyFactoryStorage();

        return PFS.protocolAddressAdded;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PiggyBankErrors as Error} from "../../../global/errors/piggy-bank.errors.sol";
import {IERC20} from "../../piggy-factory-module/controllers/IERC20.controller.sol";

import {PiggyBankEvents as PiggyEvents} from "../../../global/events/piggy-bank.event.sol";

contract PiggyBank {
    // ============================
    // STATE VARIABLE
    // ============================

    string public savingPurpose;
    address public owner;
    address protocolAddr;
    uint256 public timeLock;
    bool public withdrawn;
    bool initCalled;

    // ============================
    // CONSTRUCTOR
    // ============================

    function init(
        address ownerAddress,
        address _protocolAdd,
        uint256 _timeLock,
        string memory _savingPurpose
    ) external {
        if (initCalled == true) {
            revert Error.INIT_CALLED();
        }
        owner = ownerAddress;
        protocolAddr = _protocolAdd;
        timeLock = block.timestamp + (_timeLock * 1 days);
        savingPurpose = _savingPurpose;
        initCalled = true;
    }

    //****************************//
    //       WRITE FUNCTIONS      //
    //***************************//

    /// @notice This function is used to deposit Native token of the blockchain
    /// @dev This is a payable function that deposites native token to the contract

    function deposit() external payable {
        if (msg.value <= 0) {
            revert Error.NOT_ZERO_AMOUNT();
        }

        emit PiggyEvents.EthDeposit(msg.value);
    }

    /// @notice This function is called when the lock period is over
    /// @dev This function is guided by the lock time and cannot be called until the lock period is over

    function safeWithdraw(address _addr) external {
        if (msg.sender != owner) {
            revert Error.NOT_OWNER();
        }

        if (timeLock > block.timestamp) {
            revert Error.LOCK_PERIOD_NOT_REACHED();
        }

        if (_addr == address(0)) {
            revert Error.ADDRESS_ZERO();
        }

        if (address(this).balance <= 0) {
            revert Error.NO_FUND_IN_BANK();
        }

        uint256 bal = address(this).balance;
        uint256 commission = savingCommission();

        uint256 withdrawable = bal - commission;

        (bool ownerWithdrawn, ) = payable(_addr).call{value: withdrawable}("");
        (bool protocolAddrWithdrawn, ) = payable(protocolAddr).call{value: commission}("");

        if (ownerWithdrawn == true && protocolAddrWithdrawn == true) {
            withdrawn = true;

            emit PiggyEvents.EthWithdraw(withdrawable);
        }
    }

    /// @notice This function is called before the lock up period ended during emergency
    /// @dev function called for emergency withdrawal and 15% is withdrawn as chanrges (for penal fee)

    function emergencyWithdrawal(address _addr) external {
        if (msg.sender != owner) {
            revert Error.NOT_OWNER();
        }

        if (_addr == address(0)) {
            revert Error.ADDRESS_ZERO();
        }

        uint256 contractBal = address(this).balance;
        uint256 penalFee = penalPercentage();

        uint256 withdrawBal = contractBal - penalFee;

        (bool ownerWithdrawn, ) = payable(_addr).call{value: withdrawBal}("");

        if (ownerWithdrawn == true) {
            protocolWithdraw(penalFee);

            withdrawn = true;

            emit PiggyEvents.EthWithdraw(withdrawBal);
        }
    }

    /// @notice This function deposits ERC20 token into contract
    /// @dev This function takes in the token address and amount to deposit ERC20 token to the contarct
    /// @param _tokenAddress: ERC20 token address of token to be deposited
    /// @param _amount: Amount of ERC20 token to be deposited into the contract

    function depositToken(address _tokenAddress, uint256 _amount) public {
        if (_amount <= 0) {
            revert Error.CANT_STAKE_ZERO_AMOUNT();
        }

        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);

        emit PiggyEvents.StableTokenDeposit(_tokenAddress, _amount);
    }

    /// @notice This function can only be called after the speculated lock period
    /// @dev Function is guided be the lock period and cannot be be unlocked until the lock period
    /// @param _tokenAddress: Address of ERC20 token to be withdrawn

    function safeWithdrawToken(address _tokenAddress, address _addr) external {
        if (msg.sender != owner) {
            revert Error.NOT_OWNER();
        }

        if (block.timestamp < timeLock) {
            revert Error.LOCK_PERIOD_NOT_REACHED();
        }

        if (_addr == address(0)) {
            revert Error.ADDRESS_ZERO();
        }

        uint256 conractTokenBalance = getTokenBalance(_tokenAddress);
        uint256 commission = savingTokenCommission(_tokenAddress);
        uint256 transferToken = conractTokenBalance - commission;

        bool status = IERC20(_tokenAddress).transfer(_addr, transferToken);

        if (status == true) {
            protocolWithdrawToken(_tokenAddress, commission);

            withdrawn = true;

            emit PiggyEvents.StableTokenWithdraw(_tokenAddress, transferToken);
        }
    }

    /// @notice This function is called to withdraw ERC20 token before the lock period and a penal fee is paid
    /// @dev uses tokenPenalPercentage to calculate the penal fee which is deducted as penal fee
    /// @param _tokenAddress: Address of ERC20 token to be withdrawn

    function emergencyWithdrawalToken(address _tokenAddress, address _addr) external {
        if (msg.sender != owner) {
            revert Error.NOT_OWNER();
        }

        if (_addr == address(0)) {
            revert Error.ADDRESS_ZERO();
        }

        uint256 contractTokenBalance = getTokenBalance(_tokenAddress);
        uint256 penalFee = tokenPenalPercentage(_tokenAddress);
        uint256 transferable = contractTokenBalance - penalFee;

        bool status = IERC20(_tokenAddress).transfer(_addr, transferable);

        if (status == true) {
            protocolWithdrawToken(_tokenAddress, penalFee);

            withdrawn = true;

            emit PiggyEvents.StableTokenWithdraw(_tokenAddress, transferable);
        }
    }

    //****************************//
    //       VIEW FUNCTIONS      //
    //***************************//

    /// @notice Function returns contarct Erc20 balance
    /// @dev Uses IERC20 interface to achieve this
    /// @param _token: Address of ERC20 token

    function getTokenBalance(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    /// @notice Gets the contract balance of native token
    function getContractBalance() external view returns (uint256 bal) {
        bal = address(this).balance;
    }

    function returnUnlockTime() external view returns (uint256) {
        return timeLock;
    }

    /// @notice Function calcuates the saving commision during withdrawal
    /// @dev Calculation involves 1% of the savings during withdrawal
    function savingCommission() private view returns (uint256 commission) {
        commission = (address(this).balance * 100) / 10000;
    }

    /// @notice Function calcuates Penal fee for native token withrawal
    /// @dev Calculation involves 15% of the savings during withdrawal of native token
    function showEthPenalPercentage() external view returns (uint256 percent) {
        percent = (address(this).balance * 1500) / 10000;
    }

    /// @notice Function calcuates Penal fee for ERC20 token withrawal
    /// @dev Calculation involves 15% of the savings during withdrawal of ERC20 token
    function showTokenPenalPercentage(address _token) external view returns (uint256 percent) {
        uint256 tokenBalance = getTokenBalance(_token);
        percent = (tokenBalance * 1500) / 10000;
    }

    //****************************//
    //     PRIVATE FUNCTIONS      //
    //***************************//

    /// @notice this function allows protocol to withdraw the percentage gotten after emergency funds have been withdrawn
    /// @dev Called to transfer the native token for penal fee
    /// @param _penalFee: Total penal funds calculated
    function protocolWithdraw(uint256 _penalFee) internal {
        if (protocolAddr == address(0)) {
            revert Error.ADDRESS_ZERO();
        }
        (bool protocolWithdrawn, ) = payable(protocolAddr).call{value: _penalFee}("");
    }

    /// @notice this function calculates the penal fee for emergency withdraw
    /// @dev Calculate penal fee for native token

    function penalPercentage() private view returns (uint256 percent) {
        percent = (address(this).balance * 1500) / 10000;
    }

    /// @notice this function calculates the saving fee
    /// @dev Calculates saving fee which is 1%
    /// @param _token: Erc20 token address
    function savingTokenCommission(address _token) private view returns (uint256 commission) {
        uint256 tokenBalance = getTokenBalance(_token);
        commission = (tokenBalance * 100) / 100000;
    }

    /// @notice Calculates total penal pecentage
    /// @param _token: ERC20 token address for withdrawal
    function tokenPenalPercentage(address _token) private view returns (uint256 percent) {
        uint256 tokenBalance = getTokenBalance(_token);
        percent = (tokenBalance * 1500) / 10000;
    }

    /// @notice this function is called to transfer Erc20 token
    /// @param _token: Erc20 token address
    /// @param _amount: amount of token to be transfered
    function protocolWithdrawToken(address _token, uint256 _amount) private {
        IERC20(_token).transfer(protocolAddr, _amount);
    }

    receive() external payable {
        emit PiggyEvents.EthDeposit(msg.value);
    }
}