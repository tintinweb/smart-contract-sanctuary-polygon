// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: GPL-2.0

pragma solidity 0.7.6;
pragma abicoder v2;

import '../../interfaces/IAToken.sol';
import '../../interfaces/ILendingPool.sol';
import '../../interfaces/actions/IAaveWithdraw.sol';
import '../utils/Storage.sol';

///@notice action to withdraw tokens from aave protocol
contract AaveWithdraw is IAaveWithdraw {
    ///@notice emitted when a withdraw from aave is made
    ///@param positionManager address of aave positionManager which withdrew
    ///@param token token address
    ///@param amount amount withdrawn
    ///@param returnTokensToUser true if withdrawn tokens are sent to positionManager owner
    ///@param closedPosition true if user has withdrawn the whole position
    event WithdrawnFromAave(
        address indexed positionManager,
        address token,
        uint256 amount,
        bool returnTokensToUser,
        bool closedPosition
    );

    ///@notice withdraw from aave some token amount
    ///@param tokenFromAave token address of the token to withdraw from Aave
    ///@param tokenId position to withdraw from
    ///@param partToWithdraw percentage of token to withdraw in base points
    ///@param returnTokensToUser true if withdrawn tokens are sent to positionManager owner
    ///@return amountWithdrawn amount of token withdrawn from aave
    function withdrawFromAave(
        address tokenFromAave,
        uint256 tokenId,
        uint256 partToWithdraw,
        bool returnTokensToUser
    ) external override returns (uint256 amountWithdrawn) {
        StorageStruct storage Storage = PositionManagerStorage.getStorage();

        uint256 shares = uint256(
            PositionManagerStorage.getDynamicStorageValue(keccak256(abi.encodePacked(tokenId, 'aave_shares')))
        );
        uint256 totalShares = uint256(
            PositionManagerStorage.getDynamicStorageValue(
                keccak256(abi.encodePacked(tokenFromAave, 'aave_totalShares'))
            )
        );

        require(shares != 0, 'AWN');
        require(partToWithdraw != 0 && partToWithdraw <= 10_000, 'AW0');

        amountWithdrawn = ILendingPool(Storage.aaveAddressHolder.lendingPoolAddress()).withdraw(
            tokenFromAave,
            (_getAmount(tokenFromAave, shares, totalShares) * partToWithdraw) / 10_000,
            returnTokensToUser ? Storage.owner : address(this)
        );

        _updateShares(tokenFromAave, tokenId, partToWithdraw, shares, totalShares);
        emit WithdrawnFromAave(
            address(this),
            tokenFromAave,
            amountWithdrawn,
            returnTokensToUser,
            partToWithdraw == 10_000
        );
    }

    ///@notice gets balance of aToken associated to this position id
    ///@param tokenFromAave underlying token addrress
    ///@param shares shares of the position
    ///@param totalShares total shares of the underlying token
    ///@return amount of underlying token
    function _getAmount(
        address tokenFromAave,
        uint256 shares,
        uint256 totalShares
    ) internal view returns (uint256) {
        IAToken aToken = IAToken(
            ILendingPool(PositionManagerStorage.getStorage().aaveAddressHolder.lendingPoolAddress())
                .getReserveData(tokenFromAave)
                .aTokenAddress
        );

        return (aToken.balanceOf(address(this)) * shares) / totalShares;
    }

    ///@notice remove shares associated to withdrawn tokens and remove tokenID from aave reserves
    ///@param token address of token withdrawn
    ///@param tokenId of the withdrawn position
    ///@param partToWithdraw percentage of token to withdraw in base points
    ///@param shares shares of the position
    ///@param totalShares total shares of the underlying token
    function _updateShares(
        address token,
        uint256 tokenId,
        uint256 partToWithdraw,
        uint256 shares,
        uint256 totalShares
    ) internal {
        uint256 sharesWithdrawn = (shares * partToWithdraw) / 10_000;

        PositionManagerStorage.setDynamicStorageValue(
            keccak256(abi.encodePacked(token, 'aave_totalShares')),
            bytes32(totalShares - sharesWithdrawn)
        );

        if (partToWithdraw == 10_000) {
            PositionManagerStorage.setDynamicStorageValue(
                keccak256(abi.encodePacked(tokenId, 'aave_shares')),
                bytes32(0)
            );
        } else {
            PositionManagerStorage.setDynamicStorageValue(
                keccak256(abi.encodePacked(tokenId, 'aave_shares')),
                bytes32(shares - sharesWithdrawn)
            );
        }
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.7.6;
pragma abicoder v2;

import '../../interfaces/IPositionManager.sol';
import '../../interfaces/IUniswapAddressHolder.sol';
import '../../interfaces/IAaveAddressHolder.sol';
import '../../interfaces/IDiamondCut.sol';
import '../../interfaces/IRegistry.sol';

struct FacetAddressAndPosition {
    address facetAddress;
    uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
}

struct FacetFunctionSelectors {
    bytes4[] functionSelectors;
    uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
}

struct AavePositions {
    uint256 id;
    address tokenToAave;
}

struct StorageStruct {
    // maps function selector to the facet address and
    // the position of the selector in the facetFunctionSelectors.selectors array
    mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
    // maps facet addresses to function selectors
    mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
    // facet addresses
    address[] facetAddresses;
    IUniswapAddressHolder uniswapAddressHolder;
    address owner;
    IRegistry registry;
    IAaveAddressHolder aaveAddressHolder;
    mapping(bytes32 => bytes32) storageVars;
}

library PositionManagerStorage {
    bytes32 private constant key = keccak256('position-manager-storage-location');

    ///@notice get the storage from memory location
    ///@return s the storage struct
    function getStorage() internal pure returns (StorageStruct storage s) {
        bytes32 k = key;
        assembly {
            s.slot := k
        }
    }

    ///@notice emitted when a contract changes ownership
    ///@param previousOwner previous owner of the contract
    ///@param newOwner new owner of the contract
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    ///@notice set the owner field on the storage struct
    ///@param _newOwner new owner of the storage struct
    function setContractOwner(address _newOwner) internal {
        require(_newOwner != address(0), 'SNO');
        StorageStruct storage ds = getStorage();
        address previousOwner = ds.owner;
        ds.owner = _newOwner;
        if (_newOwner != previousOwner) {
            emit OwnershipTransferred(previousOwner, _newOwner);
        }
    }

    ///@notice make sure that a function is called by the PositionManagerFactory contract
    function enforceIsGovernance() internal view {
        StorageStruct storage ds = getStorage();
        require(msg.sender == ds.registry.positionManagerFactoryAddress(), 'SMF');
    }

    ///@notice emitted when a facet is cut into the diamond
    ///@param _diamondCut facet cut
    ///@param _init diamond cut init address
    ///@param _calldata facet cut calldata
    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    ///@notice Internal function version of diamondCut
    ///@param _diamondCut facet cut
    ///@param _init diamond cut init address
    ///@param _calldata facet cut calldata
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        uint256 _diamondCutLength = _diamondCut.length;
        for (uint256 facetIndex; facetIndex < _diamondCutLength; ++facetIndex) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert('SIF');
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    ///@notice Add functions to facet
    ///@param _facetAddress address of the facet
    ///@param _functionSelectors function selectors to add
    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length != 0, 'SNS');
        StorageStruct storage ds = getStorage();
        require(_facetAddress != address(0), 'SA0');
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);

        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }

        uint256 _functionSelectorsLength = _functionSelectors.length;
        for (uint256 selectorIndex; selectorIndex < _functionSelectorsLength; ++selectorIndex) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), 'SFE');
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    ///@notice Add facet by address
    ///@param ds storage struct
    ///@param _facetAddress address of the facet
    function addFacet(StorageStruct storage ds, address _facetAddress) internal {
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }

    ///@notice Add single function to facet
    ///@param ds storage struct
    ///@param _selector function selector to add
    ///@param _selectorPosition position of the function selector in the facetFunctionSelectors array
    function addFunction(
        StorageStruct storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    ///@notice Remove single function from facet
    ///@param ds storage struct
    ///@param _facetAddress address of the facet
    ///@param _selector function selector to remove
    function removeFunction(
        StorageStruct storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        require(_facetAddress != address(0), 'SRE');
        require(_facetAddress != address(this), 'SRI');

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

    ///@notice Replace functions in facet
    ///@param _facetAddress address of the facet
    ///@param _functionSelectors function selectors to replace
    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length != 0, 'SRF');
        StorageStruct storage ds = getStorage();
        require(_facetAddress != address(0), 'SR0');
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);

        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }

        uint256 _functionSelectorsLength = _functionSelectors.length;
        for (uint256 selectorIndex; selectorIndex < _functionSelectorsLength; ++selectorIndex) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;

            require(oldFacetAddress != _facetAddress, 'SRR');

            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    ///@notice remove functions in facet
    ///@param _facetAddress address of the facet
    ///@param _functionSelectors function selectors to remove
    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length != 0, 'SES');

        StorageStruct storage ds = getStorage();

        require(_facetAddress == address(0), 'SE0');

        uint256 _functionSelectorsLength = _functionSelectors.length;
        for (uint256 selectorIndex; selectorIndex < _functionSelectorsLength; ++selectorIndex) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    ///@notice Initialize the diamond cut
    ///@param _init delegatecall address
    ///@param _calldata delegatecall data
    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, 'SI0');
        } else {
            require(_calldata.length != 0, 'SIC');

            (bool success, bytes memory error) = _init.delegatecall(_calldata);

            if (!success) {
                if (error.length != 0) {
                    revert(string(error));
                } else {
                    revert('SIR');
                }
            }
        }
    }

    ///@notice check to verify that the key is valid and already whitelisted by governance
    ///@param hashedKey key to check
    modifier verifyKey(bytes32 hashedKey) {
        StorageStruct storage ds = getStorage();

        bytes32 storageVariableHash = ds.storageVars[hashedKey];

        require(storageVariableHash == bytes32(uint256(1)), 'SDK');
        _;
    }

    ///@notice get a specific slot of memory by the given key and read the first 32 bytes
    ///@param hashedKey key to read from
    function getDynamicStorageValue(bytes32 hashedKey) internal view verifyKey(hashedKey) returns (bytes32 value) {
        assembly {
            value := sload(hashedKey)
        }
    }

    ///@dev supposing we've already set the key on the mapping, we can't insert a wrong key
    ///@notice set a specific slot of memory by the given key and write the first 32 bytes
    ///@param hashedKey key to write to
    ///@param value value to write
    function setDynamicStorageValue(bytes32 hashedKey, bytes32 value) internal verifyKey(hashedKey) {
        assembly {
            sstore(hashedKey, value)
        }
    }

    ///@notice add a new hashedKey to the mapping in storage, sort of whitelist
    ///@param hashedKey key to add to the mapping
    function addDynamicStorageKey(bytes32 hashedKey) internal {
        StorageStruct storage ds = getStorage();

        bytes32 storageVariableHash = ds.storageVars[hashedKey];

        ///@dev return if the key already exists
        if (storageVariableHash != bytes32(0)) return;

        ds.storageVars[hashedKey] = bytes32(uint256(1));
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

library DataTypes {
    // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: Reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60-63: reserved
        //bit 64-79: reserve factor
        uint256 data;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IScaledBalanceToken} from './IScaledBalanceToken.sol';

interface IAToken is IERC20, IScaledBalanceToken {
    /**
     * @dev Emitted after the mint action
     * @param from The address performing the mint
     * @param value The amount being
     * @param index The new liquidity index of the reserve
     **/
    event Mint(address indexed from, uint256 value, uint256 index);

    /**
     * @dev Mints `amount` aTokens to `user`
     * @param user The address receiving the minted tokens
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     * @return `true` if the the previous balance of the user was 0
     */
    function mint(
        address user,
        uint256 amount,
        uint256 index
    ) external returns (bool);

    /**
     * @dev Emitted after aTokens are burned
     * @param from The owner of the aTokens, getting them burned
     * @param target The address that will receive the underlying
     * @param value The amount being burned
     * @param index The new liquidity index of the reserve
     **/
    event Burn(address indexed from, address indexed target, uint256 value, uint256 index);

    /**
     * @dev Emitted during the transfer action
     * @param from The user whose tokens are being transferred
     * @param to The recipient
     * @param value The amount being transferred
     * @param index The new liquidity index of the reserve
     **/
    event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);

    /**
     * @dev Burns aTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * @param user The owner of the aTokens, getting them burned
     * @param receiverOfUnderlying The address that will receive the underlying
     * @param amount The amount being burned
     * @param index The new liquidity index of the reserve
     **/
    function burn(
        address user,
        address receiverOfUnderlying,
        uint256 amount,
        uint256 index
    ) external;

    /**
     * @dev Mints aTokens to the reserve treasury
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     */
    function mintToTreasury(uint256 amount, uint256 index) external;

    /**
     * @dev Transfers aTokens in the event of a borrow being liquidated, in case the liquidators reclaims the aToken
     * @param from The address getting liquidated, current owner of the aTokens
     * @param to The recipient
     * @param value The amount of tokens getting transferred
     **/
    function transferOnLiquidation(
        address from,
        address to,
        uint256 value
    ) external;

    /**
     * @dev Transfers the underlying asset to `target`. Used by the LendingPool to transfer
     * assets in borrow(), withdraw() and flashLoan()
     * @param user The recipient of the aTokens
     * @param amount The amount getting transferred
     * @return The amount transferred
     **/
    function transferUnderlyingTo(address user, uint256 amount) external returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0

pragma solidity 0.7.6;

interface IAaveAddressHolder {
    ///@notice default getter for lendingPoolAddress
    ///@return address The address of the lending pool from aave
    function lendingPoolAddress() external view returns (address);

    ///@notice Set the address of lending pool
    ///@param newAddress new address of the lending pool from aave
    function setLendingPoolAddress(address newAddress) external;

    ///@notice Set the address of the registry
    ///@param newAddress The address of the registry
    function setRegistry(address newAddress) external;
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.7.6;
pragma abicoder v2;

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import {ILendingPoolAddressesProvider} from './ILendingPoolAddressesProvider.sol';
import {DataTypes} from './DataTypes.sol';

interface ILendingPool {
    /**
     * @dev Emitted on deposit()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the deposit
     * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
     * @param amount The amount deposited
     * @param referral The referral code used
     **/
    event Deposit(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on withdraw()
     * @param reserve The address of the underlyng asset being withdrawn
     * @param user The address initiating the withdrawal, owner of aTokens
     * @param to Address that will receive the underlying
     * @param amount The amount to be withdrawn
     **/
    event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
     * @param reserve The address of the underlying asset being borrowed
     * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
     * initiator of the transaction on flashLoan()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The amount borrowed out
     * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
     * @param borrowRate The numeric rate at which the user has borrowed
     * @param referral The referral code used
     **/
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 borrowRateMode,
        uint256 borrowRate,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on repay()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param repayer The address of the user initiating the repay(), providing the funds
     * @param amount The amount repaid
     **/
    event Repay(address indexed reserve, address indexed user, address indexed repayer, uint256 amount);

    /**
     * @dev Emitted on swapBorrowRateMode()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user swapping his rate mode
     * @param rateMode The rate mode that the user wants to swap to
     **/
    event Swap(address indexed reserve, address indexed user, uint256 rateMode);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on rebalanceStableBorrowRate()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user for which the rebalance has been executed
     **/
    event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on flashLoan()
     * @param target The address of the flash loan receiver contract
     * @param initiator The address initiating the flash loan
     * @param asset The address of the asset being flash borrowed
     * @param amount The amount flash borrowed
     * @param premium The fee flash borrowed
     * @param referralCode The referral code used
     **/
    event FlashLoan(
        address indexed target,
        address indexed initiator,
        address indexed asset,
        uint256 amount,
        uint256 premium,
        uint16 referralCode
    );

    /**
     * @dev Emitted when the pause is triggered.
     */
    event Paused();

    /**
     * @dev Emitted when the pause is lifted.
     */
    event Unpaused();

    /**
     * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
     * LendingPoolCollateral manager using a DELEGATECALL
     * This allows to have the events in the generated ABI for LendingPool.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
     * @param liquidator The address of the liquidator
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    /**
     * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
     * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
     * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
     * gets added to the LendingPool ABI
     * @param reserve The address of the underlying asset of the reserve
     * @param liquidityRate The new liquidity rate
     * @param stableBorrowRate The new stable borrow rate
     * @param variableBorrowRate The new variable borrow rate
     * @param liquidityIndex The new liquidity index
     * @param variableBorrowIndex The new variable borrow index
     **/
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     **/
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
     * @param asset The address of the underlying asset borrowed
     * @param rateMode The rate mode that the user wants to swap to
     **/
    function swapBorrowRateMode(address asset, uint256 rateMode) external;

    /**
     * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
     * - Users can be rebalanced if the following conditions are satisfied:
     *     1. Usage ratio is above 95%
     *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
     *        borrowed at a stable rate and depositors are not earning enough
     * @param asset The address of the underlying asset borrowed
     * @param user The address of the user to be rebalanced
     **/
    function rebalanceStableBorrowRate(address asset, address user) external;

    /**
     * @dev Allows depositors to enable/disable a specific deposited asset as collateral
     * @param asset The address of the underlying asset deposited
     * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
     **/
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

    /**
     * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    /**
     * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
     * For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
     * @param assets The addresses of the assets being flash-borrowed
     * @param amounts The amounts amounts being flash-borrowed
     * @param modes Types of the debt to open if the flash loan is not returned:
     *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
     *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @dev Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralETH the total collateral in ETH of the user
     * @return totalDebtETH the total debt in ETH of the user
     * @return availableBorrowsETH the borrowing power left of the user
     * @return currentLiquidationThreshold the liquidation threshold of the user
     * @return ltv the loan to value of the user
     * @return healthFactor the current health factor of the user
     **/
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function initReserve(
        address reserve,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress) external;

    function setConfiguration(address reserve, uint256 configuration) external;

    /**
     * @dev Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     **/
    function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @dev Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     **/
    function getUserConfiguration(address user) external view returns (DataTypes.UserConfigurationMap memory);

    /**
     * @dev Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
     * @dev Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

    /**
     * @dev Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromAfter,
        uint256 balanceToBefore
    ) external;

    function getReservesList() external view returns (address[] memory);

    function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

    function setPause(bool val) external;

    function paused() external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
    event MarketIdSet(string newMarketId);
    event LendingPoolUpdated(address indexed newAddress);
    event ConfigurationAdminUpdated(address indexed newAddress);
    event EmergencyAdminUpdated(address indexed newAddress);
    event LendingPoolConfiguratorUpdated(address indexed newAddress);
    event LendingPoolCollateralManagerUpdated(address indexed newAddress);
    event PriceOracleUpdated(address indexed newAddress);
    event LendingRateOracleUpdated(address indexed newAddress);
    event ProxyCreated(bytes32 id, address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

    function getMarketId() external view returns (string memory);

    function setMarketId(string calldata marketId) external;

    function setAddress(bytes32 id, address newAddress) external;

    function setAddressAsProxy(bytes32 id, address impl) external;

    function getAddress(bytes32 id) external view returns (address);

    function getLendingPool() external view returns (address);

    function setLendingPoolImpl(address pool) external;

    function getLendingPoolConfigurator() external view returns (address);

    function setLendingPoolConfiguratorImpl(address configurator) external;

    function getLendingPoolCollateralManager() external view returns (address);

    function setLendingPoolCollateralManager(address manager) external;

    function getPoolAdmin() external view returns (address);

    function setPoolAdmin(address admin) external;

    function getEmergencyAdmin() external view returns (address);

    function setEmergencyAdmin(address admin) external;

    function getPriceOracle() external view returns (address);

    function setPriceOracle(address priceOracle) external;

    function getLendingRateOracle() external view returns (address);

    function setLendingRateOracle(address lendingRateOracle) external;
}

// SPDX-License-Identifier: GPL-2.0

pragma solidity 0.7.6;
pragma abicoder v2;

interface IPositionManager {
    struct ModuleInfo {
        bool isActive;
        bytes32 data;
    }

    struct AaveReserve {
        mapping(uint256 => uint256) positionShares;
        mapping(uint256 => uint256) tokenIds;
        uint256 sharesEmitted;
    }

    function toggleModule(
        uint256 tokenId,
        address moduleAddress,
        bool activated
    ) external;

    function setModuleData(
        uint256 tokenId,
        address moduleAddress,
        bytes32 data
    ) external;

    function getModuleInfo(uint256 _tokenId, address _moduleAddress)
        external
        view
        returns (bool isActive, bytes32 data);

    function withdrawERC20(address tokenAddress) external;

    function middlewareUniswap(uint256 tokenId, uint256 oldTokenId) external;

    function getAllUniPositions() external view returns (uint256[] memory);

    function getAaveDataFromTokenId(uint256 tokenId) external returns (uint256, address);

    function getOwner() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.7.6;
pragma abicoder v2;

interface IRegistry {
    struct Entry {
        address contractAddress;
        bool activated;
        bytes32 defaultData;
        bool activatedByDefault;
    }

    ///@notice return the address of PositionManagerFactory
    ///@return address of PositionManagerFactory
    function positionManagerFactoryAddress() external view returns (address);

    ///@notice return the address of Governance
    ///@return address of Governance
    function governance() external view returns (address);

    ///@notice return the max twap deviation
    ///@return int24 max twap deviation
    function maxTwapDeviation() external view returns (int24);

    ///@notice return the twap duration
    ///@return uint32 twap duration
    function twapDuration() external view returns (uint32);

    ///@notice return the address of Governance
    ///@return address of Governance
    function getModuleKeys() external view returns (bytes32[] memory);

    ///@notice adds a new whitelisted keeper
    ///@param _keeper address of the new keeper
    function addKeeperToWhitelist(address _keeper) external;

    ///@notice remove a whitelisted keeper
    ///@param _keeper address of the keeper to remove
    function removeKeeperFromWhitelist(address _keeper) external;

    ///@notice checks if the address is whitelisted as a keeper
    ///@param _keeper address to check
    ///@return bool true if the address is withelisted, false otherwise
    function whitelistedKeepers(address _keeper) external view returns (bool);

    function getModuleInfo(bytes32 _id)
        external
        view
        returns (
            address,
            bool,
            bytes32,
            bool
        );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

interface IScaledBalanceToken {
    /**
     * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
     * updated stored balance divided by the reserve's liquidity index at the moment of the update
     * @param user The user whose balance is calculated
     * @return The scaled balance of the user
     **/
    function scaledBalanceOf(address user) external view returns (uint256);

    /**
     * @dev Returns the scaled balance of the user and the scaled total supply.
     * @param user The address of the user
     * @return The scaled balance of the user
     * @return The scaled balance and the scaled total supply
     **/
    function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

    /**
     * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
     * @return The scaled total supply
     **/
    function scaledTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0

pragma solidity 0.7.6;
pragma abicoder v2;

interface IUniswapAddressHolder {
    ///@notice default getter for nonfungiblePositionManagerAddress
    ///@return address The address of the non fungible position manager
    function nonfungiblePositionManagerAddress() external view returns (address);

    ///@notice default getter for uniswapV3FactoryAddress
    ///@return address The address of the Uniswap V3 factory
    function uniswapV3FactoryAddress() external view returns (address);

    ///@notice default getter for swapRouterAddress
    ///@return address The address of the swap router
    function swapRouterAddress() external view returns (address);

    ///@notice Set the address of nonfungible position manager
    ///@param newAddress new address of nonfungible position manager
    function setNonFungibleAddress(address newAddress) external;

    ///@notice Set the address of the Uniswap V3 factory
    ///@param newAddress new address of the Uniswap V3 factory
    function setFactoryAddress(address newAddress) external;

    ///@notice Set the address of uniV3 swap router
    ///@param newAddress new address of univ3 swap router
    function setSwapRouterAddress(address newAddress) external;

    ///@notice Set the address of the registry
    ///@param newAddress The address of the registry
    function setRegistry(address newAddress) external;
}

// SPDX-License-Identifier: GPL-2.0

pragma solidity 0.7.6;
pragma abicoder v2;

interface IAaveWithdraw {
    ///@notice withdraw from aave some token amount
    ///@param id position to withdraw from
    ///@param partToWithdraw percentage of token to withdraw in base points
    ///@param returnTokensToUser true if withdrawn tokens are sent to positionManager owner
    ///@return amountWithdrawn amount of token withdrawn from aave
    function withdrawFromAave(
        address tokenFromAave,
        uint256 id,
        uint256 partToWithdraw,
        bool returnTokensToUser
    ) external returns (uint256 amountWithdrawn);
}