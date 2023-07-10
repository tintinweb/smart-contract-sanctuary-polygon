/*
  Copyright 2021 Set Labs Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  SPDX-License-Identifier: Apache-2.0
*/
pragma solidity 0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface IAToken is IERC20 {
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

/*
  Copyright 2021 Set Labs Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  SPDX-License-Identifier: Apache-2.0
*/
pragma solidity 0.8.19;

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

/*
  Copyright 2021 Set Labs Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/
pragma solidity 0.8.19;

import { ILendingPoolAddressesProvider } from "./ILendingPoolAddressesProvider.sol";

interface IProtocolDataProvider {
  struct TokenData {
    string symbol;
    address tokenAddress;
  }

  function ADDRESSES_PROVIDER() external view returns (ILendingPoolAddressesProvider);
  function getAllReservesTokens() external view returns (TokenData[] memory);
  function getAllATokens() external view returns (TokenData[] memory);
  function getReserveConfigurationData(address asset) external view returns (uint256 decimals, uint256 ltv, uint256 liquidationThreshold, uint256 liquidationBonus, uint256 reserveFactor, bool usageAsCollateralEnabled, bool borrowingEnabled, bool stableBorrowRateEnabled, bool isActive, bool isFrozen);
  function getReserveData(address asset) external view returns (uint256 availableLiquidity, uint256 totalStableDebt, uint256 totalVariableDebt, uint256 liquidityRate, uint256 variableBorrowRate, uint256 stableBorrowRate, uint256 averageStableBorrowRate, uint256 liquidityIndex, uint256 variableBorrowIndex, uint40 lastUpdateTimestamp);
  function getUserReserveData(address asset, address user) external view returns (uint256 currentATokenBalance, uint256 currentStableDebt, uint256 currentVariableDebt, uint256 principalStableDebt, uint256 scaledVariableDebt, uint256 stableBorrowRate, uint256 liquidityRate, uint40 stableRateLastUpdated, bool usageAsCollateralEnabled);
  function getReserveTokensAddresses(address asset) external view returns (address aTokenAddress, address stableDebtTokenAddress, address variableDebtTokenAddress);
}

/*
  Copyright 2021 Set Labs Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  SPDX-License-Identifier: Apache-2.0
*/
pragma solidity 0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IVariableDebtToken
 * @author Aave
 * @notice Defines the basic interface for a variable debt token.
 **/
interface IVariableDebtToken is IERC20 {}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

interface IController {
    function addSet(address _setToken) external;
    function feeRecipient() external view returns(address);
    function getModuleFee(address _module, uint256 _feeType) external view returns(uint256);
    function isModule(address _module) external view returns(bool);
    function isSet(address _setToken) external view returns(bool);
    function isSystemContract(address _contractAddress) external view returns (bool);
    function resourceId(uint256 _id) external view returns(address);
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

interface IExchangeAdapter {
    function getSpender() external view returns(address);
    function getTradeCalldata(
        address _fromToken,
        address _toToken,
        address _toAddress,
        uint256 _fromQuantity,
        uint256 _minToQuantity,
        bytes memory _data
    )
        external
        view
        returns (address, uint256, bytes memory);
    function isDynamicDataAdapter() external view returns(bool);
    function getTradeMetadata(
        bytes memory _data
    )
        external
        view
        returns (bytes4 signature, address fromToken, address toToken, uint256 inputAmount, uint256 minAmountOut);
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

interface IIntegrationRegistry {
    function addIntegration(address _module, string memory _id, address _wrapper) external;
    function getIntegrationAdapter(address _module, string memory _id) external view returns(address);
    function getIntegrationAdapterWithHash(address _module, bytes32 _id) external view returns(address);
    function isValidIntegration(address _module, string memory _id) external view returns(bool);
}

/*
    Copyright 2022 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

import { ISetToken } from "./ISetToken.sol";

/**
 * @title IIssuanceModule
 * @author Set Protocol
 *
 * Interface for interacting with Issuance module interface.
 */
interface IIssuanceModule {
    function updateIssueFee(ISetToken _setToken, uint256 _newIssueFee) external;
    function updateRedeemFee(ISetToken _setToken, uint256 _newRedeemFee) external;
    function updateFeeRecipient(ISetToken _setToken, address _newRedeemFee) external;

    function initialize(
        ISetToken _setToken,
        uint256 _maxManagerFee,
        uint256 _managerIssueFee,
        uint256 _managerRedeemFee,
        address _feeRecipient,
        address _managerIssuanceHook
    ) external;
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

/**
 * @title IModule
 * @author Set Protocol
 *
 * Interface for interacting with Modules.
 */
interface IModule {
    /**
     * Called by a SetToken to notify that this module was removed from the Set token. Any logic can be included
     * in case checks need to be made or state needs to be cleared.
     */
    function removeModule() external;
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

/**
 * @title IPriceOracle
 * @author Set Protocol
 *
 * Interface for interacting with PriceOracle
 */
interface IPriceOracle {

    /* ============ Functions ============ */

    function getPrice(address _assetOne, address _assetTwo) external view returns (uint256);
    function masterQuoteAsset() external view returns (address);
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ISetToken
 * @author Set Protocol
 *
 * Interface for operating with SetTokens.
 */
interface ISetToken is IERC20 {

    /* ============ Enums ============ */

    enum ModuleState {
        NONE,
        PENDING,
        INITIALIZED
    }

    /* ============ Structs ============ */
    /**
     * The base definition of a SetToken Position
     *
     * @param component           Address of token in the Position
     * @param module              If not in default state, the address of associated module
     * @param unit                Each unit is the # of components per 10^18 of a SetToken
     * @param positionState       Position ENUM. Default is 0; External is 1
     * @param data                Arbitrary data
     */
    struct Position {
        address component;
        address module;
        int256 unit;
        uint8 positionState;
        bytes data;
    }

    /**
     * A struct that stores a component's cash position details and external positions
     * This data structure allows O(1) access to a component's cash position units and 
     * virtual units.
     *
     * @param virtualUnit               Virtual value of a component's DEFAULT position. Stored as virtual for efficiency
     *                                  updating all units at once via the position multiplier. Virtual units are achieved
     *                                  by dividing a "real" value by the "positionMultiplier"
     * @param componentIndex            
     * @param externalPositionModules   List of external modules attached to each external position. Each module
     *                                  maps to an external position
     * @param externalPositions         Mapping of module => ExternalPosition struct for a given component
     */
    struct ComponentPosition {
      int256 virtualUnit;
      address[] externalPositionModules;
      mapping(address => ExternalPosition) externalPositions;
    }

    /**
     * A struct that stores a component's external position details including virtual unit and any
     * auxiliary data.
     *
     * @param virtualUnit       Virtual value of a component's EXTERNAL position.
     * @param data              Arbitrary data
     */
    struct ExternalPosition {
      int256 virtualUnit;
      bytes data;
    }


    /* ============ Functions ============ */
    
    function addComponent(address _component) external;
    function removeComponent(address _component) external;
    function editDefaultPositionUnit(address _component, int256 _realUnit) external;
    function addExternalPositionModule(address _component, address _positionModule) external;
    function removeExternalPositionModule(address _component, address _positionModule) external;
    function editExternalPositionUnit(address _component, address _positionModule, int256 _realUnit) external;
    function editExternalPositionData(address _component, address _positionModule, bytes calldata _data) external;

    function invoke(address _target, uint256 _value, bytes calldata _data) external returns(bytes memory);

    function editPositionMultiplier(int256 _newMultiplier) external;

    function mint(address _account, uint256 _quantity) external;
    function burn(address _account, uint256 _quantity) external;

    function lock() external;
    function unlock() external;

    function addModule(address _module) external;
    function removeModule(address _module) external;
    function initializeModule() external;

    function setManager(address _manager) external;

    function manager() external view returns (address);
    function moduleStates(address _module) external view returns (ModuleState);
    function getModules() external view returns (address[] memory);
    
    function getDefaultPositionRealUnit(address _component) external view returns(int256);
    function getExternalPositionRealUnit(address _component, address _positionModule) external view returns(int256);
    function getComponents() external view returns(address[] memory);
    function getExternalPositionModules(address _component) external view returns(address[] memory);
    function getExternalPositionData(address _component, address _positionModule) external view returns(bytes memory);
    function isExternalPositionModule(address _component, address _module) external view returns(bool);
    function isComponent(address _component) external view returns(bool);
    
    function positionMultiplier() external view returns (int256);
    function getPositions() external view returns (Position[] memory);
    function getTotalComponentRealUnits(address _component) external view returns(int256);

    function isInitializedModule(address _module) external view returns(bool);
    function isPendingModule(address _module) external view returns(bool);
    function isLocked() external view returns (bool);
}

/*
  Copyright 2022 Set Labs Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

interface ISetTokenCreator {
    function create(
        address[] memory _components,
        int256[] memory _units,
        address[] memory _modules,
        address _manager,
        string memory _name,
        string memory _symbol
    )
        external
        returns (address);
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

import { ISetToken } from "../interfaces/ISetToken.sol";

interface ISetValuer {
    function calculateSetTokenValuation(ISetToken _setToken, address _quoteAsset) external view returns (uint256);
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

import { ISetToken } from "./ISetToken.sol";

interface IStreamingFeeModule {
    struct FeeState {
        address feeRecipient;
        uint256 maxStreamingFeePercentage;
        uint256 streamingFeePercentage;
        uint256 lastStreamingFeeTimestamp;
    }

    function feeStates(ISetToken _setToken) external view returns (FeeState memory);
    function getFee(ISetToken _setToken) external view returns (uint256);
    function accrueFee(ISetToken _setToken) external;
    function updateStreamingFee(ISetToken _setToken, uint256 _newFee) external;
    function updateFeeRecipient(ISetToken _setToken, address _newFeeRecipient) external;
    function initialize(ISetToken _setToken, FeeState memory _settings) external;
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/
/* solhint-disable var-name-mixedcase */

pragma solidity 0.8.19;

/**
 * @title AddressArrayUtils
 * @author Set Protocol
 *
 * Utility functions to handle Address Arrays
 *
 * CHANGELOG
 * - 4/21/21: Added validatePairsWithArray methods
 * - 4/18/23: Upgrade to Solidity 0.8.19
 */
library AddressArrayUtils {

    /**
     * Finds the index of the first occurrence of the given element.
     * @param A The input array to search
     * @param a The value to find
     * @return Returns (index and isIn) for the first occurrence starting from index 0
     */
    function indexOf(address[] memory A, address a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i; i < length; ) {
            if (A[i] == a) {
                return (i, true);
            }
            unchecked { ++i; }
        }
        return (type(uint256).max, false);
    }

    /**
    * Returns true if the value is present in the list. Uses indexOf internally.
    * @param A The input array to search
    * @param a The value to find
    * @return Returns isIn for the first occurrence starting from index 0
    */
    function contains(address[] memory A, address a) internal pure returns (bool) {
        (, bool isIn) = indexOf(A, a);
        return isIn;
    }

    /**
    * Returns true if there are 2 elements that are the same in an array
    * @param A The input array to search
    * @return Returns boolean for the first occurrence of a duplicate
    */
    function hasDuplicate(address[] memory A) internal pure returns(bool) {
        require(A.length > 0, "A is empty");

        uint256 length = A.length;
        for (uint256 i; i < length - 1; ) {
            address current = A[i];
            for (uint256 j = i + 1; j < length;) {
                if (current == A[j]) {
                    return true;
                }
                unchecked { ++j; }
            }
            unchecked { ++i; }
        }
        return false;
    }

    /**
     * @param A The input array to search
     * @param a The address to remove
     * @return Returns the array with the object removed.
     */
    function remove(address[] memory A, address a)
        internal
        pure
        returns (address[] memory)
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("Address not in array.");
        } else {
            (address[] memory _A,) = pop(A, index);
            return _A;
        }
    }

    /**
     * @param A The input array to search
     * @param a The address to remove
     */
    function removeStorage(address[] storage A, address a)
        internal
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("Address not in array.");
        } else {
            uint256 lastIndex = A.length - 1; // If the array would be empty, the previous line would throw, so no underflow here
            if (index != lastIndex) { A[index] = A[lastIndex]; }
            A.pop();
        }
    }

    /**
    * Removes specified index from array
    * @param A The input array to search
    * @param index The index to remove
    * @return Returns the new array and the removed entry
    */
    function pop(address[] memory A, uint256 index)
        internal
        pure
        returns (address[] memory, address)
    {
        uint256 length = A.length;
        require(index < length, "Index must be < A length");
        address[] memory newAddresses = new address[](length - 1);
        for (uint256 i; i < index; ) {
            newAddresses[i] = A[i];
            unchecked { ++i; }
        }
        for (uint256 j = index + 1; j < length;) {
            newAddresses[j - 1] = A[j];
            unchecked { ++j; }
        }
        return (newAddresses, A[index]);
    }

    /**
     * Returns the combination of the two arrays
     * @param A The first array
     * @param B The second array
     * @return Returns A extended by B
     */
    function extend(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint256 aLength = A.length;
        uint256 bLength = B.length;
        address[] memory newAddresses = new address[](aLength + bLength);
        for (uint256 i; i < aLength; ) {
            newAddresses[i] = A[i];
            unchecked { ++i; }
        }
        for (uint256 j; j < bLength;) {
            newAddresses[aLength + j] = B[j];
            unchecked { ++j; }
        }
        return newAddresses;
    }

    /**
     * Validate that address and uint array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of uint
     */
    function validatePairsWithArray(address[] memory A, uint[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address and bool array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of bool
     */
    function validatePairsWithArray(address[] memory A, bool[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address and string array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of strings
     */
    function validatePairsWithArray(address[] memory A, string[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address array lengths match, and calling address array are not empty
     * and contain no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of addresses
     */
    function validatePairsWithArray(address[] memory A, address[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address and bytes array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of bytes
     */
    function validatePairsWithArray(address[] memory A, bytes[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate address array is not empty and contains no duplicate elements.
     *
     * @param A          Array of addresses
     */
    function _validateLengthAndUniqueness(address[] memory A) internal pure {
        require(A.length > 0, "Array length must be > 0");
        require(!hasDuplicate(A), "Cannot duplicate addresses");
    }
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title ExplicitERC20
 * @author Set Protocol
 *
 * Utility functions for ERC20 transfers that require the explicit amount to be transferred.
 *
 * CHANGELOG
 * - 4/18/23: Upgrade to Solidity 0.8.19
 * - 4/21/23: Removed OZ SafeMath
 */
library ExplicitERC20 {
    /**
     * When given allowance, transfers a token from the "_from" to the "_to" of quantity "_quantity".
     * Ensures that the recipient has received the correct quantity (ie no fees taken on transfer)
     *
     * @param _token           ERC20 token to approve
     * @param _from            The account to transfer tokens from
     * @param _to              The account to transfer tokens to
     * @param _quantity        The quantity to transfer
     */
    function transferFrom(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _quantity
    )
        internal
    {
        // Call specified ERC20 contract to transfer tokens (via proxy).
        if (_quantity > 0) {
            uint256 existingBalance = _token.balanceOf(_to);

            SafeERC20.safeTransferFrom(
                _token,
                _from,
                _to,
                _quantity
            );

            uint256 newBalance = _token.balanceOf(_to);

            // Verify transfer quantity is reflected in balance
            require(
                newBalance == existingBalance + _quantity,
                "Invalid post transfer balance"
            );
        }
    }
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @title PreciseUnitMath
 * @author Set Protocol
 *
 * Arithmetic for fixed-point numbers with 18 decimals of precision. Some functions taken from
 * dYdX's BaseMath library.
 *
 * CHANGELOG
 * - 9/21/20: Added safePower function
 * - 4/21/21: Added approximatelyEquals function
 * - 12/13/21: Added preciseDivCeil (int overloads) function
 * - 12/13/21: Added abs function
 * - 4/14/23: Removed safePower function
 * - 4/18/23: Upgrade Solidity and OZ
 * - 4/21/23: Removed OZ SafeMath utils
 */
library PreciseUnitMath {
    using SafeCast for int256;

    // The number One in precise units.
    uint256 constant internal PRECISE_UNIT = 10 ** 18;
    int256 constant internal PRECISE_UNIT_INT = 10 ** 18;

    // Max unsigned integer value
    uint256 constant internal MAX_UINT_256 = type(uint256).max;
    // Max and min signed integer value
    int256 constant internal MAX_INT_256 = type(int256).max;
    int256 constant internal MIN_INT_256 = type(int256).min;

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnit() internal pure returns (uint256) {
        return PRECISE_UNIT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnitInt() internal pure returns (int256) {
        return PRECISE_UNIT_INT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxUint256() internal pure returns (uint256) {
        return MAX_UINT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxInt256() internal pure returns (int256) {
        return MAX_INT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function minInt256() internal pure returns (int256) {
        return MIN_INT_256;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded down). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function preciseMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / PRECISE_UNIT;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded towards zero). It's assumed that the value b is the
     * significand of a number with 18 decimals precision.
     */
    function preciseMul(int256 a, int256 b) internal pure returns (int256) {
        return (a * b) / PRECISE_UNIT_INT;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded up). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function preciseMulCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        return (((a * b) - 1) / PRECISE_UNIT) + 1;
    }

    /**
     * @dev Divides value a by value b (result is rounded down).
     */
    function preciseDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * PRECISE_UNIT) / b;
    }


    /**
     * @dev Divides value a by value b (result is rounded towards 0).
     */
    function preciseDiv(int256 a, int256 b) internal pure returns (int256) {
        return (a * PRECISE_UNIT_INT) / b;
    }

    /**
     * @dev Divides value a by value b (result is rounded up or away from 0).
     */
    function preciseDivCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "Cant divide by 0");

        return a > 0 ? (((a * PRECISE_UNIT) - 1) / b) + 1 : 0;
    }

    /**
     * @dev Divides value a by value b (result is rounded up or away from 0). When `a` is 0, 0 is
     * returned. When `b` is 0, method reverts with divide-by-zero error.
     */
    function preciseDivCeil(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "Cant divide by 0");
        
        a = a * PRECISE_UNIT_INT;
        int256 c = a / b;

        if (a % b != 0) {
            // a ^ b == 0 case is covered by the previous if statement, hence it won't resolve to --c
            (a ^ b > 0) ? ++c : --c;
        }

        return c;
    }

    /**
     * @dev Divides value a by value b (result is rounded down - positive numbers toward 0 and negative away from 0).
     */
    function divDown(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "Cant divide by 0");
        require(a != MIN_INT_256 || b != -1, "Invalid input");

        int256 result = a / b;
        if (a ^ b < 0 && a % b != 0) {
            result -= 1;
        }

        return result;
    }

    /**
     * @dev Multiplies value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function conservativePreciseMul(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a * b, PRECISE_UNIT_INT);
    }

    /**
     * @dev Divides value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function conservativePreciseDiv(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a * PRECISE_UNIT_INT, b);
    }

    /**
     * @dev Returns true if a =~ b within range, false otherwise.
     */
    function approximatelyEquals(uint256 a, uint256 b, uint256 range) internal pure returns (bool) {
        return a <= b + range && a >= b - range;
    }

    /**
     * Returns the absolute value of int256 `a` as a uint256
     */
    function abs(int256 a) internal pure returns (uint) {
        return a > -1 ? a.toUint256() : (a * -1).toUint256();
    }

    /**
     * Returns the negation of a
     */
    function neg(int256 a) internal pure returns (int256) {
        require(a > MIN_INT_256, "Inversion overflow");
        return -a;
    }
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

/* solhint-disable var-name-mixedcase */

/**
 * @title StringArrayUtils
 * @author Set Protocol
 *
 * Utility functions to handle String Arrays
 *
 * CHANGELOG
 * - 4/18/23: Upgrade to Solidity 0.8.19
 */
library StringArrayUtils {

    /**
     * Finds the index of the first occurrence of the given element.
     * @param A The input string to search
     * @param a The value to find
     * @return Returns (index and isIn) for the first occurrence starting from index 0
     */
    function indexOf(string[] memory A, string memory a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i; i < length; ) {
            if (keccak256(bytes(A[i])) == keccak256(bytes(a))) {
                return (i, true);
            }
            unchecked { ++i; }
        }
        return (type(uint256).max, false);
    }

    /**
     * @param A The input array to search
     * @param a The string to remove
     */
    function removeStorage(string[] storage A, string memory a)
        internal
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("String not in array.");
        } else {
            uint256 lastIndex = A.length - 1; // If the array would be empty, the previous line would throw, so no underflow here
            if (index != lastIndex) { A[index] = A[lastIndex]; }
            A.pop();
        }
    }
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISetToken } from "../../interfaces/ISetToken.sol";


/**
 * @title Invoke
 * @author Set Protocol
 *
 * A collection of common utility functions for interacting with the SetToken's invoke function
 *
 * CHANGELOG
 * - 4/18/23: Upgrade to Solidity 0.8.19
 * - 4/21/23: Removed OZ SafeMath utils
 */
library Invoke {
    /* ============ Internal ============ */

    /**
     * Instructs the SetToken to set approvals of the ERC20 token to a spender.
     *
     * @param _setToken        SetToken instance to invoke
     * @param _token           ERC20 token to approve
     * @param _spender         The account allowed to spend the SetToken's balance
     * @param _quantity        The quantity of allowance to allow
     */
    function invokeApprove(
        ISetToken _setToken,
        address _token,
        address _spender,
        uint256 _quantity
    )
        internal
    {
        bytes memory callData = abi.encodeWithSignature("approve(address,uint256)", _spender, _quantity);
        _setToken.invoke(_token, 0, callData);
    }

    /**
     * Instructs the SetToken to transfer the ERC20 token to a recipient.
     *
     * @param _setToken        SetToken instance to invoke
     * @param _token           ERC20 token to transfer
     * @param _to              The recipient account
     * @param _quantity        The quantity to transfer
     */
    function invokeTransfer(
        ISetToken _setToken,
        address _token,
        address _to,
        uint256 _quantity
    )
        internal
    {
        if (_quantity > 0) {
            bytes memory callData = abi.encodeWithSignature("transfer(address,uint256)", _to, _quantity);
            _setToken.invoke(_token, 0, callData);
        }
    }

    /**
     * Instructs the SetToken to transfer the ERC20 token to a recipient.
     * The new SetToken balance must equal the existing balance less the quantity transferred
     *
     * @param _setToken        SetToken instance to invoke
     * @param _token           ERC20 token to transfer
     * @param _to              The recipient account
     * @param _quantity        The quantity to transfer
     */
    function strictInvokeTransfer(
        ISetToken _setToken,
        address _token,
        address _to,
        uint256 _quantity
    )
        internal
    {
        if (_quantity > 0) {
            // Retrieve current balance of token for the SetToken
            uint256 existingBalance = IERC20(_token).balanceOf(address(_setToken));

            Invoke.invokeTransfer(_setToken, _token, _to, _quantity);

            // Get new balance of transferred token for SetToken
            uint256 newBalance = IERC20(_token).balanceOf(address(_setToken));

            // Verify only the transfer quantity is subtracted
            require(
                newBalance == existingBalance - _quantity,
                "Invalid post transfer balance"
            );
        }
    }

    /**
     * Instructs the SetToken to unwrap the passed quantity of WETH
     *
     * @param _setToken        SetToken instance to invoke
     * @param _weth            WETH address
     * @param _quantity        The quantity to unwrap
     */
    function invokeUnwrapWETH(ISetToken _setToken, address _weth, uint256 _quantity) internal {
        bytes memory callData = abi.encodeWithSignature("withdraw(uint256)", _quantity);
        _setToken.invoke(_weth, 0, callData);
    }

    /**
     * Instructs the SetToken to wrap the passed quantity of ETH
     *
     * @param _setToken        SetToken instance to invoke
     * @param _weth            WETH address
     * @param _quantity        The quantity to unwrap
     */
    function invokeWrapWETH(ISetToken _setToken, address _weth, uint256 _quantity) internal {
        bytes memory callData = abi.encodeWithSignature("deposit()");
        _setToken.invoke(_weth, _quantity, callData);
    }
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { AddressArrayUtils } from "../../lib/AddressArrayUtils.sol";
import { ExplicitERC20 } from "../../lib/ExplicitERC20.sol";
import { IController } from "../../interfaces/IController.sol";
import { IModule } from "../../interfaces/IModule.sol";
import { ISetToken } from "../../interfaces/ISetToken.sol";
import { Invoke } from "./Invoke.sol";
import { Position } from "./Position.sol";
import { PreciseUnitMath } from "../../lib/PreciseUnitMath.sol";
import { ResourceIdentifier } from "./ResourceIdentifier.sol";

/**
 * @title ModuleBase
 * @author Set Protocol
 *
 * Abstract class that houses common Module-related state and functions.
 *
 * CHANGELOG
 * - 4/21/21: Delegated modifier logic to internal helpers to reduce contract size
 * - 4/18/23: Upgrade to Solidity 0.8.19
 * - 4/21/23: Removed OZ SafeMath utils
 */
abstract contract ModuleBase is IModule {
    using AddressArrayUtils for address[];
    using Invoke for ISetToken;
    using Position for ISetToken;
    using PreciseUnitMath for uint256;
    using ResourceIdentifier for IController;

    /* ============ State Variables ============ */

    // Address of the controller
    IController public controller;

    /* ============ Modifiers ============ */

    modifier onlyManagerAndValidSet(ISetToken _setToken) {
        _validateOnlyManagerAndValidSet(_setToken);
        _;
    }

    modifier onlySetManager(ISetToken _setToken, address _caller) {
        _validateOnlySetManager(_setToken, _caller);
        _;
    }

    modifier onlyValidAndInitializedSet(ISetToken _setToken) {
        _validateOnlyValidAndInitializedSet(_setToken);
        _;
    }

    /**
     * Throws if the sender is not a SetToken's module or module not enabled
     */
    modifier onlyModule(ISetToken _setToken) {
        _validateOnlyModule(_setToken);
        _;
    }

    /**
     * Utilized during module initializations to check that the module is in pending state
     * and that the SetToken is valid
     */
    modifier onlyValidAndPendingSet(ISetToken _setToken) {
        _validateOnlyValidAndPendingSet(_setToken);
        _;
    }

    /* ============ Constructor ============ */

    /**
     * Set state variables and map asset pairs to their oracles
     *
     * @param _controller             Address of controller contract
     */
    constructor(IController _controller) {
        controller = _controller;
    }

    /* ============ Internal Functions ============ */

    /**
     * Transfers tokens from an address (that has set allowance on the module).
     *
     * @param  _token          The address of the ERC20 token
     * @param  _from           The address to transfer from
     * @param  _to             The address to transfer to
     * @param  _quantity       The number of tokens to transfer
     */
    function transferFrom(IERC20 _token, address _from, address _to, uint256 _quantity) internal {
        ExplicitERC20.transferFrom(_token, _from, _to, _quantity);
    }

    /**
     * Gets the integration for the module with the passed in name. Validates that the address is not empty
     */
    function getAndValidateAdapter(string memory _integrationName) internal view returns(address) { 
        bytes32 integrationHash = getNameHash(_integrationName);
        return getAndValidateAdapterWithHash(integrationHash);
    }

    /**
     * Gets the integration for the module with the passed in hash. Validates that the address is not empty
     */
    function getAndValidateAdapterWithHash(bytes32 _integrationHash) internal view returns(address) { 
        address adapter = controller.getIntegrationRegistry().getIntegrationAdapterWithHash(
            address(this),
            _integrationHash
        );

        require(adapter != address(0), "Must be valid adapter"); 
        return adapter;
    }

    /**
     * Gets the total fee for this module of the passed in index (fee % * quantity)
     */
    function getModuleFee(uint256 _feeIndex, uint256 _quantity) internal view returns(uint256) {
        uint256 feePercentage = controller.getModuleFee(address(this), _feeIndex);
        return _quantity.preciseMul(feePercentage);
    }

    /**
     * Pays the _feeQuantity from the _setToken denominated in _token to the protocol fee recipient
     */
    function payProtocolFeeFromSetToken(ISetToken _setToken, address _token, uint256 _feeQuantity) internal {
        if (_feeQuantity > 0) {
            _setToken.strictInvokeTransfer(_token, controller.feeRecipient(), _feeQuantity); 
        }
    }

    /**
     * Returns true if the module is in process of initialization on the SetToken
     */
    function isSetPendingInitialization(ISetToken _setToken) internal view returns(bool) {
        return _setToken.isPendingModule(address(this));
    }

    /**
     * Returns true if the address is the SetToken's manager
     */
    function isSetManager(ISetToken _setToken, address _toCheck) internal view returns(bool) {
        return _setToken.manager() == _toCheck;
    }

    /**
     * Returns true if SetToken must be enabled on the controller 
     * and module is registered on the SetToken
     */
    function isSetValidAndInitialized(ISetToken _setToken) internal view returns(bool) {
        return controller.isSet(address(_setToken)) &&
            _setToken.isInitializedModule(address(this));
    }

    /**
     * Hashes the string and returns a bytes32 value
     */
    function getNameHash(string memory _name) internal pure returns(bytes32) {
        return keccak256(bytes(_name));
    }

    /* ============== Modifier Helpers ===============
     * Internal functions used to reduce bytecode size
     */

    /**
     * Caller must SetToken manager and SetToken must be valid and initialized
     */
    function _validateOnlyManagerAndValidSet(ISetToken _setToken) internal view {
       require(isSetManager(_setToken, msg.sender), "Must be the SetToken manager");
       require(isSetValidAndInitialized(_setToken), "Must be a valid and initialized SetToken");
    }

    /**
     * Caller must SetToken manager
     */
    function _validateOnlySetManager(ISetToken _setToken, address _caller) internal view {
        require(isSetManager(_setToken, _caller), "Must be the SetToken manager");
    }

    /**
     * SetToken must be valid and initialized
     */
    function _validateOnlyValidAndInitializedSet(ISetToken _setToken) internal view {
        require(isSetValidAndInitialized(_setToken), "Must be a valid and initialized SetToken");
    }

    /**
     * Caller must be initialized module and module must be enabled on the controller
     */
    function _validateOnlyModule(ISetToken _setToken) internal view {
        require(
            _setToken.moduleStates(msg.sender) == ISetToken.ModuleState.INITIALIZED,
            "Only the module can call"
        );

        require(
            controller.isModule(msg.sender),
            "Module must be enabled on controller"
        );
    }

    /**
     * SetToken must be in a pending state and module must be in pending state
     */
    function _validateOnlyValidAndPendingSet(ISetToken _setToken) internal view {
        require(controller.isSet(address(_setToken)), "Must be controller-enabled SetToken");
        require(isSetPendingInitialization(_setToken), "Must be pending initialization");
    }
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { ISetToken } from "../../interfaces/ISetToken.sol";
import { PreciseUnitMath } from "../../lib/PreciseUnitMath.sol";


/**
 * @title Position
 * @author Set Protocol
 *
 * Collection of helper functions for handling and updating SetToken Positions
 *
 * CHANGELOG
 * - Updated editExternalPosition to work when no external position is associated with module
 * - 4/18/23: Upgrade to Solidity 0.8.19
 * - 4/21/23: Removed OZ SafeMath utils
 */
library Position {
    using SafeCast for uint256;
    using SafeCast for int256;
    using PreciseUnitMath for uint256;

    /* ============ Helper ============ */

    /**
     * Returns whether the SetToken has a default position for a given component (if the real unit is > 0)
     */
    function hasDefaultPosition(ISetToken _setToken, address _component) internal view returns(bool) {
        return _setToken.getDefaultPositionRealUnit(_component) > 0;
    }

    /**
     * Returns whether the SetToken has an external position for a given component (if # of position modules is > 0)
     */
    function hasExternalPosition(ISetToken _setToken, address _component) internal view returns(bool) {
        return _setToken.getExternalPositionModules(_component).length > 0;
    }
    
    /**
     * Returns whether the SetToken component default position real unit is greater than or equal to units passed in.
     */
    function hasSufficientDefaultUnits(ISetToken _setToken, address _component, uint256 _unit) internal view returns(bool) {
        return _setToken.getDefaultPositionRealUnit(_component) >= _unit.toInt256();
    }

    /**
     * Returns whether the SetToken component external position is greater than or equal to the real units passed in.
     */
    function hasSufficientExternalUnits(
        ISetToken _setToken,
        address _component,
        address _positionModule,
        uint256 _unit
    )
        internal
        view
        returns(bool)
    {
       return _setToken.getExternalPositionRealUnit(_component, _positionModule) >= _unit.toInt256();    
    }

    /**
     * If the position does not exist, create a new Position and add to the SetToken. If it already exists,
     * then set the position units. If the new units is 0, remove the position. Handles adding/removing of 
     * components where needed (in light of potential external positions).
     *
     * @param _setToken           Address of SetToken being modified
     * @param _component          Address of the component
     * @param _newUnit            Quantity of Position units - must be >= 0
     */
    function editDefaultPosition(ISetToken _setToken, address _component, uint256 _newUnit) internal {
        bool isPositionFound = hasDefaultPosition(_setToken, _component);
        if (!isPositionFound && _newUnit > 0) {
            // If there is no Default Position and no External Modules, then component does not exist
            if (!hasExternalPosition(_setToken, _component)) {
                _setToken.addComponent(_component);
            }
        } else if (isPositionFound && _newUnit == 0) {
            // If there is a Default Position and no external positions, remove the component
            if (!hasExternalPosition(_setToken, _component)) {
                _setToken.removeComponent(_component);
            }
        }

        _setToken.editDefaultPositionUnit(_component, _newUnit.toInt256());
    }

    /**
     * Update an external position and remove and external positions or components if necessary. The logic flows as follows:
     * 1) If component is not already added then add component and external position. 
     * 2) If component is added but no existing external position using the passed module exists then add the external position.
     * 3) If the existing position is being added to then just update the unit and data
     * 4) If the position is being closed and no other external positions or default positions are associated with the component
     *    then untrack the component and remove external position.
     * 5) If the position is being closed and other existing positions still exist for the component then just remove the
     *    external position.
     *
     * @param _setToken         SetToken being updated
     * @param _component        Component position being updated
     * @param _module           Module external position is associated with
     * @param _newUnit          Position units of new external position
     * @param _data             Arbitrary data associated with the position
     */
    function editExternalPosition(
        ISetToken _setToken,
        address _component,
        address _module,
        int256 _newUnit,
        bytes memory _data
    )
        internal
    {
        if (_newUnit != 0) {
            if (!_setToken.isComponent(_component)) {
                _setToken.addComponent(_component);
                _setToken.addExternalPositionModule(_component, _module);
            } else if (!_setToken.isExternalPositionModule(_component, _module)) {
                _setToken.addExternalPositionModule(_component, _module);
            }
            _setToken.editExternalPositionUnit(_component, _module, _newUnit);
            _setToken.editExternalPositionData(_component, _module, _data);
        } else {
            require(_data.length == 0, "Passed data must be null");
            // If no default or external position remaining then remove component from components array
            if (_setToken.getExternalPositionRealUnit(_component, _module) != 0) {
                address[] memory positionModules = _setToken.getExternalPositionModules(_component);
                if (_setToken.getDefaultPositionRealUnit(_component) == 0 && positionModules.length == 1) {
                    require(positionModules[0] == _module, "External positions must be 0 to remove component");
                    _setToken.removeComponent(_component);
                }
                _setToken.removeExternalPositionModule(_component, _module);
            }
        }
    }

    /**
     * Get total notional amount of Default position
     *
     * @param _setTokenSupply     Supply of SetToken in precise units (10^18)
     * @param _positionUnit       Quantity of Position units
     *
     * @return                    Total notional amount of units
     */
    function getDefaultTotalNotional(uint256 _setTokenSupply, uint256 _positionUnit) internal pure returns (uint256) {
        return _setTokenSupply.preciseMul(_positionUnit);
    }

    /**
     * Get position unit from total notional amount
     *
     * @param _setTokenSupply     Supply of SetToken in precise units (10^18)
     * @param _totalNotional      Total notional amount of component prior to
     * @return                    Default position unit
     */
    function getDefaultPositionUnit(uint256 _setTokenSupply, uint256 _totalNotional) internal pure returns (uint256) {
        return _totalNotional.preciseDiv(_setTokenSupply);
    }

    /**
     * Get the total tracked balance - total supply * position unit
     *
     * @param _setToken           Address of the SetToken
     * @param _component          Address of the component
     * @return                    Notional tracked balance
     */
    function getDefaultTrackedBalance(ISetToken _setToken, address _component) internal view returns(uint256) {
        int256 positionUnit = _setToken.getDefaultPositionRealUnit(_component); 
        return _setToken.totalSupply().preciseMul(positionUnit.toUint256());
    }

    /**
     * Calculates the new default position unit and performs the edit with the new unit
     *
     * @param _setToken                 Address of the SetToken
     * @param _component                Address of the component
     * @param _setTotalSupply           Current SetToken supply
     * @param _componentPreviousBalance Pre-action component balance
     * @return                          Current component balance
     * @return                          Previous position unit
     * @return                          New position unit
     */
    function calculateAndEditDefaultPosition(
        ISetToken _setToken,
        address _component,
        uint256 _setTotalSupply,
        uint256 _componentPreviousBalance
    )
        internal
        returns(uint256, uint256, uint256)
    {
        uint256 currentBalance = IERC20(_component).balanceOf(address(_setToken));
        uint256 positionUnit = _setToken.getDefaultPositionRealUnit(_component).toUint256();

        uint256 newTokenUnit;
        if (currentBalance > 0) {
            newTokenUnit = calculateDefaultEditPositionUnit(
                _setTotalSupply,
                _componentPreviousBalance,
                currentBalance,
                positionUnit
            );
        }

        editDefaultPosition(_setToken, _component, newTokenUnit);

        return (currentBalance, positionUnit, newTokenUnit);
    }

    /**
     * Calculate the new position unit given total notional values pre and post executing an action that changes SetToken state
     * The intention is to make updates to the units without accidentally picking up airdropped assets as well.
     *
     * @param _setTokenSupply     Supply of SetToken in precise units (10^18)
     * @param _preTotalNotional   Total notional amount of component prior to executing action
     * @param _postTotalNotional  Total notional amount of component after the executing action
     * @param _prePositionUnit    Position unit of SetToken prior to executing action
     * @return                    New position unit
     */
    function calculateDefaultEditPositionUnit(
        uint256 _setTokenSupply,
        uint256 _preTotalNotional,
        uint256 _postTotalNotional,
        uint256 _prePositionUnit
    )
        internal
        pure
        returns (uint256)
    {
        // If pre action total notional amount is greater then subtract post action total notional and calculate new position units
        uint256 airdroppedAmount = _preTotalNotional - _prePositionUnit.preciseMul(_setTokenSupply);
        return (_postTotalNotional - airdroppedAmount).preciseDiv(_setTokenSupply);
    }
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

import { IController } from "../../interfaces/IController.sol";
import { IIntegrationRegistry } from "../../interfaces/IIntegrationRegistry.sol";
import { IPriceOracle } from "../../interfaces/IPriceOracle.sol";
import { ISetValuer } from "../../interfaces/ISetValuer.sol";

/**
 * @title ResourceIdentifier
 * @author Set Protocol
 *
 * A collection of utility functions to fetch information related to Resource contracts in the system
 *
 * CHANGELOG
 * - 4/18/23: Upgrade to Solidity 0.8.19
 */
library ResourceIdentifier {

    // IntegrationRegistry will always be resource ID 0 in the system
    uint256 constant internal INTEGRATION_REGISTRY_RESOURCE_ID = 0;
    // PriceOracle will always be resource ID 1 in the system
    uint256 constant internal PRICE_ORACLE_RESOURCE_ID = 1;
    // SetValuer resource will always be resource ID 2 in the system
    uint256 constant internal SET_VALUER_RESOURCE_ID = 2;

    /* ============ Internal ============ */

    /**
     * Gets the instance of integration registry stored on Controller. Note: IntegrationRegistry is stored as index 0 on
     * the Controller
     */
    function getIntegrationRegistry(IController _controller) internal view returns (IIntegrationRegistry) {
        return IIntegrationRegistry(_controller.resourceId(INTEGRATION_REGISTRY_RESOURCE_ID));
    }

    /**
     * Gets instance of price oracle on Controller. Note: PriceOracle is stored as index 1 on the Controller
     */
    function getPriceOracle(IController _controller) internal view returns (IPriceOracle) {
        return IPriceOracle(_controller.resourceId(PRICE_ORACLE_RESOURCE_ID));
    }

    /**
     * Gets the instance of Set valuer on Controller. Note: SetValuer is stored as index 2 on the Controller
     */
    function getSetValuer(IController _controller) internal view returns (ISetValuer) {
        return ISetValuer(_controller.resourceId(SET_VALUER_RESOURCE_ID));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

/*
    Copyright 2023 Amun Holdings Limited and affiliated entities.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { ISetToken } from "@amun/amun-protocol/contracts/interfaces/ISetToken.sol";
import {
    IProtocolDataProvider
} from "@amun/amun-protocol/contracts/interfaces/external/aave-v2/IProtocolDataProvider.sol";
import { PreciseUnitMath } from "@amun/amun-protocol/contracts/lib/PreciseUnitMath.sol";
import { StringArrayUtils } from "@amun/amun-protocol/contracts/lib/StringArrayUtils.sol";

import { IManagerCore } from "../interfaces/IManagerCore.sol";
import { IDelegatedManager } from "../interfaces/IDelegatedManager.sol";
import { ILeverageModule } from "../interfaces/ILeverageModule.sol";
import { IPriceOracleGetter } from "../interfaces/external/IPriceOracleGetter.sol";
import { BaseGlobalExtension } from "../lib/BaseGlobalExtension.sol";
import { IExchangeAdapter } from "@amun/amun-protocol/contracts/interfaces/IExchangeAdapter.sol";

/**
 * @title AaveLeverageExtension
 * @author Amun
 *
 * Smart contract that enables trustless leverage tokens. This extension is paired with the AaveLeverageModule
 * from Set protocol where module interactions are invoked via the IDelegatedManager contract. Any leveraged token
 * can be constructed as long as the collateral and borrow asset is available on Aave. This extension contract also
 * allows the operator to set an ETH reward to incentivize keepers calling the rebalance function at different 
 * leverage thresholds.
 */
contract AaveLeverageExtension is
    BaseGlobalExtension
{
    using Address for address;
    using PreciseUnitMath for uint256;
    using SafeCast for int256;
    using StringArrayUtils for string[];

    /* ============ Enums ============ */

    enum ShouldRebalance {
        NONE, // Indicates no rebalance action can be taken
        REBALANCE, // Indicates rebalance() function can be successfully called
        PROTECTION // Indicates protection() function can be successfully called
    }
    enum ShouldRipcord {
        NONE, // Indicates no rebalance action can be taken
        RIPCORD // Indicates ripcord() function can be successfully called
    }

    /* ============ Structs ============ */

    struct ActionInfo {
        address collateralAsset; // Collateral asset address
        address borrowAsset; // Debt asset address
        uint256 collateralBalance; // Balance of underlying held in Aave in base units (e.g. USDC 10e6)
        uint256 borrowBalance; // Balance of underlying borrowed from Aave in base units
        uint256 collateralValue; // Valuation in USD adjusted for decimals in precise units (10e18)
        uint256 borrowValue; // Valuation in USD adjusted for decimals in precise units (10e18)
        uint256 collateralPrice; // Price of collateral in precise units (10e18) from Chainlink
        uint256 borrowPrice; // Price of borrow asset in precise units (10e18) from Chainlink
        uint256 setTotalSupply; // Total supply of SetToken
    }
    struct StrategySettings {
        MethodologySettings methodology; // Methodology settings
        ExecutionSettings execution; // Execution settings
        mapping(string => ExchangeSettings) exchangeSettings; // Mapping between exchange name and its settings
        ProtectionSettings protection; // Protection settings
        IncentiveSettings incentive; // Ripcord settings
        string[] enabledExchanges; // Supported exchanges
        uint256 globalLastTradeTimestamp; // Last time a trade was executed
    }
    struct ConstituentInfo {
        address asset;
        address aaveToken;
        uint256 price;
    }
    struct LeverageInfo {
        ISetToken setToken;
        ActionInfo action;
        uint256 currentLeverageRatio; // Current leverage ratio of Set
        uint256 slippageTolerance; // Allowable percent trade slippage in preciseUnits (1% = 10^16)
        uint256 twapMaxTradeSize; // Max trade size in collateral units allowed for rebalance action
        string exchangeName; // Exchange to use for trade
        bytes swapData; // Dynamic swap data passed to exchange adapter
    }
    struct MethodologySettings {
        uint256 targetLeverageRatio; // Long term target ratio in precise units (10e18)
        uint256 minLeverageRatio; // Precise units(10e18). If current leverage is below, rebalance target is this ratio
        uint256 maxLeverageRatio; // Precise units(10e18). If current leverage is above, rebalance target is this ratio
    }
    struct ExecutionSettings {
        uint256 unutilizedLeveragePercentage; // Percent of max borrow left unutilized in precise units (1% = 10e16)
        uint256 slippageTolerance; // % in precise units to price min token receive amount from trade quantities
        uint256 twapCooldownPeriod; // Cooldown period required since last trade timestamp in seconds
    }
    struct ExchangeSettings {
        uint256 twapMaxTradeSize; // Max trade size in collateral base units
        uint256 exchangeLastTradeTimestamp; // Timestamp of last trade made with this exchange
        uint256 protectionTwapMaxTradeSize; // Max trade size for protection rebalances in collateral base units
        uint256 incentivizedTwapMaxTradeSize; // Max trade size for incentivized rebalances in collateral base units
        bytes leverExchangeData; // Arbitrary exchange data passed into rebalance function for levering up
        bytes deleverExchangeData; // Arbitrary exchange data passed into rebalance function for delevering
        address adapterAddress; // Optional adapter address, required when dynamic data is used
        bool hasDynamicData; // Indicates, whether data should be coming from transaction data, or from cached value
    }
    struct IncentiveSettings {
        uint256 etherReward; // ETH reward for incentivized rebalances
        uint256 thresholdLeverageRatio; // In precise units (10e18). Leverage ratio for incentivized rebalances
        uint256 slippageTolerance; // Slippage tolerance percentage for incentivized rebalances
        uint256 twapCooldownPeriod; // TWAP cooldown in seconds for incentivized rebalances
        uint256 resetLeverageRatio; // In precise units (10e18). Target leverage ratio used to reset
    }
    struct ProtectionSettings {
        uint256 thresholdLeverageRatio; // In precise units (10e18). Leverage ratio for protection rebalances
        uint256 slippageTolerance; // Slippage tolerance percentage for protection rebalances
        uint256 twapCooldownPeriod; // TWAP cooldown in seconds for protection rebalances
        uint256 resetLeverageRatio; // In precise units (10e18). Target leverage ratio used to reset
    }

    /* ============ Events ============ */

    event ExecutionSettingsUpdated(
        address _setToken,
        uint256 _unutilizedLeveragePercentage,
        uint256 _twapCooldownPeriod,
        uint256 _slippageTolerance
    );
    event ProtectionSettingsUpdated(
        address _setToken,
        uint256 _thresholdLeverageRatio,
        uint256 _resetLeverageRatio,
        uint256 _slippageTolerance,
        uint256 _twapCooldownPeriod
    );
    event IncentiveSettingsUpdated(
        address _setToken,
        uint256 _etherReward,
        uint256 _thresholdLeverageRatio,
        uint256 _resetLeverageRatio,
        uint256 _slippageTolerance,
        uint256 _twapCooldownPeriod
    );
    event ExchangeAdded(
        address _setToken,
        string _exchangeName,
        uint256 _twapMaxTradeSize,
        uint256 _exchangeLastTradeTimestamp,
        uint256 _protectionTwapMaxTradeSize,
        uint256 _incentivizedTwapMaxTradeSize,
        bytes _leverExchangeData,
        bytes _deleverExchangeData,
        address adapterAddress,
        bool hasDynamicData
    );
    event ExchangeUpdated(
        address _setToken,
        string _exchangeName,
        uint256 _twapMaxTradeSize,
        uint256 _exchangeLastTradeTimestamp,
        uint256 _protectionTwapMaxTradeSize,
        uint256 _incentivizedTwapMaxTradeSize,
        bytes _leverExchangeData,
        bytes _deleverExchangeData,
        address adapterAddress,
        bool hasDynamicData
    );
    event ExchangeRemoved(address _setToken, string _exchangeName);
    event Engaged(
        address _setToken,
        uint256 _currentLeverageRatio,
        uint256 _newLeverageRatio,
        uint256 _chunkRebalanceNotional,
        uint256 _totalRebalanceNotional
    );
    event Rebalanced(
        address _setToken,
        uint256 _currentLeverageRatio,
        uint256 _newLeverageRatio,
        uint256 _chunkRebalanceNotional,
        uint256 _totalRebalanceNotional
    );
    event ProtectionCalled(
        address _setToken,
        uint256 _currentLeverageRatio,
        uint256 _newLeverageRatio,
        uint256 _rebalanceNotional
    );
    event RipcordCalled(
        address _setToken,
        uint256 _currentLeverageRatio,
        uint256 _newLeverageRatio,
        uint256 _rebalanceNotional,
        uint256 _etherIncentive
    );
    event Disengaged(
        address _setToken,
        uint256 _currentLeverageRatio,
        uint256 _newLeverageRatio,
        uint256 _chunkRebalanceNotional,
        uint256 _totalRebalanceNotional
    );
    event MethodologySettingsUpdated(
        address _setToken,
        uint256 _targetLeverageRatio,
        uint256 _minLeverageRatio,
        uint256 _maxLeverageRatio
    );
    event AaveLeverageExtensionInitialized(
        address indexed _setToken,
        address indexed _delegatedManager
    );

    /* ============ Errors ============ */

    error Engage(uint256 id);
    error Rebalance(uint256 id);
    error Protect(uint256 id);
    error Ripcord(uint256 id);
    error AddEnabledExchange(uint256 id);
    error RemoveEnabledExchange(uint256 id);
    error UpdateEnabledExchange(uint256 id);
    error InitializeExtension(uint256 id);
    error InitializeModule(uint256 id);
    error ShouldRebalanceWithBounds(uint256 id);
    error HandleRebalance(uint256 id);
    error ValidateLeveragedInfo(uint256 id);
    error CalculateChunkRebalanceNotional(uint256 id);
    error GetSetTokenConstituentInfo(uint256 id);
    error ValidateRipcord(uint256 id);
    error ValidateNonExchangeSettings(uint256 id);
    error ValidateExchangeSettings(uint256 id);

    /* ============ State Variables ============ */

    ILeverageModule public leverageModule; // LeverageModule associated to the extension
    mapping(ISetToken => StrategySettings) public strategy; // Mapping between supported setTokens and their params

    /* ============ Constructor ============ */

    /**
     * Instantiate managerCore and leverage module.
     *
     */
    constructor(
        IManagerCore _managerCore,
        ILeverageModule _leverageModule
    ) BaseGlobalExtension(_managerCore) {
        leverageModule = _leverageModule;
    }

    /* ============ External Functions ============ */

    /**
     * ONLY OPERATOR: Engage to target leverage ratio for the first time. SetToken will borrow debt position from Aave
     * and trade for collateral asset. If target leverage ratio is above max borrow or max trade size, then TWAP is 
     * kicked off. To complete engage if TWAP, the operator must call rebalance to meet the target.
     *
     * @param _setToken                SetToken to engage
     * @param _exchangeName            Exchange used for trading
     * @param _collateralConstituent   Collateral information Struct (prices, address and aave collateral address)
     * @param _borrowConstituent       Borrow information Struct (prices, constituent and aave variable debt address)
     * @param _swapData                Dynamic swap data passed to exchange adapter
     */
    function engage(
        ISetToken _setToken,
        string memory _exchangeName,
        ConstituentInfo memory _collateralConstituent,
        ConstituentInfo memory _borrowConstituent,
        bytes memory _swapData
    ) external onlyOperator(_setToken) {
        StrategySettings storage myStrategy = strategy[_setToken];

        ActionInfo memory engageInfo = _createActionInfo(
            _setToken,
            _collateralConstituent,
            _borrowConstituent
        );

        if (!(engageInfo.setTotalSupply > 0)) {
            revert Engage(uint256(1)); // SetToken must have > 0 supply
        }

        if (!(engageInfo.borrowBalance == 0)) {
            revert Engage(uint256(2)); // Debt must be 0
        }

        LeverageInfo memory leverageInfo = LeverageInfo({
            setToken: _setToken,
            action: engageInfo,
            currentLeverageRatio: PreciseUnitMath.preciseUnit(), // 1x leverage in precise units
            slippageTolerance: myStrategy.execution.slippageTolerance,
            twapMaxTradeSize: myStrategy
                .exchangeSettings[_exchangeName]
                .twapMaxTradeSize,
            exchangeName: _exchangeName,
            swapData: _swapData
        });

        // Calculate total rebalance units and kick off TWAP if above max borrow or max trade size
        (
            uint256 chunkRebalanceNotional,
            uint256 totalRebalanceNotional
        ) = _calculateChunkRebalanceNotional(
                leverageInfo,
                myStrategy.methodology.targetLeverageRatio,
                true,
                true
            );

        _lever(leverageInfo, chunkRebalanceNotional, _swapData);

        _updateLastTradeTimestamp(_setToken, _exchangeName);

        emit Engaged(
            address(_setToken),
            leverageInfo.currentLeverageRatio,
            getCurrentOnchainLeverageRatio(_setToken),
            chunkRebalanceNotional,
            totalRebalanceNotional
        );
    }

    /**
     * ONLY OPERATOR: Rebalance product. If current leverage ratio is between the max and min bounds, then rebalance
     * can only be called once the rebalance interval has elapsed since last timestamp. If outside the max and min, 
     * rebalance can be called anytime to bring leverage ratio back to the max or min bounds. The methodology will 
     * determine whether to delever or lever.
     * Note: If the calculated current leverage ratio is above the incentivized leverage ratio or in TWAP then rebalance
     * cannot be called. Instead, you must call ripcord() which is incentivized with a reward in Ether or wait for 
     * cooldown period to elapse and call this function again.
     *
     * @param _setToken          SetToken to rebalance
     * @param _exchangeName      Exchange used for trading
     * @param _collateralPrice   Offchain collateral price
     * @param _borrowPrice       Offchain borrow price
     * @param _swapData          Dynamic swap data passed to exchange adapter
     */
    function rebalance(
        ISetToken _setToken,
        string memory _exchangeName,
        uint256 _collateralPrice,
        uint256 _borrowPrice,
        bytes memory _swapData
    ) external onlyOperator(_setToken) {
        StrategySettings storage myStrategy = strategy[_setToken];

        (
            ConstituentInfo memory collateralAsset,
            ConstituentInfo memory borrowAsset
        ) = _getSetTokenConstituentInfo(_setToken);

        collateralAsset.price = _collateralPrice;
        borrowAsset.price = _borrowPrice;

        LeverageInfo memory leverageInfo = _getAndValidateLeveragedInfo(
            _setToken,
            myStrategy.execution.slippageTolerance,
            myStrategy.exchangeSettings[_exchangeName].twapMaxTradeSize,
            _exchangeName,
            _createActionInfo(_setToken, collateralAsset, borrowAsset),
            _swapData
        );

        if (
            !(getCurrentOnchainLeverageRatio(leverageInfo.setToken) <
                myStrategy.protection.thresholdLeverageRatio)
        ) {
            revert Rebalance(uint256(1)); // Must be below protection leverage ratio
        }

        if (
            !(myStrategy
                .exchangeSettings[_exchangeName]
                .exchangeLastTradeTimestamp +
                myStrategy.execution.twapCooldownPeriod <
                block.timestamp) /* solhint-disable-line not-rely-on-time */
        ) {
            revert Rebalance(uint256(2)); // TWAP cooldown must have elapsed
        }

        if (
            !(leverageInfo.currentLeverageRatio >
                myStrategy.methodology.maxLeverageRatio ||
                leverageInfo.currentLeverageRatio <
                myStrategy.methodology.minLeverageRatio)
        ) {
            revert Rebalance(uint256(3)); // Not valid leverage ratio
        }
        _handleRebalance(leverageInfo);
    }

    /**
     * ONLY OPERATOR: In case the current leverage ratio exceeds the protection leverage threshold, the protect function
     * can be called by authorized operators to return leverage ratio back a preset leverage ratio. This function 
     * typically would only be called during times of high downside volatility and / or normal keeper malfunctions.
     * The protection function uses it's own TWAP cooldown period, slippage tolerance and TWAP max trade size which are
     * typically looser than in regular rebalances but more restrictive than the ripcord parameters.
     *
     * @param _setToken         SetToken to protect
     * @param _exchangeName     Exchange used for trading
     * @param _swapData         Dynamic swap data passed to exchange adapter
     */
    function protect(
        ISetToken _setToken,
        string memory _exchangeName,
        bytes memory _swapData
    ) external onlyOperator(_setToken) {
        StrategySettings storage myStrategy = strategy[_setToken];

        (
            ConstituentInfo memory collateralAsset,
            ConstituentInfo memory borrowAsset
        ) = _getSetTokenConstituentInfo(_setToken);

        ActionInfo memory actionInfo = _createActionInfo(
            _setToken,
            collateralAsset,
            borrowAsset
        );
        LeverageInfo memory leverageInfo = _getAndValidateLeveragedInfo(
            _setToken,
            myStrategy.protection.slippageTolerance,
            myStrategy
                .exchangeSettings[_exchangeName]
                .protectionTwapMaxTradeSize,
            _exchangeName,
            actionInfo,
            _swapData
        );

        if (
            leverageInfo.currentLeverageRatio <
            myStrategy.protection.thresholdLeverageRatio
        ) {
            revert Protect(uint256(1)); // Must be above protection leverage ratio
        }
        // If currently in the midst of a TWAP rebalance, ensure that the cooldown period has elapsed
        if (
            !(myStrategy
                .exchangeSettings[_exchangeName]
                .exchangeLastTradeTimestamp +
                myStrategy.protection.twapCooldownPeriod <
                block.timestamp) /* solhint-disable-line not-rely-on-time */
        ) {
            revert Protect(uint256(2)); // TWAP cooldown must have elapsed
        }

        (uint256 chunkRebalanceNotional, ) = _calculateChunkRebalanceNotional(
            leverageInfo,
            myStrategy.protection.resetLeverageRatio,
            false,
            true
        );

        _delever(leverageInfo, chunkRebalanceNotional, _swapData);

        _updateLastTradeTimestamp(_setToken, _exchangeName);

        emit ProtectionCalled(
            address(_setToken),
            leverageInfo.currentLeverageRatio,
            getCurrentOnchainLeverageRatio(_setToken),
            chunkRebalanceNotional
        );
    }

    /**
     * ANYONE CALLABLE: In case the current leverage ratio exceeds the incentivized leverage threshold, the ripcord 
     * function can be called by anyone to return leverage ratio back to a preset leverage ratio. This function 
     * typically would only be called during times of high downside volatility and / or normal keeper malfunctions. The
     * caller of ripcord() will receive a reward in Ether. The ripcord function uses it's own TWAP cooldown period,
     * slippage tolerance and TWAP max trade size which are typically looser than in regular rebalances.
     *
     * @param _setToken         SetToken to ripcord
     * @param _exchangeName     Exchange used for trading
     */
    function ripcord(
        ISetToken _setToken,
        string memory _exchangeName
    ) external {
        StrategySettings storage myStrategy = strategy[_setToken];

        if (myStrategy.exchangeSettings[_exchangeName].hasDynamicData) {
            revert Ripcord(uint256(1)); // Can't use dynamic adapter"
        }

        (
            ConstituentInfo memory collateralAsset,
            ConstituentInfo memory borrowAsset
        ) = _getSetTokenConstituentInfo(_setToken);

        ActionInfo memory actionInfo = _createActionInfo(
            _setToken,
            collateralAsset,
            borrowAsset
        );

        LeverageInfo memory leverageInfo = _getAndValidateLeveragedInfo(
            _setToken,
            myStrategy.incentive.slippageTolerance,
            myStrategy
                .exchangeSettings[_exchangeName]
                .incentivizedTwapMaxTradeSize,
            _exchangeName,
            actionInfo,
            ""
        );

        // Use the exchangeLastTradeTimestamp so it can ripcord quickly with multiple exchanges
        _validateRipcord(
            _setToken,
            leverageInfo.currentLeverageRatio,
            myStrategy
                .exchangeSettings[_exchangeName]
                .exchangeLastTradeTimestamp
        );

        (uint256 chunkRebalanceNotional, ) = _calculateChunkRebalanceNotional(
            leverageInfo,
            myStrategy.incentive.resetLeverageRatio,
            false,
            true
        );

        _delever(leverageInfo, chunkRebalanceNotional, "");

        _updateLastTradeTimestamp(_setToken, _exchangeName);

        uint256 etherTransferred = _transferEtherRewardToCaller(
            myStrategy.incentive.etherReward
        );

        emit RipcordCalled(
            address(_setToken),
            leverageInfo.currentLeverageRatio,
            getCurrentOnchainLeverageRatio(_setToken),
            chunkRebalanceNotional,
            etherTransferred
        );
    }

    /**
     * ONLY OWNER AND VALID MANAGER: Return leverage ratio to 1x and delever to repay loan. This can be used for 
     * upgrading or shutting down the strategy. SetToken will redeem collateral position and trade for debt position
     * to repay Aave. If the chunk rebalance size is less than the total notional size, then this function will delever
     * and repay entire borrow balance on Aave. If chunk rebalance size is above max borrow or max trade size, then 
     * operator must continue to call this function to complete repayment of loan.
     * Note: Delever to 0 will likely result in additional units of the borrow asset added as equity on the SetToken
     * due to oracle price / market price mismatch
     *
     * @param _setToken         SetToken to disengage
     * @param _exchangeName     Exchange used for trading
     * @param _swapData         Dynamic swap data passed to exchange adapter
     */
    function disengage(
        ISetToken _setToken,
        string memory _exchangeName,
        bytes memory _swapData
    ) external onlyOwnerAndValidManager(_manager(_setToken)) {
        StrategySettings storage myStrategy = strategy[_setToken];

        (
            ConstituentInfo memory collateralAsset,
            ConstituentInfo memory borrowAsset
        ) = _getSetTokenConstituentInfo(_setToken);

        ActionInfo memory actionInfo = _createActionInfo(
            _setToken,
            collateralAsset,
            borrowAsset
        );
        LeverageInfo memory leverageInfo = _getAndValidateLeveragedInfo(
            _setToken,
            myStrategy.execution.slippageTolerance,
            myStrategy.exchangeSettings[_exchangeName].twapMaxTradeSize,
            _exchangeName,
            actionInfo,
            _swapData
        );

        uint256 newLeverageRatio = PreciseUnitMath.preciseUnit();

        (
            uint256 chunkRebalanceNotional,
            uint256 totalRebalanceNotional
        ) = _calculateChunkRebalanceNotional(
                leverageInfo,
                newLeverageRatio,
                false,
                true
            );

        if (totalRebalanceNotional > chunkRebalanceNotional) {
            _delever(leverageInfo, chunkRebalanceNotional, _swapData);
        } else {
            _deleverToZeroBorrowBalance(
                leverageInfo,
                totalRebalanceNotional,
                _swapData
            );
        }

        emit Disengaged(
            address(_setToken),
            leverageInfo.currentLeverageRatio,
            getCurrentOnchainLeverageRatio(_setToken),
            chunkRebalanceNotional,
            totalRebalanceNotional
        );
    }

    /**
     * ONLY METHODOLOGIST: Set methodology settings and check new settings are valid. 
     * Note: Need to pass in existing parameters if only changing a few settings. Must not be in a rebalance.
     *
     * @param _setToken                        SetToken to change its methodology params
     * @param _newMethodologySettings          Struct containing methodology parameters
     */
    function setMethodologySettings(
        ISetToken _setToken,
        MethodologySettings memory _newMethodologySettings
    ) external onlyMethodologist(_setToken) {
        StrategySettings storage myStrategy = strategy[_setToken];

        _validateNonExchangeSettings(
            _newMethodologySettings,
            myStrategy.execution,
            myStrategy.protection,
            myStrategy.incentive
        );
        myStrategy.methodology = _newMethodologySettings;

        emit MethodologySettingsUpdated(
            address(_setToken),
            _newMethodologySettings.targetLeverageRatio,
            _newMethodologySettings.minLeverageRatio,
            _newMethodologySettings.maxLeverageRatio
        );
    }

    /**
     * ONLY METHODOLOGIST: Set execution settings and check new settings are valid. 
     * Note: Need to pass in existing parameters if only changing a few settings. Must not be in a rebalance.
     *
     * @param _setToken                     SetToken to change its execution parameters
     * @param _newExecutionSettings         Struct containing execution parameters
     */
    function setExecutionSettings(
        ISetToken _setToken,
        ExecutionSettings memory _newExecutionSettings
    ) external onlyMethodologist(_setToken) {
        StrategySettings storage myStrategy = strategy[_setToken];

        _validateNonExchangeSettings(
            myStrategy.methodology,
            _newExecutionSettings,
            myStrategy.protection,
            myStrategy.incentive
        );

        myStrategy.execution = _newExecutionSettings;

        emit ExecutionSettingsUpdated(
            address(_setToken),
            _newExecutionSettings.unutilizedLeveragePercentage,
            _newExecutionSettings.twapCooldownPeriod,
            _newExecutionSettings.slippageTolerance
        );
    }

    /**
     * ONLY METHODOLOGIST: Set protection settings and check new settings are valid.
     * Note: Need to pass in existing parameters if only changing a few settings. Must not be in a rebalance.
     *
     * @param _setToken                       SetToken to change its protection parameters
     * @param _newProtectionSettings          Struct containing protection parameters
     */
    function setProtectionSettings(
        ISetToken _setToken,
        ProtectionSettings memory _newProtectionSettings
    ) external onlyMethodologist(_setToken) {
        StrategySettings storage myStrategy = strategy[_setToken];

        _validateNonExchangeSettings(
            myStrategy.methodology,
            myStrategy.execution,
            _newProtectionSettings,
            myStrategy.incentive
        );

        myStrategy.protection = _newProtectionSettings;

        emit ProtectionSettingsUpdated(
            address(_setToken),
            _newProtectionSettings.thresholdLeverageRatio,
            _newProtectionSettings.resetLeverageRatio,
            _newProtectionSettings.slippageTolerance,
            _newProtectionSettings.twapCooldownPeriod
        );
    }

    /**
     * ONLY METHODOLOGIST: Set incentive settings and check new settings are valid.
     * Note: Need to pass in existing parameters if only changing a few settings. Must not be in a rebalance.
     *
     * @param _setToken                      SetToken to change its incentive parameters
     * @param _newIncentiveSettings          Struct containing incentive parameters
     */
    function setIncentiveSettings(
        ISetToken _setToken,
        IncentiveSettings memory _newIncentiveSettings
    ) external onlyMethodologist(_setToken) {
        StrategySettings storage myStrategy = strategy[_setToken];

        _validateNonExchangeSettings(
            myStrategy.methodology,
            myStrategy.execution,
            myStrategy.protection,
            _newIncentiveSettings
        );

        myStrategy.incentive = _newIncentiveSettings;

        emit IncentiveSettingsUpdated(
            address(_setToken),
            _newIncentiveSettings.etherReward,
            _newIncentiveSettings.thresholdLeverageRatio,
            _newIncentiveSettings.resetLeverageRatio,
            _newIncentiveSettings.slippageTolerance,
            _newIncentiveSettings.twapCooldownPeriod
        );
    }

    /**
     * ONLY METHODOLOGIST: Add a new enabled exchange for trading during rebalances. New exchanges will have their
     * exchangeLastTradeTimestamp set to 0. Adding exchanges during rebalances is allowed, as it is not possible to
     * enter an unexpected state while doing so.
     *
     * @param _setToken             SetToken to enable the exchange
     * @param _exchangeName         Name of the exchange
     * @param _exchangeSettings     Struct containing exchange parameters
     */
    function addEnabledExchange(
        ISetToken _setToken,
        string memory _exchangeName,
        ExchangeSettings memory _exchangeSettings
    ) external onlyMethodologist(_setToken) {
        StrategySettings storage myStrategy = strategy[_setToken];

        if (myStrategy.exchangeSettings[_exchangeName].twapMaxTradeSize != 0) {
            revert AddEnabledExchange(uint256(1)); // Exchange already enabled
        }

        _validateExchangeSettings(_exchangeSettings);

        myStrategy.exchangeSettings[_exchangeName] = _exchangeSettings;

        myStrategy.enabledExchanges.push(_exchangeName);

        emit ExchangeAdded(
            address(_setToken),
            _exchangeName,
            _exchangeSettings.twapMaxTradeSize,
            _exchangeSettings.exchangeLastTradeTimestamp,
            _exchangeSettings.protectionTwapMaxTradeSize,
            _exchangeSettings.incentivizedTwapMaxTradeSize,
            _exchangeSettings.leverExchangeData,
            _exchangeSettings.deleverExchangeData,
            _exchangeSettings.adapterAddress,
            _exchangeSettings.hasDynamicData
        );
    }

    /**
     * ONLY METHODOLOGIST: Removes an exchange. Reverts if the exchange is not already enabled. Removing exchanges
     * during rebalances is allowed, as it is not possible to enter an unexpected state while doing so.
     *
     * @param _setToken         SetToken to remove the exchange
     * @param _exchangeName     Name of exchange to remove
     */
    function removeEnabledExchange(
        ISetToken _setToken,
        string memory _exchangeName
    ) external onlyMethodologist(_setToken) {
        StrategySettings storage myStrategy = strategy[_setToken];

        if (myStrategy.exchangeSettings[_exchangeName].twapMaxTradeSize == 0) {
            revert RemoveEnabledExchange(uint256(1)); // Exchange not enabled
        }

        delete myStrategy.exchangeSettings[_exchangeName];
        myStrategy.enabledExchanges.removeStorage(_exchangeName);

        emit ExchangeRemoved(address(_setToken), _exchangeName);
    }

    /**
     * ONLY METHODOLOGIST: Updates the settings of an exchange. Reverts if exchange is not already added. When updating
     * an exchange, exchangeLastTradeTimestamp is preserved. Updating exchanges during rebalances is allowed, as it is
     * not possible to enter an unexpected state while doing so.
     * Note: Need to pass in all existing parameters even if only changing a few settings.
     *
     * @param _setToken             SetToken to update the exchange
     * @param _exchangeName         Name of the exchange
     * @param _exchangeSettings     Struct containing exchange parameters
     */
    function updateEnabledExchange(
        ISetToken _setToken,
        string memory _exchangeName,
        ExchangeSettings memory _exchangeSettings
    ) external onlyMethodologist(_setToken) {
        StrategySettings storage myStrategy = strategy[_setToken];

        if (myStrategy.exchangeSettings[_exchangeName].twapMaxTradeSize == 0) {
            revert UpdateEnabledExchange(uint256(1)); // Exchange not enabled
        }

        _validateExchangeSettings(_exchangeSettings);

        myStrategy.exchangeSettings[_exchangeName] = _exchangeSettings;

        emit ExchangeUpdated(
            address(_setToken),
            _exchangeName,
            _exchangeSettings.twapMaxTradeSize,
            _exchangeSettings.exchangeLastTradeTimestamp,
            _exchangeSettings.protectionTwapMaxTradeSize,
            _exchangeSettings.incentivizedTwapMaxTradeSize,
            _exchangeSettings.leverExchangeData,
            _exchangeSettings.deleverExchangeData,
            _exchangeSettings.adapterAddress,
            _exchangeSettings.hasDynamicData
        );
    }

    /**
     * ONLY OWNER AND VALID MANAGER: Withdraw entire balance of ETH in this contract to operator.
     * Rebalance must not be in progress
     *
     * @param _setToken             SetToken to update the exchange
     */
    function withdrawEtherBalance(
        ISetToken _setToken
    ) external onlyOwnerAndValidManager(_manager(_setToken)) {
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {
        this;
    }

    /**
     * ONLY OWNER AND VALID MANAGER: Initializes AaveLeverageModule on the SetToken associated with the 
     * DelegatedManager
     *
     * @param _delegatedManager             Instance of the DelegatedManager to initialize the TradeModule for
     * @param _collateralAssets             Underlying tokens to be enabled as collateral in the SetToken
     * @param _borrowAssets                 Underlying tokens to be enabled as borrow in the SetToken
     */
    function initializeModule(
        IDelegatedManager _delegatedManager,
        address[] memory _collateralAssets,
        address[] memory _borrowAssets
    ) external onlyOwnerAndValidManager(_delegatedManager) {
        if (!_delegatedManager.isInitializedExtension(address(this))) {
            revert InitializeModule(uint256(1)); // Extension must be initialized
        }

        _initializeModule(_delegatedManager, _collateralAssets, _borrowAssets);
    }

    /**
     * ONLY OWNER AND VALID MANAGER: Initializes AaveLeverageExtension to the DelegatedManager and adds
     * its associated setToken to extension's supported tokens
     *
     * @param _delegatedManager     Instance of the DelegatedManager to initialize
     * @param _methodology          Methodology settings
     * @param _execution            Execution settings
     * @param _protection           Protection settings
     * @param _incentive            Incetive settings (Ripcord)
     */
    function initializeExtension(
        IDelegatedManager _delegatedManager,
        MethodologySettings memory _methodology,
        ExecutionSettings memory _execution,
        ProtectionSettings memory _protection,
        IncentiveSettings memory _incentive
    ) external onlyOwnerAndValidManager(_delegatedManager) {
        if (!_delegatedManager.isPendingExtension(address(this))) {
            revert InitializeExtension(uint256(1)); // Extension must be pending
        }

        ISetToken _setToken = _delegatedManager.setToken();

        // Add its parameters
        StrategySettings storage myStrategy = strategy[_setToken];

        _validateNonExchangeSettings(
            _methodology,
            _execution,
            _protection,
            _incentive
        );

        myStrategy.methodology = _methodology;
        myStrategy.execution = _execution;
        myStrategy.protection = _protection;
        myStrategy.incentive = _incentive;

        _initializeExtension(_setToken, _delegatedManager);

        emit AaveLeverageExtensionInitialized(
            address(_setToken),
            address(_delegatedManager)
        );
    }

    /**
     * ONLY MANAGER: Remove an existing SetToken and DelegatedManager tracked by the AaveLeverageExtension
     *
     */
    function removeExtension() external override {
        IDelegatedManager delegatedManager = IDelegatedManager(msg.sender);
        ISetToken setToken = delegatedManager.setToken();

        _removeExtension(setToken, _manager(delegatedManager.setToken()));
    }

    /* ============ External Getter Functions ============ */

    /**
     * Gets exchange settings
     *
     * @param _setToken     SetToken to get its enabled exchanges
     * @param _exchangeName Exchange name
     *
     * @return ExchangeSettings
     */
    function getExchangeSettings(
        ISetToken _setToken,
        string memory _exchangeName
    ) external view returns (ExchangeSettings memory) {
        return strategy[_setToken].exchangeSettings[_exchangeName];
    }

    /**
     * Gets the list of enabled exchanges
     *
     * @param _setToken     SetToken to get its enabled exchanges
     *
     * @return string[] memory     Array of enabled exchanges
     */
    function getEnabledExchanges(
        ISetToken _setToken
    ) external view returns (string[] memory) {
        return strategy[_setToken].enabledExchanges;
    }

    /**
     * Get current onchain leverage ratio. Current leverage ratio is defined as the USD value of the 
     * collateral divided by the USD value of the SetToken. Prices for collateral and borrow asset are
     * retrieved from the Chainlink Price Oracle.
     *
     * @param _setToken     SetToken to get its current leverage ratio
     *
     * @return currentLeverageRatio         Current leverage ratio in precise units (10e18)
     */
    function getCurrentOnchainLeverageRatio(
        ISetToken _setToken
    ) public view returns (uint256) {
        (
            ConstituentInfo memory collateralAsset,
            ConstituentInfo memory borrowAsset
        ) = _getSetTokenConstituentInfo(_setToken);
        ActionInfo memory currentLeverageInfo = _createActionInfo(
            _setToken,
            collateralAsset,
            borrowAsset
        );

        return
            _calculateCurrentLeverageRatio(
                currentLeverageInfo.collateralValue,
                currentLeverageInfo.borrowValue
            );
    }

    /**
     * Get current offchain leverage ratio. Current leverage ratio is defined as the USD value of the
     * collateral divided by the USD value of the SetToken. Prices for collateral and borrow asset are
     * provided in gwei (18 decimals).
     *
     * @param _setToken            SetToken to get its current offchain leverage ratio
     * @param _collateralPrice     Collateral price
     * @param _borrowPrice         Borrow price
     *
     * @return currentOffchainLeverageRatio         Current offchain leverage ratio in precise units (10e18)
     */
    function getCurrentOffchainLeverageRatio(
        ISetToken _setToken,
        uint256 _collateralPrice,
        uint256 _borrowPrice
    ) external view returns (uint256) {
        (
            ConstituentInfo memory collateralAsset,
            ConstituentInfo memory borrowAsset
        ) = _getSetTokenConstituentInfo(_setToken);
        collateralAsset.price = _collateralPrice;
        borrowAsset.price = _borrowPrice;

        ActionInfo memory currentLeverageInfo = _createActionInfo(
            _setToken,
            collateralAsset,
            borrowAsset
        );

        return
            _calculateCurrentLeverageRatio(
                currentLeverageInfo.collateralValue,
                currentLeverageInfo.borrowValue
            );
    }

    /**
     * Calculates the chunk rebalance size.
     * Note: this function does not take into account timestamps, so it may return a nonzero value even when
     * shouldRebalance would return ShouldRebalance.NONE for all exchanges (since minimum delays have not elapsed)
     *
     * @param _setToken         SetToken to get chunk notional
     * @param _exchangeNames    Array of exchange names to get rebalance sizes for
     * @param _collateralPrice  Collateral price
     * @param _borrowPrice      Borrow price
     *
     * @return sizes            Array of total notional chunk size. Measured in the asset that would be sold
     * @return isLever          Rebalance direction
     */
    function getChunkRebalanceNotional(
        ISetToken _setToken,
        string[] calldata _exchangeNames,
        uint256 _collateralPrice,
        uint256 _borrowPrice
    ) external view returns (uint256[] memory sizes, bool isLever) {
        StrategySettings storage myStrategy = strategy[_setToken];

        uint256 newLeverageRatio;
        bool isProtection;

        (
            ConstituentInfo memory collateralAsset,
            ConstituentInfo memory borrowAsset
        ) = _getSetTokenConstituentInfo(_setToken);
        ActionInfo memory actionInfo = _createActionInfo(
            _setToken,
            collateralAsset,
            borrowAsset
        );
        uint256 currentLeverageRatio = _calculateCurrentLeverageRatio(
            actionInfo.collateralValue,
            actionInfo.borrowValue
        );

        // if over protection leverage ratio, always protect
        if (
            currentLeverageRatio > myStrategy.protection.thresholdLeverageRatio
        ) {
            newLeverageRatio = myStrategy.protection.resetLeverageRatio;
            isProtection = true;
            // Else just use the normal rebalance new leverage ratio calculation
        } else {
            collateralAsset.price = _collateralPrice;
            borrowAsset.price = _borrowPrice;
            actionInfo = _createActionInfo(
                _setToken,
                collateralAsset,
                borrowAsset
            );
            currentLeverageRatio = _calculateCurrentLeverageRatio(
                actionInfo.collateralValue,
                actionInfo.borrowValue
            );
            newLeverageRatio = myStrategy.methodology.targetLeverageRatio;
        }

        isLever = newLeverageRatio > currentLeverageRatio;

        sizes = _getAllChunkNotionalSizes(
            _setToken,
            _exchangeNames,
            actionInfo,
            currentLeverageRatio,
            newLeverageRatio,
            isProtection,
            isLever
        );
    }

    /**
     * Calculates the chunk rebalance size in case of Ripcord only. This can be used by external contracts and
     * keeper bots to calculate the optimal exchange to ripcord with.
     * Note: this function does not take into account timestamps, so it may return a nonzero value even when
     * shouldRebalance would return ShouldRebalance.NONE for all exchanges (since minimum delays have not elapsed)
     *
     * @param _setToken         SetToken to get chunk notional for ripcord
     * @param _exchangeNames    Array of exchange names to get rebalance sizes for
     *
     * @return sizes            Array of total notional chunk size. Measured in the asset that would be sold
     */
    function getChunkRebalanceNotionalRipcord(
        ISetToken _setToken,
        string[] calldata _exchangeNames
    ) external view returns (uint256[] memory sizes) {
        StrategySettings storage myStrategy = strategy[_setToken];

        uint256 currentLeverageRatio = getCurrentOnchainLeverageRatio(
            _setToken
        );

        sizes = new uint256[](_exchangeNames.length);

        if (
            currentLeverageRatio > myStrategy.incentive.thresholdLeverageRatio
        ) {
            (
                ConstituentInfo memory collateralAsset,
                ConstituentInfo memory borrowAsset
            ) = _getSetTokenConstituentInfo(_setToken);

            sizes = _getAllChunkNotionalSizes(
                _setToken,
                _exchangeNames,
                _createActionInfo(_setToken, collateralAsset, borrowAsset),
                currentLeverageRatio,
                myStrategy.incentive.resetLeverageRatio,
                true,
                false
            );
        }
    }

    /**
     * Get current Ether incentive for when current leverage ratio exceeds incentivized leverage ratio and ripcord
     * can be called. If ETH balance on the contract is below the etherReward, then return the balance of ETH instead.
     *
     * @param _setToken         SetToken to get the incentive eth reward
     *
     * @return etherReward      Quantity of ETH reward in base units (10e18)
     */
    function getCurrentEtherIncentive(
        ISetToken _setToken
    ) external view returns (uint256) {
        StrategySettings storage myStrategy = strategy[_setToken];

        if (
            getCurrentOnchainLeverageRatio(_setToken) >=
            myStrategy.incentive.thresholdLeverageRatio
        ) {
            // If ETH reward is below the balance on this contract, then return ETH balance on contract instead
            return
                myStrategy.incentive.etherReward < address(this).balance
                    ? myStrategy.incentive.etherReward
                    : address(this).balance;
        } else {
            return 0;
        }
    }

    /**
     * Helper that checks if conditions are met for rebalance or protection.
     * Returns an enum with 0 = no rebalance, 1 = call rebalance(), 2 = call protection()
     *
     * @param _setToken             SetToken to get the rebalance state
     * @param _collateralPrice      Offchain collateral price
     * @param _borrowPrice          Offchain borrow price
     *
     * @return (string[], ShouldRebalance[])  Two memory arrays that indicates if rebalance is needed per exchange
     */
    function shouldRebalance(
        ISetToken _setToken,
        uint256 _collateralPrice,
        uint256 _borrowPrice
    ) external view returns (string[] memory, ShouldRebalance[] memory) {
        StrategySettings storage myStrategy = strategy[_setToken];

        (
            ConstituentInfo memory collateralAsset,
            ConstituentInfo memory borrowAsset
        ) = _getSetTokenConstituentInfo(_setToken);
        collateralAsset.price = _collateralPrice;
        borrowAsset.price = _borrowPrice;

        ActionInfo memory currentLeverageInfo = _createActionInfo(
            _setToken,
            collateralAsset,
            borrowAsset
        );

        return
            _shouldRebalance(
                _setToken,
                _calculateCurrentLeverageRatio(
                    currentLeverageInfo.collateralValue,
                    currentLeverageInfo.borrowValue
                ),
                getCurrentOnchainLeverageRatio(_setToken),
                myStrategy.methodology.minLeverageRatio,
                myStrategy.methodology.maxLeverageRatio
            );
    }

    /**
     * Helper that checks if conditions are met for ripcord. Returns an enum with 0 = no ripcord or 1 = call ripcord()
     *
     * @param _setToken                       SetToken to get the ripcord state
     *
     * @return (string[], ShouldRebalance[])  Two memory arrays that indicates if ripcord is needed per exchange
     */
    function shouldRipcord(
        ISetToken _setToken
    ) external view returns (string[] memory, ShouldRipcord[] memory) {
        return
            _shouldRipcord(
                _setToken,
                getCurrentOnchainLeverageRatio(_setToken)
            );
    }

    /**
     * Helper that checks if conditions are met for rebalance or protection with custom max and min bounds specified 
     * by caller. This function simplifies the logic for off-chain keeper bots to determine what threshold to call 
     * rebalance when leverage exceeds max or drops below min.
     * Returns an enum with 0 = no rebalance, 1 = call rebalance(), 2 = call protect()
     *
     * @param _setToken                        SetToken to get its rebalance state
     * @param _customMinLeverageRatio          Min leverage ratio passed in by caller
     * @param _customMaxLeverageRatio          Max leverage ratio passed in by caller
     * @param _collateralPrice                 Offchain collateral price
     * @param _borrowPrice                     Offchain borrow price
     *
     * @return (string[], ShouldRebalance[])   Two memory arrays that indicates if rebalance is needed per exchange
     */
    function shouldRebalanceWithBounds(
        ISetToken _setToken,
        uint256 _customMinLeverageRatio,
        uint256 _customMaxLeverageRatio,
        uint256 _collateralPrice,
        uint256 _borrowPrice
    ) external view returns (string[] memory, ShouldRebalance[] memory) {
        StrategySettings storage myStrategy = strategy[_setToken];

        if (
            _customMinLeverageRatio > myStrategy.methodology.minLeverageRatio ||
            _customMaxLeverageRatio < myStrategy.methodology.maxLeverageRatio
        ) {
            revert ShouldRebalanceWithBounds(uint256(1)); // Custom bounds must be valid
        }

        (
            ConstituentInfo memory collateralAsset,
            ConstituentInfo memory borrowAsset
        ) = _getSetTokenConstituentInfo(_setToken);
        collateralAsset.price = _collateralPrice;
        borrowAsset.price = _borrowPrice;

        ActionInfo memory currentLeverageInfo = _createActionInfo(
            _setToken,
            collateralAsset,
            borrowAsset
        );

        return
            _shouldRebalance(
                _setToken,
                _calculateCurrentLeverageRatio(
                    currentLeverageInfo.collateralValue,
                    currentLeverageInfo.borrowValue
                ),
                getCurrentOnchainLeverageRatio(_setToken),
                _customMinLeverageRatio,
                _customMaxLeverageRatio
            );
    }

    /* ============ Internal Functions ============ */

    /**
     * Calculate notional rebalance quantity, whether to chunk rebalance based on max trade size and max borrow and
     * invoke lever on AaveLeverageModule
     *
     */
    function _lever(
        LeverageInfo memory _leverageInfo,
        uint256 _chunkRebalanceNotional,
        bytes memory _swapData
    ) internal {
        StrategySettings storage myStrategy = strategy[_leverageInfo.setToken];

        uint256 collateralRebalanceUnits = _chunkRebalanceNotional.preciseDiv(
            _leverageInfo.action.setTotalSupply
        );

        uint256 borrowUnits = _calculateBorrowUnits(
            collateralRebalanceUnits,
            _leverageInfo.action
        );

        uint256 minReceiveCollateralUnits = collateralRebalanceUnits.preciseMul(
            PreciseUnitMath.preciseUnit() - _leverageInfo.slippageTolerance
        );

        bytes memory leverCallData = abi.encodeWithSignature(
            "lever(address,address,address,uint256,uint256,string,bytes)",
            address(_leverageInfo.setToken),
            _leverageInfo.action.borrowAsset,
            _leverageInfo.action.collateralAsset,
            borrowUnits,
            minReceiveCollateralUnits,
            _leverageInfo.exchangeName,
            myStrategy
                .exchangeSettings[_leverageInfo.exchangeName]
                .hasDynamicData
                ? _swapData
                : myStrategy
                    .exchangeSettings[_leverageInfo.exchangeName]
                    .leverExchangeData
        );
        _invokeManager(
            _manager(_leverageInfo.setToken),
            address(leverageModule),
            leverCallData
        );
    }

    /**
     * Calculate delever units Invoke delever on AaveLeverageModule.
     */
    function _delever(
        LeverageInfo memory _leverageInfo,
        uint256 _chunkRebalanceNotional,
        bytes memory _swapData
    ) internal {
        StrategySettings storage myStrategy = strategy[_leverageInfo.setToken];

        uint256 collateralRebalanceUnits = _chunkRebalanceNotional.preciseDiv(
            _leverageInfo.action.setTotalSupply
        );

        uint256 minRepayUnits = collateralRebalanceUnits
            .preciseMul(_leverageInfo.action.collateralPrice)
            .preciseDiv(_leverageInfo.action.borrowPrice)
            .preciseMul(
                PreciseUnitMath.preciseUnit() - _leverageInfo.slippageTolerance
            );

        bytes memory deleverCallData = abi.encodeWithSignature(
            "delever(address,address,address,uint256,uint256,string,bytes)",
            address(_leverageInfo.setToken),
            _leverageInfo.action.collateralAsset,
            _leverageInfo.action.borrowAsset,
            collateralRebalanceUnits,
            minRepayUnits,
            _leverageInfo.exchangeName,
            myStrategy
                .exchangeSettings[_leverageInfo.exchangeName]
                .hasDynamicData
                ? _swapData
                : myStrategy
                    .exchangeSettings[_leverageInfo.exchangeName]
                    .deleverExchangeData
        );

        _invokeManager(
            _manager(_leverageInfo.setToken),
            address(leverageModule),
            deleverCallData
        );
    }

    /**
     * Invoke deleverToZeroBorrowBalance on AaveLeverageModule.
     */
    function _deleverToZeroBorrowBalance(
        LeverageInfo memory _leverageInfo,
        uint256 _chunkRebalanceNotional,
        bytes memory _swapData
    ) internal {
        StrategySettings storage myStrategy = strategy[_leverageInfo.setToken];

        // Account for slippage tolerance in redeem quantity for the deleverToZeroBorrowBalance function
        uint256 maxCollateralRebalanceUnits = (
            myStrategy
                .exchangeSettings[_leverageInfo.exchangeName]
                .hasDynamicData
                ? _chunkRebalanceNotional
                : _chunkRebalanceNotional.preciseMul(
                    PreciseUnitMath.preciseUnit() +
                        myStrategy.execution.slippageTolerance
                )
        ).preciseDiv(_leverageInfo.action.setTotalSupply);

        bytes memory deleverToZeroBorrowBalanceCallData = abi
            .encodeWithSignature(
                "deleverToZeroBorrowBalance(address,address,address,uint256,string,bytes)",
                address(_leverageInfo.setToken),
                _leverageInfo.action.collateralAsset,
                _leverageInfo.action.borrowAsset,
                maxCollateralRebalanceUnits,
                _leverageInfo.exchangeName,
                myStrategy
                    .exchangeSettings[_leverageInfo.exchangeName]
                    .hasDynamicData
                    ? _swapData
                    : myStrategy
                        .exchangeSettings[_leverageInfo.exchangeName]
                        .deleverExchangeData
            );

        _invokeManager(
            _manager(_leverageInfo.setToken),
            address(leverageModule),
            deleverToZeroBorrowBalanceCallData
        );
    }

    /**
     * Check whether to lever/delever based on the current vs target leverage ratios.
     * Used in the rebalance() functions
     */
    function _handleRebalance(LeverageInfo memory _leverageInfo) internal {
        uint256 chunkRebalanceNotional;
        uint256 totalRebalanceNotional;

        StrategySettings storage myStrategy = strategy[_leverageInfo.setToken];
        uint256 targetLeverageRatio = myStrategy
            .methodology
            .targetLeverageRatio;

        if (targetLeverageRatio < _leverageInfo.currentLeverageRatio) {
            (
                chunkRebalanceNotional,
                totalRebalanceNotional
            ) = _calculateChunkRebalanceNotional(
                _leverageInfo,
                targetLeverageRatio,
                false,
                true
            );
            _delever(
                _leverageInfo,
                chunkRebalanceNotional,
                _leverageInfo.swapData
            );
        } else {
            (
                chunkRebalanceNotional,
                totalRebalanceNotional
            ) = _calculateChunkRebalanceNotional(
                _leverageInfo,
                targetLeverageRatio,
                true,
                true
            );
            _lever(
                _leverageInfo,
                chunkRebalanceNotional,
                _leverageInfo.swapData
            );
        }

        if (
            !(getCurrentOnchainLeverageRatio(_leverageInfo.setToken) <
                myStrategy.protection.thresholdLeverageRatio)
        ) {
            revert HandleRebalance(uint256(1)); // External prices deviate from oracles
        }

        _updateLastTradeTimestamp(
            _leverageInfo.setToken,
            _leverageInfo.exchangeName
        );

        emit Rebalanced(
            address(_leverageInfo.setToken),
            _leverageInfo.currentLeverageRatio,
            getCurrentOnchainLeverageRatio(_leverageInfo.setToken),
            chunkRebalanceNotional,
            totalRebalanceNotional
        );
    }

    /**
     * Internal function to initialize AaveLeverageModule on the SetToken associated with the DelegatedManager.
     *
     * @param _delegatedManager             Instance of the DelegatedManager to initialize the TradeModule for
     * @param _collateralAssets             Underlying tokens to be enabled as collateral in the SetToken
     * @param _borrowAssets                 Underlying tokens to be enabled as borrow in the SetToken
     */
    function _initializeModule(
        IDelegatedManager _delegatedManager,
        address[] memory _collateralAssets,
        address[] memory _borrowAssets
    ) internal {
        bytes memory callData = abi.encodeWithSignature(
            "initialize(address,address[],address[])",
            _delegatedManager.setToken(),
            _collateralAssets,
            _borrowAssets
        );
        _invokeManager(_delegatedManager, address(leverageModule), callData);
    }

    /**
     * Create the leverage info struct to be used in internal functions
     *
     * @return LeverageInfo                Struct containing ActionInfo and other data
     */
    function _getAndValidateLeveragedInfo(
        ISetToken _setToken,
        uint256 _slippageTolerance,
        uint256 _maxTradeSize,
        string memory _exchangeName,
        ActionInfo memory actionInfo,
        bytes memory _swapData
    ) internal pure returns (LeverageInfo memory) {
        // Assume if maxTradeSize is 0, then the exchange is not enabled. 
        // This is enforced by addEnabledExchange and updateEnabledExchange
        if (_maxTradeSize == 0) {
            revert ValidateLeveragedInfo(uint256(1)); // Must be valid exchange
        }
        if (actionInfo.setTotalSupply == 0) {
            revert ValidateLeveragedInfo(uint256(2)); // SetToken must have > 0 supply
        }
        if (actionInfo.borrowBalance == 0) {
            revert ValidateLeveragedInfo(uint256(3)); // Borrow balance must exist
        }

        // Get current leverage ratio
        uint256 currentLeverageRatio = _calculateCurrentLeverageRatio(
            actionInfo.collateralValue,
            actionInfo.borrowValue
        );

        return
            LeverageInfo({
                setToken: _setToken,
                action: actionInfo,
                currentLeverageRatio: currentLeverageRatio,
                slippageTolerance: _slippageTolerance,
                twapMaxTradeSize: _maxTradeSize,
                exchangeName: _exchangeName,
                swapData: _swapData
            });
    }

    /**
     * Create the action info struct to be used in internal functions
     *
     * @param _collateralConstituent   Offchain collateral price
     * @param _borrowConstituent       Offchain borrow price
     *
     * @return ActionInfo              Struct containing data used by internal lever and delever functions
     */
    function _createActionInfo(
        ISetToken _setToken,
        ConstituentInfo memory _collateralConstituent,
        ConstituentInfo memory _borrowConstituent
    ) internal view returns (ActionInfo memory) {
        ActionInfo memory rebalanceInfo;

        // Prices with 18 decimal places, but we need 36 - underlyingDecimals decimal places.
        // This is so that when the underlying amount is multiplied by the received price,
        // the collateral valuation is normalized to 36 decimals.
        // To perform this adjustment, we multiply by 10^(36 - 8 - underlyingDecimals)

        ERC20 collateralAToken = ERC20(_collateralConstituent.aaveToken);
        ERC20 targetBorrowDebtToken = ERC20(_borrowConstituent.aaveToken);

        rebalanceInfo.collateralAsset = _collateralConstituent.asset;
        rebalanceInfo.borrowAsset = _borrowConstituent.asset;

        rebalanceInfo.collateralPrice =
            _collateralConstituent.price *
            (10 ** (uint256(18) - uint256(collateralAToken.decimals())));
        rebalanceInfo.borrowPrice =
            _borrowConstituent.price *
            (10 ** (uint256(18) - uint256(targetBorrowDebtToken.decimals())));

        rebalanceInfo.collateralBalance = collateralAToken.balanceOf(
            address(_setToken)
        );
        rebalanceInfo.borrowBalance = targetBorrowDebtToken.balanceOf(
            address(_setToken)
        );
        rebalanceInfo.collateralValue = rebalanceInfo
            .collateralPrice
            .preciseMul(rebalanceInfo.collateralBalance);
        rebalanceInfo.borrowValue = rebalanceInfo.borrowPrice.preciseMul(
            rebalanceInfo.borrowBalance
        );
        rebalanceInfo.setTotalSupply = _setToken.totalSupply();

        return rebalanceInfo;
    }

    /**
     * Calculate the current leverage ratio given a valuation of the collateral and borrow asset,
     * which is calculated as collateral USD valuation / SetToken USD valuation
     *
     * @param _collateralValue   Value of the collateral asset
     * @param _borrowValue       Value of the borrowed asset
     *
     * @return uint256            Current leverage ratio
     */
    function _calculateCurrentLeverageRatio(
        uint256 _collateralValue,
        uint256 _borrowValue
    ) internal pure returns (uint256) {
        return _collateralValue.preciseDiv(_collateralValue - _borrowValue);
    }

    /**
     * Calculate total notional rebalance quantity and chunked rebalance quantity in collateral units.
     *
     * @return uint256          Chunked rebalance notional in collateral units
     * @return uint256          Total rebalance notional in collateral units
     */
    function _calculateChunkRebalanceNotional(
        LeverageInfo memory _leverageInfo,
        uint256 _newLeverageRatio,
        bool _isLever,
        bool _isExecution
    ) internal view returns (uint256, uint256) {
        StrategySettings storage myStrategy = strategy[_leverageInfo.setToken];

        // Calculate absolute value of difference between new and current leverage ratio
        uint256 leverageRatioDifference = _isLever
            ? _newLeverageRatio - _leverageInfo.currentLeverageRatio
            : _leverageInfo.currentLeverageRatio - _newLeverageRatio;

        uint256 totalRebalanceNotional = leverageRatioDifference
            .preciseDiv(_leverageInfo.currentLeverageRatio)
            .preciseMul(_leverageInfo.action.collateralBalance);

        uint256 maxBorrow = _calculateMaxBorrowCollateral(
            _leverageInfo.setToken,
            _isLever,
            myStrategy.execution.unutilizedLeveragePercentage
        );

        uint256 chunkRebalanceNotional = Math.min(
            Math.min(maxBorrow, totalRebalanceNotional),
            _leverageInfo.twapMaxTradeSize
        );

        if (
            myStrategy
                .exchangeSettings[_leverageInfo.exchangeName]
                .hasDynamicData && _isExecution
        ) {
            (, , , uint256 fromTokenAmount, ) = IExchangeAdapter(
                myStrategy
                    .exchangeSettings[_leverageInfo.exchangeName]
                    .adapterAddress
            ).getTradeMetadata(_leverageInfo.swapData);
            uint256 amountToSell = _isLever
                ? fromTokenAmount
                    .preciseMul(_leverageInfo.action.borrowPrice)
                    .preciseDiv(_leverageInfo.action.collateralPrice)
                : fromTokenAmount;
            uint256 maxDiff = (uint256(5).preciseDiv(1000)); //TODO

            if (
                !amountToSell
                    .preciseDiv(chunkRebalanceNotional)
                    .approximatelyEquals(PreciseUnitMath.preciseUnit(), maxDiff)
            ) {
                revert CalculateChunkRebalanceNotional(uint256(1)); // Amount to sell too far from reference amount
            }
            chunkRebalanceNotional = amountToSell;

            if (
                totalRebalanceNotional
                    .preciseDiv(chunkRebalanceNotional)
                    .approximatelyEquals(PreciseUnitMath.preciseUnit(), maxDiff)
            ) totalRebalanceNotional = chunkRebalanceNotional;
        }

        return (chunkRebalanceNotional, totalRebalanceNotional);
    }

    /**
     * Calculate the max borrow / repay amount allowed in base units for lever / delever. 
     * This is due to overcollateralization requirements on assets deposited in lending protocols for borrowing.
     *
     * For lever, max borrow is calculated as:
     * (Net borrow limit in USD - existing borrow value in USD) / collateral asset price adjusted for decimals
     *
     * For delever, max repay is calculated as:
     * Collateral balance in base units * (USD net borrow limit - USD existing borrow value) / USD net borrow limit
     *
     * Net borrow limit for levering is calculated as:
     * The collateral value in USD * Aave collateral factor * (1 - unutilized leverage %)
     *
     * Net repay limit for delevering is calculated as:
     * The collateral value in USD * Aave liquiditon threshold * (1 - unutilized leverage %)
     *
     * @return uint256          Max borrow notional denominated in collateral asset
     */
    function _calculateMaxBorrowCollateral(
        ISetToken _setToken,
        bool _isLever,
        uint256 _unutilizedLeveragePercentage
    ) internal view returns (uint256) {
        // Use onchain prices to calculate max Borrow to align with Aave
        (
            ConstituentInfo memory collateralAsset,
            ConstituentInfo memory borrowAsset
        ) = _getSetTokenConstituentInfo(_setToken);
        ActionInfo memory _actionInfo = _createActionInfo(
            _setToken,
            collateralAsset,
            borrowAsset
        );

        // Retrieve collateral factor and liquidation threshold for the collateral asset in precise units (1e16 = 1%)
        (
            ,
            uint256 maxLtvRaw,
            uint256 liquidationThresholdRaw,
            ,
            ,
            ,
            ,
            ,
            ,

        ) = leverageModule.protocolDataProvider().getReserveConfigurationData(
                _actionInfo.collateralAsset
            );

        // Normalize LTV and liquidation threshold to precise units.
        // LTV is measured in 4 decimals in Aave which is why we must multiply by 1e14
        // for example ETH has an LTV value of 8000 which represents 80%
        if (_isLever) {
            uint256 netBorrowLimit = _actionInfo
                .collateralValue
                .preciseMul(maxLtvRaw * (10 ** 14))
                .preciseMul(
                    PreciseUnitMath.preciseUnit() -
                        _unutilizedLeveragePercentage
                );

            return
                netBorrowLimit -
                _actionInfo.borrowValue.preciseDiv(_actionInfo.collateralPrice);
        } else {
            uint256 netRepayLimit = _actionInfo
                .collateralValue
                .preciseMul(liquidationThresholdRaw * (10 ** 14))
                .preciseMul(
                    PreciseUnitMath.preciseUnit() -
                        _unutilizedLeveragePercentage
                );

            return
                _actionInfo
                    .collateralBalance
                    .preciseMul(netRepayLimit - _actionInfo.borrowValue)
                    .preciseDiv(netRepayLimit);
        }
    }

    /**
     * Derive the borrow units for lever.
     * The units are calculated by the collateral units multiplied by collateral / borrow asset price.
     * Output is measured to borrow unit decimals.
     *
     * @return uint256           Position units to borrow
     */
    function _calculateBorrowUnits(
        uint256 _collateralRebalanceUnits,
        ActionInfo memory _actionInfo
    ) internal pure returns (uint256) {
        return
            _collateralRebalanceUnits
                .preciseMul(_actionInfo.collateralPrice)
                .preciseDiv(_actionInfo.borrowPrice);
    }

    /**
     * Update globalLastTradeTimestamp and exchangeLastTradeTimestamp values.
     * This function updates both the exchange-specific and global timestamp so that the epoch rebalance can use
     * the global timestamp (since the global timestamp is always  equal to the most recently used exchange timestamp).
     * This allows for multiple rebalances to occur simultaneously since only the exchange-specific timestamp is checked
     * for non-epoch rebalances.
     */
    function _updateLastTradeTimestamp(
        ISetToken _setToken,
        string memory _exchangeName
    ) internal {
        StrategySettings storage myStrategy = strategy[_setToken];

        myStrategy.globalLastTradeTimestamp = block.timestamp; /* solhint-disable-line not-rely-on-time */
        myStrategy
            .exchangeSettings[_exchangeName]
            .exchangeLastTradeTimestamp = block.timestamp; /* solhint-disable-line not-rely-on-time */
    }

    /**
     * Transfer ETH reward to caller of the ripcord function. If the ETH balance on this contract is less than required
     * incentive quantity, then transfer contract balance instead to prevent reverts.
     *
     * @return uint256           Amount of ETH transferred to caller
     */
    function _transferEtherRewardToCaller(
        uint256 _etherReward
    ) internal returns (uint256) {
        uint256 etherToTransfer = _etherReward < address(this).balance
            ? _etherReward
            : address(this).balance;

        payable(msg.sender).transfer(etherToTransfer);

        return etherToTransfer;
    }

    /**
     * Internal function returning the constituents addresses
     *
     * @return collateralAsset      Collateral asset address
     * @return borrowAsset          Borrow asset address
     */
    function _getSetTokenConstituentInfo(
        ISetToken _setToken
    )
        internal
        view
        returns (
            ConstituentInfo memory collateralAsset,
            ConstituentInfo memory borrowAsset
        )
    {
        (
            address[] memory collaterals,
            address[] memory borrows
        ) = leverageModule.getEnabledAssets(_setToken);
        if (!(collaterals.length == 1 && borrows.length == 1)) {
            // SetToken does not contain one collateral and one borrow positions
            revert GetSetTokenConstituentInfo(uint256(1));
        }

        IPriceOracleGetter priceOracle = IPriceOracleGetter(
            leverageModule.lendingPoolAddressesProvider().getPriceOracle()
        );

        collateralAsset.asset = collaterals[0];
        collateralAsset.aaveToken = address(
            leverageModule
                .underlyingToReserveTokens(IERC20(collaterals[0]))
                .aToken
        );
        collateralAsset.price = priceOracle.getAssetPrice(
            collateralAsset.asset
        );

        borrowAsset.asset = borrows[0];
        borrowAsset.aaveToken = address(
            leverageModule
                .underlyingToReserveTokens(IERC20(borrows[0]))
                .variableDebtToken
        );
        borrowAsset.price = priceOracle.getAssetPrice(borrowAsset.asset);
    }

    /**
     * Internal function returning the chunk rebalance sizes.
     *
     * @return sizes            Array of total notional chunk size. Measured in the asset that would be sold
     */
    function _getAllChunkNotionalSizes(
        ISetToken _setToken,
        string[] calldata _exchangeNames,
        ActionInfo memory _actionInfo,
        uint256 currentLeverageRatio,
        uint256 newLeverageRatio,
        bool isProtection,
        bool isLever
    ) internal view returns (uint256[] memory sizes) {
        uint256 exchangeNamesLen = _exchangeNames.length;
        sizes = new uint256[](exchangeNamesLen);
        StrategySettings storage myStrategy = strategy[_setToken];
        for (uint256 i; i < exchangeNamesLen; ) {
            LeverageInfo memory leverageInfo = LeverageInfo({
                setToken: _setToken,
                action: _actionInfo,
                currentLeverageRatio: currentLeverageRatio,
                slippageTolerance: isProtection
                    ? myStrategy.protection.slippageTolerance
                    : myStrategy.execution.slippageTolerance,
                twapMaxTradeSize: isProtection
                    ? myStrategy
                        .exchangeSettings[_exchangeNames[i]]
                        .protectionTwapMaxTradeSize
                    : myStrategy
                        .exchangeSettings[_exchangeNames[i]]
                        .twapMaxTradeSize,
                exchangeName: _exchangeNames[i],
                swapData: ""
            });

            (uint256 collateralNotional, ) = _calculateChunkRebalanceNotional(
                leverageInfo,
                newLeverageRatio,
                isLever,
                false
            );

            // _calculateBorrowUnits can convert both unit and notional values
            sizes[i] = isLever
                ? _calculateBorrowUnits(collateralNotional, leverageInfo.action)
                : collateralNotional;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * Validate that current leverage is above incentivized leverage ratio and incentivized cooldown period
     * has elapsed in ripcord()
     */
    function _validateRipcord(
        ISetToken _setToken,
        uint256 _currentOnchainLeverageRatio,
        uint256 _lastTradeTimestamp
    ) internal view {
        StrategySettings storage myStrategy = strategy[_setToken];

        if (
            _currentOnchainLeverageRatio <
            myStrategy.incentive.thresholdLeverageRatio
        ) {
            revert ValidateRipcord(uint256(1)); // Must be above incentivized leverage ratio
        }
        // If currently in the midst of a TWAP rebalance, ensure that the cooldown period has elapsed
        if (
            _lastTradeTimestamp + myStrategy.incentive.twapCooldownPeriod >=
            block.timestamp /* solhint-disable-line not-rely-on-time */
        ) {
            revert ValidateRipcord(uint256(2)); // TWAP cooldown must have elapsed
        }
    }

    /**
     * Internal function returning the ShouldRipcord enum used in shouldRipcord
     *
     * @return ShouldRipcord         Enum detailing whether to ripcord or no action
     */
    function _shouldRipcord(
        ISetToken _setToken,
        uint256 _currentOnchainLeverageRatio
    ) internal view returns (string[] memory, ShouldRipcord[] memory) {
        StrategySettings storage myStrategy = strategy[_setToken];
        uint256 enabledExchangesLen = myStrategy.enabledExchanges.length;
        ShouldRipcord[] memory shouldRipcordEnums = new ShouldRipcord[](
            enabledExchangesLen
        );
        for (uint256 i; i < enabledExchangesLen; ) {
            // If none of the below conditions are satisfied, then should not rebalance
            shouldRipcordEnums[i] = ShouldRipcord.NONE;
            // If above ripcord threshold, then check if incentivized cooldown period has elapsed
            if (
                _currentOnchainLeverageRatio >=
                myStrategy.incentive.thresholdLeverageRatio
            ) {
                if (
                    myStrategy
                        .exchangeSettings[myStrategy.enabledExchanges[i]]
                        .exchangeLastTradeTimestamp +
                        myStrategy.incentive.twapCooldownPeriod <
                    block.timestamp /* solhint-disable-line not-rely-on-time */
                ) {
                    shouldRipcordEnums[i] = ShouldRipcord.RIPCORD;
                }
            }

            unchecked {
                ++i;
            }
        }
        return (myStrategy.enabledExchanges, shouldRipcordEnums);
    }

    /**
     * Internal function returning the ShouldRebalance enum used in shouldRebalance and shouldRebalanceWithBounds 
     * external getter functions
     *
     * @return ShouldRebalance   Enum detailing whether to rebalance, protect or no action
     */
    function _shouldRebalance(
        ISetToken _setToken,
        uint256 _currentOffchainLeverageRatio,
        uint256 _currentOnchainLeverageRatio,
        uint256 _minLeverageRatio,
        uint256 _maxLeverageRatio
    ) internal view returns (string[] memory, ShouldRebalance[] memory) {
        StrategySettings storage myStrategy = strategy[_setToken];
        uint256 enabledExchangesLen = myStrategy.enabledExchanges.length;
        ShouldRebalance[] memory shouldRebalanceEnums = new ShouldRebalance[](
            enabledExchangesLen
        );
        for (uint256 i; i < enabledExchangesLen; ) {
            // If none of the below conditions are satisfied, then should not rebalance
            shouldRebalanceEnums[i] = ShouldRebalance.NONE;

            // If above protection threshold, then check if incentivized cooldown period has elapsed
            if (
                _currentOnchainLeverageRatio >=
                myStrategy.protection.thresholdLeverageRatio
            ) {
                if (
                    myStrategy
                        .exchangeSettings[myStrategy.enabledExchanges[i]]
                        .exchangeLastTradeTimestamp +
                        myStrategy.protection.twapCooldownPeriod <
                    block.timestamp /* solhint-disable-line not-rely-on-time */
                ) {
                    shouldRebalanceEnums[i] = ShouldRebalance.PROTECTION;
                }
            } else {
                // Check current leverage is above max leverage OR current leverage is below
                // min leverage
                if (
                    (_currentOffchainLeverageRatio > _maxLeverageRatio ||
                        _currentOffchainLeverageRatio < _minLeverageRatio)
                ) {
                    shouldRebalanceEnums[i] = ShouldRebalance.REBALANCE;
                }
            }
            unchecked {
                ++i;
            }
        }
        return (myStrategy.enabledExchanges, shouldRebalanceEnums);
    }

    /**
     * Validate non-exchange settings.
     */
    function _validateNonExchangeSettings(
        MethodologySettings memory _methodology,
        ExecutionSettings memory _execution,
        ProtectionSettings memory _protection,
        IncentiveSettings memory _incentive
    ) internal pure {
        if (
            _methodology.minLeverageRatio > _methodology.targetLeverageRatio ||
            _methodology.minLeverageRatio == 0
        ) {
            revert ValidateNonExchangeSettings(uint256(1)); // Must be valid min leverage
        }
        if (_methodology.maxLeverageRatio < _methodology.targetLeverageRatio) {
            revert ValidateNonExchangeSettings(uint256(2)); // Must be valid max leverage
        }
        if (
            _execution.unutilizedLeveragePercentage >
            PreciseUnitMath.preciseUnit()
        ) {
            revert ValidateNonExchangeSettings(uint256(3)); // Unutilized leverage must be <= 100%
        }
        if (_execution.slippageTolerance > PreciseUnitMath.preciseUnit()) {
            revert ValidateNonExchangeSettings(uint256(4)); // Slippage tolerance must be <= 100%
        }
        if (_incentive.slippageTolerance > PreciseUnitMath.preciseUnit()) {
            revert ValidateNonExchangeSettings(uint256(5)); // Incentivized slippage tolerance must be <= 100%
        }
        if (_protection.slippageTolerance > PreciseUnitMath.preciseUnit()) {
            revert ValidateNonExchangeSettings(uint256(6)); // Protection slippage tolerance must be <= 100%
        }
        if (
            _protection.thresholdLeverageRatio <= _methodology.maxLeverageRatio
        ) {
            revert ValidateNonExchangeSettings(uint256(7)); // Protection leverage ratio must be > max leverage ratio
        }
        if (_incentive.resetLeverageRatio <= _methodology.targetLeverageRatio) {
            // Incentivized reset leverage ratio must be > target leverage ratio
            revert ValidateNonExchangeSettings(uint256(8));
        }
        if (
            _protection.resetLeverageRatio <= _methodology.targetLeverageRatio
        ) {
            // Protection reset leverage ratio must be > target leverage ratio
            revert ValidateNonExchangeSettings(uint256(9));
        }
        if (
            _incentive.resetLeverageRatio >= _incentive.thresholdLeverageRatio
        ) {
             // Incentivized reset leverage ratio must be < incentivized leverage ratio
            revert ValidateNonExchangeSettings(uint256(10));
        }
        if (
            _protection.resetLeverageRatio >= _protection.thresholdLeverageRatio
        ) {
             // Protection reset leverage ratio must be < protection leverage ratio
            revert ValidateNonExchangeSettings(uint256(11));
        }
        if (
            _protection.thresholdLeverageRatio >=
            _incentive.thresholdLeverageRatio
        ) {
            // Protection leverage ratio must be < Incentivized leverage ratio
            revert ValidateNonExchangeSettings(uint256(12));
        }
        if (_execution.twapCooldownPeriod < _incentive.twapCooldownPeriod) {
            revert ValidateNonExchangeSettings(uint256(13)); // TWAP cooldown must be >= incentivized TWAP cooldown
        }
        if (_execution.twapCooldownPeriod < _protection.twapCooldownPeriod) {
            revert ValidateNonExchangeSettings(uint256(14)); // TWAP cooldown must be >= protection TWAP cooldown
        }
    }

    /**
     * Validate an ExchangeSettings struct when adding or updating an exchange.
     * Does not validate that twapMaxTradeSize < incentivizedMaxTradeSize since
     * it may be useful to disable exchanges for ripcord by setting incentivizedMaxTradeSize to 0.
     */
    function _validateExchangeSettings(
        ExchangeSettings memory _settings
    ) internal pure {
        if (_settings.twapMaxTradeSize == 0) {
            revert ValidateExchangeSettings(uint256(1)); // Max TWAP trade size must not be 0
        }
        if (
            _settings.hasDynamicData && _settings.adapterAddress == address(0)
        ) {
            revert ValidateExchangeSettings(uint256(2)); // When providing dynamic data, adapter address is required
        }
    }
}

/*
    Copyright 2022 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { ISetToken } from "@amun/amun-protocol/contracts/interfaces/ISetToken.sol";
import { IIssuanceModule } from "@amun/amun-protocol/contracts/interfaces/IIssuanceModule.sol";
import { PreciseUnitMath } from "@amun/amun-protocol/contracts/lib/PreciseUnitMath.sol";

import { BaseGlobalExtension } from "../lib/BaseGlobalExtension.sol";
import { IDelegatedManager } from "../interfaces/IDelegatedManager.sol";
import { IManagerCore } from "../interfaces/IManagerCore.sol";

/**
 * @title IssuanceExtension
 * @author Set Protocol
 *
 * Smart contract global extension which provides DelegatedManager owner and methodologist the ability
 * to accrue and split issuance and redemption fees. Owner may configure the fee split percentages.
 *
 * Notes
 * - the fee split is set on the Delegated Manager contract
 * - when fees distributed via this contract will be inclusive of all fee types that have already been accrued
 *
 * CHANGELOG
 * - 4/20/23: Upgrade to Solidity 0.8.19
 * - 4/24/23: Removed OZ SafeMath
 */
contract IssuanceExtension is BaseGlobalExtension {
    using Address for address;
    using PreciseUnitMath for uint256;

    /* ============ Events ============ */

    event IssuanceExtensionInitialized(
        address indexed _setToken,
        address indexed _delegatedManager
    );

    event FeesDistributed(
        address _setToken,
        address indexed _ownerFeeRecipient,
        address indexed _methodologist,
        uint256 _ownerTake,
        uint256 _methodologistTake
    );

    /* ============ State Variables ============ */

    // Instance of IssuanceModule
    IIssuanceModule public immutable issuanceModule;

    /* ============ Constructor ============ */

    constructor(
        IManagerCore _managerCore,
        IIssuanceModule _issuanceModule
    )
        BaseGlobalExtension(_managerCore)
    {
        issuanceModule = _issuanceModule;
    }

    /* ============ External Functions ============ */

    /**
     * ANYONE CALLABLE: Distributes fees accrued to the DelegatedManager. Calculates fees for
     * owner and methodologist, and sends to owner fee recipient and methodologist respectively.
     */
    function distributeFees(ISetToken _setToken) public {
        IDelegatedManager delegatedManager = _manager(_setToken);

        uint256 totalFees = _setToken.balanceOf(address(delegatedManager));

        address methodologist = delegatedManager.methodologist();
        address ownerFeeRecipient = delegatedManager.ownerFeeRecipient();

        uint256 ownerTake = totalFees.preciseMul(delegatedManager.ownerFeeSplit());
        uint256 methodologistTake = totalFees - ownerTake;

        if (ownerTake > 0) {
            delegatedManager.transferTokens(address(_setToken), ownerFeeRecipient, ownerTake);
        }

        if (methodologistTake > 0) {
            delegatedManager.transferTokens(address(_setToken), methodologist, methodologistTake);
        }

        emit FeesDistributed(address(_setToken), ownerFeeRecipient, methodologist, ownerTake, methodologistTake);
    }

    /**
     * ONLY OWNER AND VALID MANAGER: Initializes IssuanceModule on the SetToken associated with the DelegatedManager.
     *
     * @param _delegatedManager             Instance of the DelegatedManager to initialize the IssuanceModule for
     * @param _maxManagerFee                Maximum fee that can be charged on issue and redeem
     * @param _managerIssueFee              Fee to charge on issuance
     * @param _managerRedeemFee             Fee to charge on redemption
     * @param _feeRecipient                 Address to send fees to
     * @param _managerIssuanceHook          Instance of the contract with the Pre-Issuance Hook function
     */
    function initializeModule(
        IDelegatedManager _delegatedManager,
        uint256 _maxManagerFee,
        uint256 _managerIssueFee,
        uint256 _managerRedeemFee,
        address _feeRecipient,
        address _managerIssuanceHook
    ) external onlyOwnerAndValidManager(_delegatedManager) {
        require(_delegatedManager.isInitializedExtension(address(this)), "Extension must be initialized");

        _initializeModule(
            _delegatedManager.setToken(),
            _delegatedManager,
            _maxManagerFee,
            _managerIssueFee,
            _managerRedeemFee,
            _feeRecipient,
            _managerIssuanceHook
        );
    }

    /**
     * ONLY OWNER AND VALID MANAGER: Initializes IssuanceExtension to the DelegatedManager.
     *
     * @param _delegatedManager     Instance of the DelegatedManager to initialize
     */
    function initializeExtension(
        IDelegatedManager _delegatedManager
    ) external onlyOwnerAndValidManager(_delegatedManager) {
        require(_delegatedManager.isPendingExtension(address(this)), "Extension must be pending");

        ISetToken setToken = _delegatedManager.setToken();

        _initializeExtension(setToken, _delegatedManager);

        emit IssuanceExtensionInitialized(address(setToken), address(_delegatedManager));
    }

    /**
     * ONLY OWNER AND VALID MANAGER: Initializes IssuanceExtension to the DelegatedManager and IssuanceModule
     * to the SetToken
     *
     * @param _delegatedManager             Instance of the DelegatedManager to initialize
     * @param _maxManagerFee                Maximum fee that can be charged on issue and redeem
     * @param _managerIssueFee              Fee to charge on issuance
     * @param _managerRedeemFee             Fee to charge on redemption
     * @param _feeRecipient                 Address to send fees to
     * @param _managerIssuanceHook          Instance of the contract with the Pre-Issuance Hook function
     */
    function initializeModuleAndExtension(
        IDelegatedManager _delegatedManager,
        uint256 _maxManagerFee,
        uint256 _managerIssueFee,
        uint256 _managerRedeemFee,
        address _feeRecipient,
        address _managerIssuanceHook
    ) external onlyOwnerAndValidManager(_delegatedManager) {
        require(_delegatedManager.isPendingExtension(address(this)), "Extension must be pending");

        ISetToken setToken = _delegatedManager.setToken();

        _initializeExtension(setToken, _delegatedManager);
        _initializeModule(
            setToken,
            _delegatedManager,
            _maxManagerFee,
            _managerIssueFee,
            _managerRedeemFee,
            _feeRecipient,
            _managerIssuanceHook
        );

        emit IssuanceExtensionInitialized(address(setToken), address(_delegatedManager));
    }

    /**
     * ONLY MANAGER: Remove an existing SetToken and DelegatedManager tracked by the IssuanceExtension
     */
    function removeExtension() external override {
        IDelegatedManager delegatedManager = IDelegatedManager(msg.sender);
        ISetToken setToken = delegatedManager.setToken();

        _removeExtension(setToken, delegatedManager);
    }

    /**
     * ONLY OWNER: Updates issuance fee on IssuanceModule.
     *
     * @param _setToken     Instance of the SetToken to update issue fee for
     * @param _newFee       New issue fee percentage in precise units (1% = 1e16, 100% = 1e18)
     */
    function updateIssueFee(
        ISetToken _setToken,
        uint256 _newFee
    ) external onlyOwner(_setToken) {
        bytes memory callData = abi.encodeWithSignature("updateIssueFee(address,uint256)", _setToken, _newFee);
        _invokeManager(_manager(_setToken), address(issuanceModule), callData);
    }

    /**
     * ONLY OWNER: Updates redemption fee on IssuanceModule.
     *
     * @param _setToken     Instance of the SetToken to update redeem fee for
     * @param _newFee       New redeem fee percentage in precise units (1% = 1e16, 100% = 1e18)
     */
    function updateRedeemFee(
        ISetToken _setToken,
        uint256 _newFee
    ) external onlyOwner(_setToken) {
        bytes memory callData = abi.encodeWithSignature("updateRedeemFee(address,uint256)", _setToken, _newFee);
        _invokeManager(_manager(_setToken), address(issuanceModule), callData);
    }

    /**
     * ONLY OWNER: Updates fee recipient on IssuanceModule
     *
     * @param _setToken         Instance of the SetToken to update fee recipient for
     * @param _newFeeRecipient  Address of new fee recipient. This should be the address of the DelegatedManager
     */
    function updateFeeRecipient(
        ISetToken _setToken,
        address _newFeeRecipient
    ) external onlyOwner(_setToken) {
        bytes memory callData = abi.encodeWithSignature(
            "updateFeeRecipient(address,address)",
            _setToken,
            _newFeeRecipient
        );
        _invokeManager(_manager(_setToken), address(issuanceModule), callData);
    }

    /* ============ Internal Functions ============ */

    /**
     * Internal function to initialize IssuanceModule on the SetToken associated with the DelegatedManager.
     *
     * @param _setToken                     Instance of the SetToken corresponding to the DelegatedManager
     * @param _delegatedManager             Instance of the DelegatedManager to initialize the TradeModule for
     * @param _maxManagerFee                Maximum fee that can be charged on issue and redeem
     * @param _managerIssueFee              Fee to charge on issuance
     * @param _managerRedeemFee             Fee to charge on redemption
     * @param _feeRecipient                 Address to send fees to
     * @param _managerIssuanceHook          Instance of the contract with the Pre-Issuance Hook function
     */
    function _initializeModule(
        ISetToken _setToken,
        IDelegatedManager _delegatedManager,
        uint256 _maxManagerFee,
        uint256 _managerIssueFee,
        uint256 _managerRedeemFee,
        address _feeRecipient,
        address _managerIssuanceHook
    )
        internal
    {
        bytes memory callData = abi.encodeWithSignature(
            "initialize(address,uint256,uint256,uint256,address,address)",
            _setToken,
            _maxManagerFee,
            _managerIssueFee,
            _managerRedeemFee,
            _feeRecipient,
            _managerIssuanceHook
        );
        _invokeManager(_delegatedManager, address(issuanceModule), callData);
    }
}

/*
    Copyright 2022 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { ISetToken } from "@amun/amun-protocol/contracts/interfaces/ISetToken.sol";
import { IStreamingFeeModule } from "@amun/amun-protocol/contracts/interfaces/IStreamingFeeModule.sol";
import { PreciseUnitMath } from "@amun/amun-protocol/contracts/lib/PreciseUnitMath.sol";

import { BaseGlobalExtension } from "../lib/BaseGlobalExtension.sol";
import { IDelegatedManager } from "../interfaces/IDelegatedManager.sol";
import { IManagerCore } from "../interfaces/IManagerCore.sol";

/**
 * @title StreamingFeeSplitExtension
 * @author Set Protocol
 *
 * Smart contract global extension which provides DelegatedManager owner and methodologist the ability
 * to accrue and split streaming fees. Owner may configure the fee split percentages.
 *
 * Notes
 * - the fee split is set on the Delegated Manager contract
 * - when fees distributed via this contract will be inclusive of all fee types
 *
 * CHANGELOG
 * - 4/20/23: Upgrade to Solidity 0.8.19
 * - 4/24/23: Removed OZ SafeMath
 */
contract StreamingFeeSplitExtension is BaseGlobalExtension {
    using Address for address;
    using PreciseUnitMath for uint256;

    /* ============ Events ============ */

    event StreamingFeeSplitExtensionInitialized(
        address indexed _setToken,
        address indexed _delegatedManager
    );

    event FeesDistributed(
        address _setToken,
        address indexed _ownerFeeRecipient,
        address indexed _methodologist,
        uint256 _ownerTake,
        uint256 _methodologistTake
    );

    /* ============ State Variables ============ */

    // Instance of StreamingFeeModule
    IStreamingFeeModule public immutable streamingFeeModule;

    /* ============ Constructor ============ */

    constructor(
        IManagerCore _managerCore,
        IStreamingFeeModule _streamingFeeModule
    )
        BaseGlobalExtension(_managerCore)
    {
        streamingFeeModule = _streamingFeeModule;
    }

    /* ============ External Functions ============ */

    /**
     * ANYONE CALLABLE: Accrues fees from streaming fee module. Gets resulting balance after fee accrual,
     * calculates fees for owner and methodologist, and sends to owner fee recipient and methodologist respectively.
     */
    function accrueFeesAndDistribute(ISetToken _setToken) public {
        // Emits a FeeActualized event
        streamingFeeModule.accrueFee(_setToken);

        IDelegatedManager delegatedManager = _manager(_setToken);

        uint256 totalFees = _setToken.balanceOf(address(delegatedManager));

        address methodologist = delegatedManager.methodologist();
        address ownerFeeRecipient = delegatedManager.ownerFeeRecipient();

        uint256 ownerTake = totalFees.preciseMul(delegatedManager.ownerFeeSplit());
        uint256 methodologistTake = totalFees - ownerTake;

        if (ownerTake > 0) {
            delegatedManager.transferTokens(address(_setToken), ownerFeeRecipient, ownerTake);
        }

        if (methodologistTake > 0) {
            delegatedManager.transferTokens(address(_setToken), methodologist, methodologistTake);
        }

        emit FeesDistributed(address(_setToken), ownerFeeRecipient, methodologist, ownerTake, methodologistTake);
    }

    /**
     * ONLY OWNER AND VALID MANAGER: Initializes StreamingFeeModule on the SetToken associated with the
     * DelegatedManager
     *
     * @param _delegatedManager     Instance of the DelegatedManager to initialize the StreamingFeeModule for
     * @param _settings             FeeState struct defining fee parameters for StreamingFeeModule initialization
     */
    function initializeModule(
        IDelegatedManager _delegatedManager,
        IStreamingFeeModule.FeeState memory _settings
    ) external onlyOwnerAndValidManager(_delegatedManager) {
        require(_delegatedManager.isInitializedExtension(address(this)), "Extension must be initialized");

        _initializeModule(_delegatedManager.setToken(), _delegatedManager, _settings);
    }

    /**
     * ONLY OWNER AND VALID MANAGER: Initializes StreamingFeeSplitExtension to the DelegatedManager.
     *
     * @param _delegatedManager     Instance of the DelegatedManager to initialize
     */
    function initializeExtension(
        IDelegatedManager _delegatedManager
    ) external onlyOwnerAndValidManager(_delegatedManager) {
        require(_delegatedManager.isPendingExtension(address(this)), "Extension must be pending");

        ISetToken setToken = _delegatedManager.setToken();

        _initializeExtension(setToken, _delegatedManager);

        emit StreamingFeeSplitExtensionInitialized(address(setToken), address(_delegatedManager));
    }

    /**
     * ONLY OWNER AND VALID MANAGER: Initializes StreamingFeeSplitExtension to the DelegatedManager and
     * StreamingFeeModule to the SetToken
     *
     * @param _delegatedManager     Instance of the DelegatedManager to initialize
     * @param _settings             FeeState struct defining fee parameters for StreamingFeeModule initialization
     */
    function initializeModuleAndExtension(
        IDelegatedManager _delegatedManager,
        IStreamingFeeModule.FeeState memory _settings
    ) external onlyOwnerAndValidManager(_delegatedManager) {
        require(_delegatedManager.isPendingExtension(address(this)), "Extension must be pending");

        ISetToken setToken = _delegatedManager.setToken();

        _initializeExtension(setToken, _delegatedManager);
        _initializeModule(setToken, _delegatedManager, _settings);

        emit StreamingFeeSplitExtensionInitialized(address(setToken), address(_delegatedManager));
    }

    /**
     * ONLY MANAGER: Remove an existing SetToken and DelegatedManager tracked by the StreamingFeeSplitExtension
     */
    function removeExtension() external override {
        IDelegatedManager delegatedManager = IDelegatedManager(msg.sender);
        ISetToken setToken = delegatedManager.setToken();

        _removeExtension(setToken, delegatedManager);
    }

    /**
     * ONLY OWNER: Updates streaming fee on StreamingFeeModule.
     *
     * NOTE: This will accrue streaming fees though not send to owner fee recipient and methodologist.
     *
     * @param _setToken     Instance of the SetToken to update streaming fee for
     * @param _newFee       Percent of Set accruing to fee extension annually (1% = 1e16, 100% = 1e18)
     */
    function updateStreamingFee(
        ISetToken _setToken,
        uint256 _newFee
    ) external onlyOwner(_setToken) {
        bytes memory callData = abi.encodeWithSignature("updateStreamingFee(address,uint256)", _setToken, _newFee);
        _invokeManager(_manager(_setToken), address(streamingFeeModule), callData);
    }

    /**
     * ONLY OWNER: Updates fee recipient on StreamingFeeModule
     *
     * @param _setToken         Instance of the SetToken to update fee recipient for
     * @param _newFeeRecipient  Address of new fee recipient. This should be the address of the DelegatedManager
     */
    function updateFeeRecipient(
        ISetToken _setToken,
        address _newFeeRecipient
    ) external onlyOwner(_setToken) {
        bytes memory callData = abi.encodeWithSignature(
            "updateFeeRecipient(address,address)",
            _setToken,
            _newFeeRecipient
        );
        _invokeManager(_manager(_setToken), address(streamingFeeModule), callData);
    }

    /* ============ Internal Functions ============ */

    /**
     * Internal function to initialize StreamingFeeModule on the SetToken associated with the DelegatedManager.
     *
     * @param _setToken                     Instance of the SetToken corresponding to the DelegatedManager
     * @param _delegatedManager     Instance of the DelegatedManager to initialize the TradeModule for
     * @param _settings             FeeState struct defining fee parameters for StreamingFeeModule initialization
     */
    function _initializeModule(
        ISetToken _setToken,
        IDelegatedManager _delegatedManager,
        IStreamingFeeModule.FeeState memory _settings
    )
        internal
    {
        bytes memory callData = abi.encodeWithSignature(
            "initialize(address,(address,uint256,uint256,uint256))",
            _setToken,
            _settings);
        _invokeManager(_delegatedManager, address(streamingFeeModule), callData);
    }
}

/*
    Copyright 2022 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {AddressArrayUtils} from "@amun/amun-protocol/contracts/lib/AddressArrayUtils.sol";
import {IController} from "@amun/amun-protocol/contracts/interfaces/IController.sol";
import {ISetToken} from "@amun/amun-protocol/contracts/interfaces/ISetToken.sol";
import {ISetTokenCreator} from "@amun/amun-protocol/contracts/interfaces/ISetTokenCreator.sol";

import {DelegatedManager} from "../manager/DelegatedManager.sol";
import {IDelegatedManager} from "../interfaces/IDelegatedManager.sol";
import {IManagerCore} from "../interfaces/IManagerCore.sol";

/**
 * @title DelegatedManagerFactory
 * @author Set Protocol
 *
 * Factory smart contract which gives asset managers the ability to:
 * > create a Set Token managed with a DelegatedManager contract
 * > create a DelegatedManager contract for an existing Set Token to migrate to
 * > initialize extensions and modules for SetTokens using the DelegatedManager system
 *
 * CHANGELOG
 * - 4/20/23: Upgrade to Solidity 0.8.19
 * - 4/21/23: Add ownable
 */
contract DelegatedManagerFactory is Ownable {
    using AddressArrayUtils for address[];
    using Address for address;

    /* ============ Structs ============ */

    struct InitializeParams {
        address deployer;
        address owner;
        address methodologist;
        IDelegatedManager manager;
        bool isPending;
    }

    /* ============ Events ============ */

    /**
     * @dev Emitted on DelegatedManager creation
     * @param _setToken             Instance of the SetToken being created
     * @param _manager              Address of the DelegatedManager
     * @param _deployer             Address of the deployer
     */
    event DelegatedManagerCreated(
        ISetToken indexed _setToken,
        DelegatedManager indexed _manager,
        address _deployer
    );

    /**
     * @dev Emitted on DelegatedManager initialization
     * @param _setToken             Instance of the SetToken being initialized
     * @param _manager              Address of the DelegatedManager owner
     */
    event DelegatedManagerInitialized(
        ISetToken indexed _setToken,
        IDelegatedManager indexed _manager
    );

    /* ============ State Variables ============ */

    // ManagerCore address
    IManagerCore public immutable managerCore;

    // Controller address
    IController public immutable controller;

    // SetTokenFactory address
    ISetTokenCreator public immutable setTokenFactory;

    // Mapping which stores manager creation metadata between creation and initialization steps
    mapping(ISetToken => InitializeParams) public initializeState;

    /* ============ Constructor ============ */

    /**
     * @dev Sets managerCore and setTokenFactory address.
     * @param _managerCore                      Address of ManagerCore protocol contract
     * @param _controller                       Address of Controller protocol contract
     * @param _setTokenFactory                  Address of SetTokenFactory protocol contract
     */
    constructor(
        IManagerCore _managerCore,
        IController _controller,
        ISetTokenCreator _setTokenFactory
    ) {
        managerCore = _managerCore;
        controller = _controller;
        setTokenFactory = _setTokenFactory;
    }

    /* ============ External Functions ============ */

    /**
     * ONLY OWNER: Deploys a new SetToken and DelegatedManager. Sets some temporary metadata about
     * the deployment which will be read during a subsequent intialization step which wires everything
     * together.
     *
     * @param _components       List of addresses of components for initial Positions
     * @param _units            List of units. Each unit is the # of components per 10^18 of a SetToken
     * @param _name             Name of the SetToken
     * @param _symbol           Symbol of the SetToken
     * @param _owner            Address to set as the DelegateManager's `owner` role
     * @param _methodologist    Address to set as the DelegateManager's methodologist role
     * @param _modules          List of modules to enable. All modules must be approved by the Controller
     * @param _operators        List of operators authorized for the DelegateManager
     * @param _assets           List of assets DelegateManager can trade. When empty, asset allow list is not enforced
     * @param _extensions       List of extensions authorized for the DelegateManager
     *
     * @return (ISetToken, address) The created SetToken and DelegatedManager addresses, respectively
     */
    function createSetAndManager(
        address[] memory _components,
        int256[] memory _units,
        string memory _name,
        string memory _symbol,
        address _owner,
        address _methodologist,
        address[] memory _modules,
        address[] memory _operators,
        address[] memory _assets,
        address[] memory _extensions
    ) external onlyOwner returns (ISetToken, address) {
        _validateManagerParameters(_components, _extensions, _assets);

        ISetToken setToken = _deploySet(
            _components,
            _units,
            _modules,
            _name,
            _symbol
        );

        DelegatedManager manager = _deployManager(
            setToken,
            _extensions,
            _operators,
            _assets
        );

        _setInitializationState(
            setToken,
            address(manager),
            _owner,
            _methodologist
        );

        return (setToken, address(manager));
    }

    /**
     * ONLY DEPLOYER: Wires SetToken, DelegatedManager, global manager extensions, and modules together
     * into a functioning package.
     *
     * NOTE: When migrating to this manager system from an existing SetToken, the SetToken's current manager address
     * must be reset to point at the newly deployed DelegatedManager contract in a separate, final transaction.
     *
     * @param  _setToken                      Instance of the SetToken
     * @param  _ownerFeeSplit                 Fees in precise units (10^16 = 1%) sent to owner, rest to methodologist
     * @param  _ownerFeeRecipient             Address which receives owner's share of fees when they're distributed
     * @param  _extensions                    List of addresses of extensions which need to be initialized
     * @param  _initializeExtensionsBytecode  List of bytecode encoded calls to relevant extensions' initialize function
     */
    function initialize(
        ISetToken _setToken,
        uint256 _ownerFeeSplit,
        address _ownerFeeRecipient,
        address[] memory _extensions,
        bytes[] memory _initializeExtensionsBytecode
    ) external {
        require(
            initializeState[_setToken].isPending,
            "Manager must be awaiting initialization"
        );
        require(
            msg.sender == initializeState[_setToken].deployer,
            "Only deployer can initialize manager"
        );
        _extensions.validatePairsWithArray(_initializeExtensionsBytecode);

        IDelegatedManager manager = initializeState[_setToken].manager;

        // If the SetToken was factory-deployed & factory is its current `manager`, transfer
        // managership to the new DelegatedManager
        if (_setToken.manager() == address(this)) {
            _setToken.setManager(address(manager));
        }

        _initializeExtensions(
            manager,
            _extensions,
            _initializeExtensionsBytecode
        );

        _setManagerState(
            manager,
            initializeState[_setToken].owner,
            initializeState[_setToken].methodologist,
            _ownerFeeSplit,
            _ownerFeeRecipient
        );

        delete initializeState[_setToken];

        emit DelegatedManagerInitialized(_setToken, manager);
    }

    /* ============ Internal Functions ============ */

    /**
     * Deploys a SetToken, setting this factory as its manager temporarily, pending initialization.
     * Managership is transferred to a newly created DelegatedManager during `initialize`
     *
     * @param _components       List of addresses of components for initial Positions
     * @param _units            List of units. Each unit is the # of components per 10^18 of a SetToken
     * @param _modules          List of modules to enable. All modules must be approved by the Controller
     * @param _name             Name of the SetToken
     * @param _symbol           Symbol of the SetToken
     *
     * @return Address of created SetToken;
     */
    function _deploySet(
        address[] memory _components,
        int256[] memory _units,
        address[] memory _modules,
        string memory _name,
        string memory _symbol
    ) internal returns (ISetToken) {
        address setToken = setTokenFactory.create(
            _components,
            _units,
            _modules,
            address(this),
            _name,
            _symbol
        );

        return ISetToken(setToken);
    }

    /**
     * Deploys a DelegatedManager. Sets owner and methodologist roles to address(this) and the resulting manager
     * address is saved to the ManagerCore.
     *
     * @param  _setToken         Instance of SetToken to migrate to the DelegatedManager system
     * @param  _extensions       List of extensions authorized for the DelegateManager
     * @param  _operators        List of operators authorized for the DelegateManager
     * @param  _assets           List of assets DelegateManager can trade. When empty, asset allow list is not enforced
     *
     * @return Address of created DelegatedManager
     */
    function _deployManager(
        ISetToken _setToken,
        address[] memory _extensions,
        address[] memory _operators,
        address[] memory _assets
    ) internal returns (DelegatedManager) {
        // If asset array is empty, manager's useAssetAllowList will be set to false
        // and the asset allow list is not enforced
        bool useAssetAllowlist = _assets.length > 0;

        DelegatedManager newManager = new DelegatedManager(
            _setToken,
            address(this),
            address(this),
            _extensions,
            _operators,
            _assets,
            useAssetAllowlist
        );

        // Registers manager with ManagerCore
        managerCore.addManager(address(newManager));

        emit DelegatedManagerCreated(_setToken, newManager, msg.sender);

        return newManager;
    }

    /**
     * Initialize extensions on the DelegatedManager. Checks that extensions are tracked on the ManagerCore and that the
     * provided bytecode targets the input manager.
     *
     * @param  _manager                  Instance of DelegatedManager
     * @param  _extensions               List of addresses of extensions to initialize
     * @param  _initializeBytecode       List of bytecode encoded calls to relevant extensions's initialize function
     */
    function _initializeExtensions(
        IDelegatedManager _manager,
        address[] memory _extensions,
        bytes[] memory _initializeBytecode
    ) internal {
        uint256 extensionsLen = _extensions.length;
        for (uint256 i; i < extensionsLen; ) {
            address extension = _extensions[i];
            require(
                managerCore.isExtension(extension),
                "Target must be ManagerCore-enabled Extension"
            );

            bytes memory initializeBytecode = _initializeBytecode[i];

            // Each input initializeBytecode is a varible length bytes array which consists of a 32 byte prefix for the
            // length parameter, a 4 byte function selector, a 32 byte DelegatedManager address, and any additional
            // parameters as shown below:
            // [32bytes - length, 4bytes - function selector, 32bytes - DelegatedManager address, additional parameters]
            // Input DelegatedManager address required as the DelegatedManager address corresponding to the caller
            address inputManager;
            /* solhint-disable-next-line no-inline-assembly */
            assembly {
                inputManager := mload(add(initializeBytecode, 36))
            }
            require(
                inputManager == address(_manager),
                "Must target correct DelegatedManager"
            );

            // Because we validate uniqueness of _extensions only one transaction can be sent to each extension during
            // this transaction. Due to this no extension can be used for any SetToken transactions other than
            // initializing these contracts
            extension.functionCallWithValue(initializeBytecode, 0);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * Stores temporary creation metadata during the contract creation step. Data is retrieved, read and
     * finally deleted during `initialize`.
     *
     * @param  _setToken         Instance of SetToken
     * @param  _manager          Address of DelegatedManager created for SetToken
     * @param  _owner            Given address to the `owner` DelegatedManager's role on initialization
     * @param  _methodologist    Given address to the `methodologist` DelegatedManager's role on initialization
     */
    function _setInitializationState(
        ISetToken _setToken,
        address _manager,
        address _owner,
        address _methodologist
    ) internal {
        initializeState[_setToken] = InitializeParams({
            deployer: msg.sender,
            owner: _owner,
            methodologist: _methodologist,
            manager: IDelegatedManager(_manager),
            isPending: true
        });
    }

    /**
     * Initialize fee settings on DelegatedManager and transfer `owner` and `methodologist` roles.
     *
     * @param  _manager                 Instance of DelegatedManager
     * @param  _owner                   Address that will be given the `owner` DelegatedManager's role
     * @param  _methodologist           Address that will be given the `methodologist` DelegatedManager's role
     * @param  _ownerFeeSplit           Fees in precise units (10^16 = 1%) sent to owner, rest to methodologist
     * @param  _ownerFeeRecipient       Address which receives owner's share of fees when they're distributed
     */
    function _setManagerState(
        IDelegatedManager _manager,
        address _owner,
        address _methodologist,
        uint256 _ownerFeeSplit,
        address _ownerFeeRecipient
    ) internal {
        _manager.updateOwnerFeeSplit(_ownerFeeSplit);
        _manager.updateOwnerFeeRecipient(_ownerFeeRecipient);

        _manager.transferOwnership(_owner);
        _manager.setMethodologist(_methodologist);
    }

    /**
     * Validates that all components currently held by the Set are on the asset allow list. Validate that the manager is
     * deployed with at least one extension in the PENDING state.
     *
     * @param  _components       List of addresses of components for initial/current Set positions
     * @param  _extensions       List of extensions authorized for the DelegateManager
     * @param  _assets           List of assets DelegateManager can trade. When empty, asset allow list is not enforced
     */
    function _validateManagerParameters(
        address[] memory _components,
        address[] memory _extensions,
        address[] memory _assets
    ) internal pure {
        require(_extensions.length > 0, "Must have at least 1 extension");

        if (_assets.length != 0) {
            _validateComponentsIncludedInAssetsList(_components, _assets);
        }
    }

    /**
     * Validates that all SetToken components are included in the assets whitelist. This prevents the
     * DelegatedManager from being initialized with some components in an untrade-able state.
     *
     * @param _components       List of addresses of components for initial Positions
     * @param  _assets          List of assets DelegateManager can trade.
     */
    function _validateComponentsIncludedInAssetsList(
        address[] memory _components,
        address[] memory _assets
    ) internal pure {
        uint256 componentsLen = _components.length;
        for (uint256 i; i < componentsLen; ) {
            require(
                _assets.contains(_components[i]),
                "Asset list must include all components"
            );
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/************
@title IPriceOracleGetter interface
@notice Interface for the Aave price oracle.*/
interface IPriceOracleGetter {
    function getAssetPrice(address _asset) external view returns (uint256);
    function getAssetsPrices(address[] calldata _assets) external view returns(uint256[] memory);
    function getSourceOfAsset(address _asset) external view returns(address);
    function getFallbackOracle() external view returns(address);
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

import { IBaseManager } from "./IBaseManager.sol";

interface IAdapter {
    function manager() external view returns (IBaseManager);
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

import { ISetToken } from "@amun/amun-protocol/contracts/interfaces/ISetToken.sol";

interface IBaseManager {
    function setToken() external returns(ISetToken);

    function methodologist() external returns(address);

    function operator() external returns(address);

    function interactManager(address _module, bytes calldata _encoded) external;

    function transferTokens(address _token, address _destination, uint256 _amount) external;
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

import { ISetToken } from "@amun/amun-protocol/contracts/interfaces/ISetToken.sol";

interface IDelegatedManager {
    function interactManager(address _module, bytes calldata _encoded) external;

    function initializeExtension() external;

    function transferTokens(address _token, address _destination, uint256 _amount) external;

    function updateOwnerFeeSplit(uint256 _newFeeSplit) external;

    function updateOwnerFeeRecipient(address _newFeeRecipient) external;

    function setMethodologist(address _newMethodologist) external;

    function transferOwnership(address _owner) external;

    function setToken() external view returns(ISetToken);
    function owner() external view returns(address);
    function methodologist() external view returns(address);
    function operatorAllowlist(address _operator) external view returns(bool);
    function assetAllowlist(address _asset) external view returns(bool);
    function useAssetAllowlist() external view returns(bool);
    function isAllowedAsset(address _asset) external view returns(bool);
    function isPendingExtension(address _extension) external view returns(bool);
    function isInitializedExtension(address _extension) external view returns(bool);
    function getExtensions() external view returns(address[] memory);
    function getOperators() external view returns(address[] memory);
    function getAllowedAssets() external view returns(address[] memory);
    function ownerFeeRecipient() external view returns(address);
    function ownerFeeSplit() external view returns(uint256);
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

import { IBaseManager } from "./IBaseManager.sol";

interface IExtension {
    function manager() external view returns (IBaseManager);
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

import { ISetToken } from "@amun/amun-protocol/contracts/interfaces/ISetToken.sol";

interface IGlobalExtension {
    function removeExtension() external;
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IAToken } from "@amun/amun-protocol/contracts/interfaces/external/aave-v2/IAToken.sol";
import { ISetToken } from "@amun/amun-protocol/contracts/interfaces/ISetToken.sol";
import { 
    IVariableDebtToken
} from "@amun/amun-protocol/contracts/interfaces/external/aave-v2/IVariableDebtToken.sol";
import {
    IProtocolDataProvider
} from "@amun/amun-protocol/contracts/interfaces/external/aave-v2/IProtocolDataProvider.sol";
import {
    ILendingPoolAddressesProvider
} from "@amun/amun-protocol/contracts/interfaces/external/aave-v2/ILendingPoolAddressesProvider.sol";

interface ILeverageModule {
    
    struct ReserveTokens {
        IAToken aToken;                         // Reserve's aToken instance
        IVariableDebtToken variableDebtToken;   // Reserve's variable debt token instance
    }

    function sync(
        ISetToken _setToken
    ) external;

    function lever(
        ISetToken _setToken,
        address _borrowAsset,
        address _collateralAsset,
        uint256 _borrowQuantity,
        uint256 _minReceiveQuantity,
        string memory _tradeAdapterName,
        bytes memory _tradeData
    ) external;

    function delever(
        ISetToken _setToken,
        address _collateralAsset,
        address _repayAsset,
        uint256 _redeemQuantity,
        uint256 _minRepayQuantity,
        string memory _tradeAdapterName,
        bytes memory _tradeData
    ) external;

    function lendingPoolAddressesProvider() external pure returns(ILendingPoolAddressesProvider);
    function protocolDataProvider() external pure returns(IProtocolDataProvider);
    function getEnabledAssets(ISetToken _setToken) external view returns(address[] memory, address[] memory);
    function underlyingToReserveTokens(IERC20) external view returns(ReserveTokens calldata);
}

/*
    Copyright 2022 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

interface IManagerCore {
    function addManager(address _manager) external;
    function isExtension(address _extension) external view returns(bool);
    function isFactory(address _factory) external view returns(bool);
    function isManager(address _manager) external view returns(bool);
    function owner() external view returns(address);
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

interface IPriceFeed {
    function decimals() external view returns (uint8);

    /// @dev Returns the index price of the token.
    /// @param interval The interval represents twap interval.
    function getPrice(uint256 interval) external view returns (uint256);
}

/*
    Copyright 2022 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

import { AddressArrayUtils } from "@amun/amun-protocol/contracts/lib/AddressArrayUtils.sol";
import { ISetToken } from "@amun/amun-protocol/contracts/interfaces/ISetToken.sol";

import { IDelegatedManager } from "../interfaces/IDelegatedManager.sol";
import { IManagerCore } from "../interfaces/IManagerCore.sol";

/**
 * @title BaseGlobalExtension
 * @author Set Protocol
 *
 * Abstract class that houses common global extension-related functions. Global extensions must
 * also have their own initializeExtension function (not included here because interfaces will vary).
 *
 * CHANGELOG
 * - 4/20/23: Upgrade to Solidity 0.8.19
 */
abstract contract BaseGlobalExtension {
    using AddressArrayUtils for address[];

    /* ============ Events ============ */

    event ExtensionRemoved(
        address indexed _setToken,
        address indexed _delegatedManager
    );

    /* ============ State Variables ============ */

    // Address of the ManagerCore
    IManagerCore public immutable managerCore;

    // Mapping from Set Token to DelegatedManager
    mapping(ISetToken => IDelegatedManager) public setManagers;

    /* ============ Modifiers ============ */

    /**
     * Throws if the sender is not the SetToken manager contract owner
     */
    modifier onlyOwner(ISetToken _setToken) {
        _onlyOwner(_setToken);
        _;
    }
    function _onlyOwner(ISetToken _setToken) internal view {
        require(msg.sender == _manager(_setToken).owner(), "Must be owner");
    }

    /**
     * Throws if the sender is not the SetToken methodologist
     */
    modifier onlyMethodologist(ISetToken _setToken) {
        _onlyMethodologist(_setToken);
        _;
    }
    function _onlyMethodologist(ISetToken _setToken) internal view {
        require(msg.sender == _manager(_setToken).methodologist(), "Must be methodologist");
    }

    /**
     * Throws if the sender is not a SetToken operator
     */
    modifier onlyOperator(ISetToken _setToken) {
        _onlyOperator(_setToken);
        _;
    }
    function _onlyOperator(ISetToken _setToken) internal view {
        require(_manager(_setToken).operatorAllowlist(msg.sender), "Must be approved operator");
    }

    /**
     * Throws if the sender is not the SetToken manager contract owner or
     * if the manager is not enabled on the ManagerCore
     */
    modifier onlyOwnerAndValidManager(IDelegatedManager _delegatedManager) {
        _onlyOwnerAndValidManager(_delegatedManager);
        _;
    }
    function _onlyOwnerAndValidManager(IDelegatedManager _delegatedManager) internal view {
        require(msg.sender == _delegatedManager.owner(), "Must be owner");
        require(managerCore.isManager(address(_delegatedManager)), "Must be ManagerCore-enabled manager");
    }

    /**
     * Throws if asset is not allowed to be held by the Set
     */
    modifier onlyAllowedAsset(ISetToken _setToken, address _asset) {
        _onlyAllowedAsset(_setToken, _asset);
        _;
    }
    function _onlyAllowedAsset(ISetToken _setToken, address _asset) internal view {
        require(_manager(_setToken).isAllowedAsset(_asset), "Must be allowed asset");
    }

    /* ============ Constructor ============ */

    /**
     * Set state variables
     *
     * @param _managerCore             Address of managerCore contract
     */
    constructor(IManagerCore _managerCore) {
        managerCore = _managerCore;
    }

    /* ============ External Functions ============ */

    /**
     * ONLY MANAGER: Deletes SetToken/Manager state from extension. Must only be callable by manager!
     */
    function removeExtension() external virtual;

    /* ============ Internal Functions ============ */

    /**
     * Invoke call from manager
     *
     * @param _delegatedManager      Manager to interact with
     * @param _module                Module to interact with
     * @param _encoded               Encoded byte data
     */
    function _invokeManager(IDelegatedManager _delegatedManager, address _module, bytes memory _encoded) internal {
        _delegatedManager.interactManager(_module, _encoded);
    }

    /**
     * Internal function to grab manager of passed SetToken from extensions data structure.
     *
     * @param _setToken         SetToken who's manager is needed
     */
    function _manager(ISetToken _setToken) internal view returns (IDelegatedManager) {
        return setManagers[_setToken];
    }

    /**
     * Internal function to initialize extension to the DelegatedManager.
     *
     * @param _setToken             Instance of the SetToken corresponding to the DelegatedManager
     * @param _delegatedManager     Instance of the DelegatedManager to initialize
     */
    function _initializeExtension(ISetToken _setToken, IDelegatedManager _delegatedManager) internal {
        setManagers[_setToken] = _delegatedManager;

        _delegatedManager.initializeExtension();
    }

    /**
     * ONLY MANAGER: Internal function to delete SetToken/Manager state from extension
     */
    function _removeExtension(ISetToken _setToken, IDelegatedManager _delegatedManager) internal {
        require(msg.sender == address(_manager(_setToken)), "Must be Manager");

        delete setManagers[_setToken];

        emit ExtensionRemoved(address(_setToken), address(_delegatedManager));
    }
}

/*
    Copyright 2018 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

/**
 * @title MutualUpgrade
 * @author Set Protocol
 *
 * The MutualUpgrade contract contains a modifier for handling mutual upgrades between two parties
 *
 * CHANGELOG
 * - 4/20/23: Upgrade to Solidity 0.8.19
 */
contract MutualUpgrade {
    /* ============ State Variables ============ */

    // Mapping of upgradable units and if upgrade has been initialized by other party
    mapping(bytes32 => bool) public mutualUpgrades;

    /* ============ Events ============ */

    event MutualUpgradeRegistered(
        bytes32 _upgradeHash
    );

    /* ============ Modifiers ============ */

    modifier mutualUpgrade(address _signerOne, address _signerTwo) {
        require(
            msg.sender == _signerOne || msg.sender == _signerTwo,
            "Must be authorized address"
        );

        address nonCaller = _getNonCaller(_signerOne, _signerTwo);

        // The upgrade hash is defined by the hash of the transaction call data and sender of msg,
        // which uniquely identifies the function, arguments, and sender.
        bytes32 expectedHash = keccak256(abi.encodePacked(msg.data, nonCaller));

        if (!mutualUpgrades[expectedHash]) {
            bytes32 newHash = keccak256(abi.encodePacked(msg.data, msg.sender));

            mutualUpgrades[newHash] = true;

            emit MutualUpgradeRegistered(newHash);

            return;
        }

        delete mutualUpgrades[expectedHash];

        // Run the rest of the upgrades
        _;
    }

    /* ============ Internal Functions ============ */

    function _getNonCaller(address _signerOne, address _signerTwo) internal view returns(address) {
        return msg.sender == _signerOne ? _signerTwo : _signerOne;
    }
}

/*
    Copyright 2022 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

/**
 * @title MutualUpgradeV2
 * @author Set Protocol
 *
 * The MutualUpgradeV2 contract contains a modifier for handling mutual upgrades between two parties
 *
 * CHANGELOG
 * - Update mutualUpgrade to allow single transaction execution if the two signing addresses are the same
 * - 4/20/23: Upgrade to Solidity 0.8.19
 */
contract MutualUpgradeV2 {
    /* ============ State Variables ============ */

    // Mapping of upgradable units and if upgrade has been initialized by other party
    mapping(bytes32 => bool) public mutualUpgrades;

    /* ============ Events ============ */

    event MutualUpgradeRegistered(
        bytes32 _upgradeHash
    );

    /* ============ Modifiers ============ */

    modifier mutualUpgrade(address _signerOne, address _signerTwo) {
        require(
            msg.sender == _signerOne || msg.sender == _signerTwo,
            "Must be authorized address"
        );

        // If the two signing addresses are the same, skip upgrade hash step
        if (_signerOne == _signerTwo) {
            _;
        }

        address nonCaller = _getNonCaller(_signerOne, _signerTwo);

        // The upgrade hash is defined by the hash of the transaction call data and sender of msg,
        // which uniquely identifies the function, arguments, and sender.
        bytes32 expectedHash = keccak256(abi.encodePacked(msg.data, nonCaller));

        if (!mutualUpgrades[expectedHash]) {
            bytes32 newHash = keccak256(abi.encodePacked(msg.data, msg.sender));

            mutualUpgrades[newHash] = true;

            emit MutualUpgradeRegistered(newHash);

            return;
        }

        delete mutualUpgrades[expectedHash];

        // Run the rest of the upgrades
        _;
    }

    /* ============ Internal Functions ============ */

    function _getNonCaller(address _signerOne, address _signerTwo) internal view returns(address) {
        return msg.sender == _signerOne ? _signerTwo : _signerOne;
    }
}

/*
    Copyright 2022 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { AddressArrayUtils } from "@amun/amun-protocol/contracts/lib/AddressArrayUtils.sol";
import { ISetToken } from "@amun/amun-protocol/contracts/interfaces/ISetToken.sol";
import { PreciseUnitMath } from "@amun/amun-protocol/contracts/lib/PreciseUnitMath.sol";

import { IGlobalExtension } from "../interfaces/IGlobalExtension.sol";
import { MutualUpgradeV2 } from "../lib/MutualUpgradeV2.sol";

/**
 * @title DelegatedManager
 * @author Set Protocol
 *
 * Smart contract manager that maintains permissions and SetToken admin functionality via owner role. Owner
 * works alongside methodologist to ensure business agreements are kept. Owner is able to delegate maintenance
 * operations to operator(s). There can be more than one operator, however they have a global role so once
 * delegated to they can perform any operator delegated roles. The owner is able to set restrictions on what
 * operators can do in the form of asset whitelists. Operators cannot trade/wrap/claim/etc. an asset that is not
 * a part of the asset whitelist, hence they are a semi-trusted party. It is recommended that the owner address
 * be managed by a multi-sig or some form of permissioning system.
 *
 * CHANGELOG
 * - 4/20/23: Upgrade to Solidity 0.8.19
 */
contract DelegatedManager is Ownable, MutualUpgradeV2 {
    using Address for address;
    using AddressArrayUtils for address[];
    using SafeERC20 for IERC20;

    /* ============ Enums ============ */

    enum ExtensionState {
        NONE,
        PENDING,
        INITIALIZED
    }

    /* ============ Events ============ */

    event MethodologistChanged(
        address indexed _newMethodologist
    );

    event ExtensionAdded(
        address indexed _extension
    );

    event ExtensionRemoved(
        address indexed _extension
    );

    event ExtensionInitialized(
        address indexed _extension
    );

    event OperatorAdded(
        address indexed _operator
    );

    event OperatorRemoved(
        address indexed _operator
    );

    event AllowedAssetAdded(
        address indexed _asset
    );

    event AllowedAssetRemoved(
        address indexed _asset
    );

    event UseAssetAllowlistUpdated(
        bool _status
    );

    event OwnerFeeSplitUpdated(
        uint256 _newFeeSplit
    );

    event OwnerFeeRecipientUpdated(
        address indexed _newFeeRecipient
    );

    /* ============ Modifiers ============ */

    /**
     * Throws if the sender is not the SetToken methodologist
     */
    modifier onlyMethodologist() {
        require(msg.sender == methodologist, "Must be methodologist");
        _;
    }

    /**
     * Throws if the sender is not an initialized extension
     */
    modifier onlyExtension() {
        require(extensionAllowlist[msg.sender] == ExtensionState.INITIALIZED, "Must be initialized extension");
        _;
    }

    /* ============ State Variables ============ */

    // Instance of SetToken
    ISetToken public immutable setToken;

    // Address of factory contract used to deploy contract
    address public immutable factory;

    // Mapping to check which ExtensionState a given extension is in
    mapping(address => ExtensionState) public extensionAllowlist;

    // Array of initialized extensions
    address[] internal extensions;

    // Mapping indicating if address is an approved operator
    mapping(address=>bool) public operatorAllowlist;

    // List of approved operators
    address[] internal operators;

    // Mapping indicating if asset is approved to be traded for, wrapped into, claimed, etc.
    mapping(address=>bool) public assetAllowlist;

    // List of allowed assets
    address[] internal allowedAssets;

    // Toggle if asset allow list is being enforced
    bool public useAssetAllowlist;

    // Global owner fee split that can be referenced by Extensions
    uint256 public ownerFeeSplit;

    // Address owners portions of fees get sent to
    address public ownerFeeRecipient;

    // Address of methodologist which serves as providing methodology for the index and receives fee splits
    address public methodologist;

    /* ============ Constructor ============ */

    constructor(
        ISetToken _setToken,
        address _factory,
        address _methodologist,
        address[] memory _extensions,
        address[] memory _operators,
        address[] memory _allowedAssets,
        bool _useAssetAllowlist
    )
    {
        setToken = _setToken;
        factory = _factory;
        methodologist = _methodologist;
        useAssetAllowlist = _useAssetAllowlist;
        emit UseAssetAllowlistUpdated(_useAssetAllowlist);

        _addExtensions(_extensions);
        _addOperators(_operators);
        _addAllowedAssets(_allowedAssets);
    }

    /* ============ External Functions ============ */

    /**
     * ONLY EXTENSION: Interact with a module registered on the SetToken. In order to ensure SetToken admin
     * functions can only be changed from this contract no calls to the SetToken can originate from Extensions.
     * To transfer SetTokens use the `transferTokens` function.
     *
     * @param _module           Module to interact with
     * @param _data             Byte data of function to call in module
     */
    function interactManager(address _module, bytes calldata _data) external onlyExtension {
        require(_module != address(setToken), "Extensions cannot call SetToken");
        // Invoke call to module, assume value will always be 0
        _module.functionCallWithValue(_data, 0);
    }

    /**
     * ONLY EXTENSION: Transfers _tokens held by the manager to _destination. Can be used to
     * distribute fees or recover anything sent here accidentally.
     *
     * @param _token           ERC20 token to send
     * @param _destination     Address receiving the tokens
     * @param _amount          Quantity of tokens to send
     */
    function transferTokens(address _token, address _destination, uint256 _amount) external onlyExtension {
        IERC20(_token).safeTransfer(_destination, _amount);
    }

    /**
     * ANYONE CALLABLE: Initializes an added extension from PENDING to INITIALIZED state and adds to extension array. An
     * address can only enter a PENDING state if it is an enabled extension added by the manager. Only
     * callable by the extension itself, hence msg.sender is the subject of update.
     */
    function initializeExtension() external {
        require(extensionAllowlist[msg.sender] == ExtensionState.PENDING, "Extension must be pending");

        extensionAllowlist[msg.sender] = ExtensionState.INITIALIZED;
        extensions.push(msg.sender);

        emit ExtensionInitialized(msg.sender);
    }

    /**
     * ONLY OWNER: Add new extension(s) that the DelegatedManager can call. Puts extensions into PENDING
     * state, each must be initialized in order to be used.
     *
     * @param _extensions           New extension(s) to add
     */
    function addExtensions(address[] memory _extensions) external onlyOwner {
        _addExtensions(_extensions);
    }

    /**
     * ONLY OWNER: Remove existing extension(s) tracked by the DelegatedManager. Removed extensions are
     * placed in NONE state.
     *
     * @param _extensions           Old extension to remove
     */
    function removeExtensions(address[] memory _extensions) external onlyOwner {
        uint256 extensionsLen = _extensions.length;
        for (uint256 i; i < extensionsLen;) {
            address extension = _extensions[i];

            require(extensionAllowlist[extension] == ExtensionState.INITIALIZED, "Extension not initialized");

            extensions.removeStorage(extension);

            extensionAllowlist[extension] = ExtensionState.NONE;

            IGlobalExtension(extension).removeExtension();

            emit ExtensionRemoved(extension);

            unchecked { ++i; }
        }
    }

    /**
     * ONLY OWNER: Add new operator(s) address(es)
     *
     * @param _operators           New operator(s) to add
     */
    function addOperators(address[] memory _operators) external onlyOwner {
        _addOperators(_operators);
    }

    /**
     * ONLY OWNER: Remove operator(s) from the allowlist
     *
     * @param _operators           New operator(s) to remove
     */
    function removeOperators(address[] memory _operators) external onlyOwner {
        uint256 operatorsLen = _operators.length;
        for (uint256 i; i < operatorsLen;) {
            address operator = _operators[i];

            require(operatorAllowlist[operator], "Operator not already added");

            operators.removeStorage(operator);

            operatorAllowlist[operator] = false;

            emit OperatorRemoved(operator);

            unchecked { ++i; }
        }
    }

    /**
     * ONLY OWNER: Add new asset(s) that can be traded to, wrapped to, or claimed
     *
     * @param _assets           New asset(s) to add
     */
    function addAllowedAssets(address[] memory _assets) external onlyOwner {
        _addAllowedAssets(_assets);
    }

    /**
     * ONLY OWNER: Remove asset(s) so that it/they can't be traded to, wrapped to, or claimed
     *
     * @param _assets           Asset(s) to remove
     */
    function removeAllowedAssets(address[] memory _assets) external onlyOwner {
        uint256 assetsLen = _assets.length;
        for (uint256 i; i < assetsLen;) {
            address asset = _assets[i];

            require(assetAllowlist[asset], "Asset not already added");

            allowedAssets.removeStorage(asset);

            assetAllowlist[asset] = false;

            emit AllowedAssetRemoved(asset);

            unchecked { ++i; }
        }
    }

    /**
     * ONLY OWNER: Toggle useAssetAllowlist on and off. When false asset allowlist is ignored
     * when true it is enforced.
     *
     * @param _useAssetAllowlist           Bool indicating whether to use asset allow list
     */
    function updateUseAssetAllowlist(bool _useAssetAllowlist) external onlyOwner {
        useAssetAllowlist = _useAssetAllowlist;

        emit UseAssetAllowlistUpdated(_useAssetAllowlist);
    }

    /**
     * MUTUAL UPGRADE: Update percent of fees that are sent to owner.
     * Owner and Methodologist must each call this function to execute the update.
     * If Owner and Methodologist point to the same address, the update can be executed in a single call.
     *
     * @param _newFeeSplit           Percent in precise units (100% = 10**18) of fees that accrue to owner
     */
    function updateOwnerFeeSplit(uint256 _newFeeSplit) external mutualUpgrade(owner(), methodologist) {
        require(_newFeeSplit <= PreciseUnitMath.preciseUnit(), "Invalid fee split");

        ownerFeeSplit = _newFeeSplit;

        emit OwnerFeeSplitUpdated(_newFeeSplit);
    }

    /**
     * ONLY OWNER: Update address owner receives fees at
     *
     * @param _newFeeRecipient           Address to send owner fees to
     */
    function updateOwnerFeeRecipient(address _newFeeRecipient) external onlyOwner {
        require(_newFeeRecipient != address(0), "Null address passed");

        ownerFeeRecipient = _newFeeRecipient;

        emit OwnerFeeRecipientUpdated(_newFeeRecipient);
    }

    /**
     * ONLY METHODOLOGIST: Update the methodologist address
     *
     * @param _newMethodologist           New methodologist address
     */
    function setMethodologist(address _newMethodologist) external onlyMethodologist {
        require(_newMethodologist != address(0), "Null address passed");

        methodologist = _newMethodologist;

        emit MethodologistChanged(_newMethodologist);
    }

    /**
     * ONLY OWNER: Update the SetToken manager address.
     *
     * @param _newManager           New manager address
     */
    function setManager(address _newManager) external onlyOwner {
        require(_newManager != address(0), "Zero address not valid");
        require(extensions.length == 0, "Must remove all extensions");
        setToken.setManager(_newManager);
    }

    /**
     * ONLY OWNER: Add a new module to the SetToken.
     *
     * @param _module           New module to add
     */
    function addModule(address _module) external onlyOwner {
        setToken.addModule(_module);
    }

    /**
     * ONLY OWNER: Remove a module from the SetToken.
     *
     * @param _module           Module to remove
     */
    function removeModule(address _module) external onlyOwner {
        setToken.removeModule(_module);
    }

    /* ============ External View Functions ============ */

    function isAllowedAsset(address _asset) external view returns(bool) {
        return !useAssetAllowlist || assetAllowlist[_asset];
    }

    function isPendingExtension(address _extension) external view returns(bool) {
        return extensionAllowlist[_extension] == ExtensionState.PENDING;
    }

    function isInitializedExtension(address _extension) external view returns(bool) {
        return extensionAllowlist[_extension] == ExtensionState.INITIALIZED;
    }

    function getExtensions() external view returns(address[] memory) {
        return extensions;
    }

    function getOperators() external view returns(address[] memory) {
        return operators;
    }

    function getAllowedAssets() external view returns(address[] memory) {
        return allowedAssets;
    }

    /* ============ Internal Functions ============ */

    /**
     * Add extensions that the DelegatedManager can call.
     *
     * @param _extensions           New extension to add
     */
    function _addExtensions(address[] memory _extensions) internal {
        uint256 extensionsLen = _extensions.length;
        for (uint256 i; i < extensionsLen;) {
            address extension = _extensions[i];

            require(extensionAllowlist[extension] == ExtensionState.NONE , "Extension already exists");

            extensionAllowlist[extension] = ExtensionState.PENDING;

            emit ExtensionAdded(extension);

            unchecked { ++i; }
        }
    }

    /**
     * Add new operator(s) address(es)
     *
     * @param _operators           New operator to add
     */
    function _addOperators(address[] memory _operators) internal {
        uint256 operatorsLen = _operators.length;
        for (uint256 i; i < operatorsLen;) {
            address operator = _operators[i];

            require(!operatorAllowlist[operator], "Operator already added");

            operators.push(operator);

            operatorAllowlist[operator] = true;

            emit OperatorAdded(operator);

            unchecked { ++i; }
        }
    }

    /**
     * Add new assets that can be traded to, wrapped to, or claimed
     *
     * @param _assets           New asset to add
     */
    function _addAllowedAssets(address[] memory _assets) internal {
        uint256 assetsLen = _assets.length;
        for (uint256 i; i < assetsLen;) {
            address asset = _assets[i];

            require(!assetAllowlist[asset], "Asset already added");

            allowedAssets.push(asset);

            assetAllowlist[asset] = true;

            emit AllowedAssetAdded(asset);

            unchecked { ++i; }
        }
    }
}

/*
    Copyright 2022 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { AddressArrayUtils } from "@amun/amun-protocol/contracts/lib/AddressArrayUtils.sol";

/**
 * @title ManagerCore
 * @author Set Protocol
 *
 *  Registry for governance approved GlobalExtensions, DelegatedManagerFactories, and DelegatedManagers.
 *
 * CHANGELOG
 * - 4/20/23: Upgrade to Solidity 0.8.19
 */
contract ManagerCore is Ownable {
    using AddressArrayUtils for address[];

    /* ============ Events ============ */

    event ExtensionAdded(address indexed _extension);
    event ExtensionRemoved(address indexed _extension);
    event FactoryAdded(address indexed _factory);
    event FactoryRemoved(address indexed _factory);
    event ManagerAdded(address indexed _manager, address indexed _factory);
    event ManagerRemoved(address indexed _manager);

    /* ============ Modifiers ============ */

    /**
     * Throws if function is called by any address other than a valid factory.
     */
    modifier onlyFactory() {
        require(isFactory[msg.sender], "Only valid factories can call");
        _;
    }

    modifier onlyInitialized() {
        require(isInitialized, "Contract must be initialized.");
        _;
    }

    /* ============ State Variables ============ */

    // List of enabled extensions
    address[] public extensions;
    // List of enabled factories of managers
    address[] public factories;
    // List of enabled managers
    address[] public managers;

    // Mapping to check whether address is valid Extension, Factory, or Manager
    mapping(address => bool) public isExtension;
    mapping(address => bool) public isFactory;
    mapping(address => bool) public isManager;


    // Return true if the ManagerCore is initialized
    bool public isInitialized;

    /* ============ External Functions ============ */

    /**
     * ONLY OWNER: Initializes any predeployed factories. Note: This function can only be called by
     * the owner once to batch initialize the initial system contracts.
     *
     * @param _extensions            List of extensions to add
     * @param _factories             List of factories to add
     */
    function initialize(
        address[] memory _extensions,
        address[] memory _factories
    ) external onlyOwner {
        require(!isInitialized, "ManagerCore is already initialized");

        extensions = _extensions;
        factories = _factories;

        // Loop through and initialize isExtension and isFactory mapping
        uint256 extensionsLen = _extensions.length;
        for (uint256 i; i < extensionsLen;) {
            _addExtension(_extensions[i]);
            unchecked { ++i; }
        }
        uint256 factoriesLen = _factories.length;
        for (uint256 i; i < factoriesLen;) {
            _addFactory(_factories[i]);
            unchecked { ++i; }
        }

        // Set to true to only allow initialization once
        isInitialized = true;
    }

    /**
     * ONLY OWNER: Allows governance to add an extension
     *
     * @param _extension               Address of the extension contract to add
     */
    function addExtension(address _extension) external onlyInitialized onlyOwner {
        require(!isExtension[_extension], "Extension already exists");

        _addExtension(_extension);

        extensions.push(_extension);
    }

    /**
     * ONLY OWNER: Allows governance to remove an extension
     *
     * @param _extension               Address of the extension contract to remove
     */
    function removeExtension(address _extension) external onlyInitialized onlyOwner {
        require(isExtension[_extension], "Extension does not exist");

        extensions.removeStorage(_extension);

        isExtension[_extension] = false;

        emit ExtensionRemoved(_extension);
    }

    /**
     * ONLY OWNER: Allows governance to add a factory
     *
     * @param _factory               Address of the factory contract to add
     */
    function addFactory(address _factory) external onlyInitialized onlyOwner {
        require(!isFactory[_factory], "Factory already exists");

        _addFactory(_factory);

        factories.push(_factory);
    }

    /**
     * ONLY OWNER: Allows governance to remove a factory
     *
     * @param _factory               Address of the factory contract to remove
     */
    function removeFactory(address _factory) external onlyInitialized onlyOwner {
        require(isFactory[_factory], "Factory does not exist");

        factories.removeStorage(_factory);

        isFactory[_factory] = false;

        emit FactoryRemoved(_factory);
    }

    /**
     * ONLY FACTORY: Adds a newly deployed manager as an enabled manager.
     *
     * @param _manager               Address of the manager contract to add
     */
    function addManager(address _manager) external onlyInitialized onlyFactory {
        require(!isManager[_manager], "Manager already exists");

        isManager[_manager] = true;

        managers.push(_manager);

        emit ManagerAdded(_manager, msg.sender);
    }

    /**
     * ONLY OWNER: Allows governance to remove a manager
     *
     * @param _manager               Address of the manager contract to remove
     */
    function removeManager(address _manager) external onlyInitialized onlyOwner {
        require(isManager[_manager], "Manager does not exist");

        managers.removeStorage(_manager);

        isManager[_manager] = false;

        emit ManagerRemoved(_manager);
    }

    /* ============ External Getter Functions ============ */

    function getExtensions() external view returns (address[] memory) {
        return extensions;
    }

    function getFactories() external view returns (address[] memory) {
        return factories;
    }

    function getManagers() external view returns (address[] memory) {
        return managers;
    }

    /* ============ Internal Functions ============ */

    /**
     * Add an extension tracked on the ManagerCore
     *
     * @param _extension               Address of the extension contract to add
     */
    function _addExtension(address _extension) internal {
        require(_extension != address(0), "Zero address submitted.");

        isExtension[_extension] = true;

        emit ExtensionAdded(_extension);
    }

    /**
     * Add a factory tracked on the ManagerCore
     *
     * @param _factory               Address of the factory contract to add
     */
    function _addFactory(address _factory) internal {
        require(_factory != address(0), "Zero address submitted.");

        isFactory[_factory] = true;

        emit FactoryAdded(_factory);
    }
}

/*
    Copyright 2022 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

import { ISetToken } from "@amun/amun-protocol/contracts/interfaces/ISetToken.sol";

import { BaseGlobalExtension } from "../lib/BaseGlobalExtension.sol";
import { IDelegatedManager } from "../interfaces/IDelegatedManager.sol";
import { IManagerCore } from "../interfaces/IManagerCore.sol";
import { ModuleMock } from "./ModuleMock.sol";

contract BaseGlobalExtensionMock is BaseGlobalExtension {

    /* ============ State Variables ============ */

    ModuleMock public immutable module;

    /* ============ Constructor ============ */

    constructor(
        IManagerCore _managerCore,
        ModuleMock _module
    )
        BaseGlobalExtension(_managerCore)
    {
        module = _module;
    }

    /* ============ External Functions ============ */

    function initializeExtension(
        IDelegatedManager _delegatedManager
    )
        external
        onlyOwnerAndValidManager(_delegatedManager)
    {
        require(_delegatedManager.isPendingExtension(address(this)), "Extension must be pending");

        _initializeExtension(_delegatedManager.setToken(), _delegatedManager);
    }

    function initializeModuleAndExtension(
        IDelegatedManager _delegatedManager
    )
        external
        onlyOwnerAndValidManager(_delegatedManager)
    {
        require(_delegatedManager.isPendingExtension(address(this)), "Extension must be pending");

        ISetToken setToken = _delegatedManager.setToken();

        _initializeExtension(setToken, _delegatedManager);

        bytes memory callData = abi.encodeWithSignature("initialize(address)", setToken);
        _invokeManager(_delegatedManager, address(module), callData);
    }

    function testInvokeManager(ISetToken _setToken, address _module, bytes calldata _encoded) external {
        _invokeManager(_manager(_setToken), _module, _encoded);
    }

    function testOnlyOwner(ISetToken _setToken)
        external
        onlyOwner(_setToken)
    {}

    function testOnlyMethodologist(ISetToken _setToken)
        external
        onlyMethodologist(_setToken)
    {}

    function testOnlyOperator(ISetToken _setToken)
        external
        onlyOperator(_setToken)
    {}

    function testOnlyOwnerAndValidManager(IDelegatedManager _delegatedManager)
        external
        onlyOwnerAndValidManager(_delegatedManager)
    {}

    function testOnlyAllowedAsset(ISetToken _setToken, address _asset)
        external
        onlyAllowedAsset(_setToken, _asset)
    {}

    function removeExtension() external override {
        IDelegatedManager delegatedManager = IDelegatedManager(msg.sender);
        ISetToken setToken = delegatedManager.setToken();

        _removeExtension(setToken, delegatedManager);
    }
}

/*
    Copyright 2023 Amun Holdings Limited and affiliated entities.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IExchangeAdapter } from "@amun/amun-protocol/contracts/interfaces/IExchangeAdapter.sol";

/**
 * Dynamic Data Trade Adapter that doubles as a mock exchange with fixed input amount passed from off-chain
 */
contract DynamicDataTradeAdapterMock is IExchangeAdapter {

    event Trade(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount
    );

    function isDynamicDataAdapter() override external pure returns(bool) {
        return true;
    }

    function getTradeMetadata(
        bytes memory _data
    )
        override
        external
        pure
        returns (bytes4 signature, address fromToken, address toToken, uint256 inputAmount, uint256 minAmountOut) {
            // Parse calldata and validate parameters match expected inputs
            // solium-disable-next-line security/no-inline-assembly
            assembly {            
                // Shift pointer by 32 bytes in order to account for bytes length 
                signature := mload(add(_data, 32))
                fromToken := mload(add(_data, 36))
                toToken := mload(add(_data, 68))
                inputAmount := mload(add(_data, 132))
                minAmountOut := mload(add(_data, 164))
            }

    }
    
    /* ============ Helper Functions ============ */

    function withdraw(address _token)
        external
    {
        uint256 balance = ERC20(_token).balanceOf(address(this));
        require(ERC20(_token).transfer(msg.sender, balance), "ERC20 transfer failed");
    }

    /* ============ Trade Functions ============ */

    function trade(
        address _sourceToken,
        address _destinationToken,
        address _destinationAddress,
        uint256 _sourceQuantity,
        uint256 _minDestinationQuantity
    )
        external
    {
        uint256 destinationBalance = ERC20(_destinationToken).balanceOf(address(this));
        require(ERC20(_sourceToken).transferFrom(_destinationAddress, address(this), _sourceQuantity), "ERC20 TransferFrom failed");

        if (_minDestinationQuantity == 1) { // byte revert case, min nonzero uint256 minimum receive quantity
            bytes memory data = abi.encodeWithSelector(
                bytes4(keccak256("trade(address,address,address,uint256,uint256)")),
                _sourceToken,
                _destinationToken,
                _destinationAddress,
                _sourceQuantity,
                _minDestinationQuantity
            );
            assembly { revert(add(data, 32), mload(data)) }
        }
        if (destinationBalance >= _minDestinationQuantity) { // normal case
            require(ERC20(_destinationToken).transfer(_destinationAddress, destinationBalance), "ERC20 transfer failed");
            emit Trade(_sourceToken, _destinationToken, _sourceQuantity, destinationBalance);
        }
        else { // string revert case, minimum destination quantity not in exchange
            revert("Insufficient funds in exchange");
        }
    }

    /* ============ Adapter Functions ============ */

    function getSpender()
        override
        external
        view
        returns (address)
    {
        return address(this);
    }

    function getTradeCalldata(
        address _sourceToken,
        address _destinationToken,
        address _destinationAddress,
        uint256 _sourceQuantity,
        uint256 _minDestinationQuantity,
        bytes memory /* _data */
    )
        override
        external
        view
        returns (address, uint256, bytes memory)
    {
        // Encode method data for SetToken to invoke
        bytes memory methodData = abi.encodeWithSignature(
            "trade(address,address,address,uint256,uint256)",
            _sourceToken,
            _destinationToken,
            _destinationAddress,
            _sourceQuantity,
            _minDestinationQuantity
        );

        return (address(this), 0, methodData);
    }
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

import { ISetToken } from "@amun/amun-protocol/contracts/interfaces/ISetToken.sol";

import { IGlobalExtension } from "../interfaces/IGlobalExtension.sol";

contract ManagerMock {
    ISetToken public immutable setToken;

    constructor(
        ISetToken _setToken
    )
    {
        setToken = _setToken;
    }

    function removeExtensions(address[] memory _extensions) external {
        uint256 extensionsLen = _extensions.length;
        for (uint256 i; i < extensionsLen;) {
            address extension = _extensions[i];
            IGlobalExtension(extension).removeExtension();
            unchecked { ++i; }
        }
    }
}

/*
    Copyright 2022 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

import { IController } from "@amun/amun-protocol/contracts/interfaces/IController.sol";
import { ISetToken } from "@amun/amun-protocol/contracts/interfaces/ISetToken.sol";
import { ModuleBase } from "@amun/amun-protocol/contracts/protocol/lib/ModuleBase.sol";

contract ModuleMock is ModuleBase {

    bool public removed;

    /* ============ Constructor ============ */

    constructor(IController _controller) ModuleBase(_controller) {}

    /* ============ External Functions ============ */

    function initialize(
        ISetToken _setToken
    )
        external
        onlyValidAndPendingSet(_setToken)
        onlySetManager(_setToken, msg.sender)
    {
        _setToken.initializeModule();
    }

    function removeModule() external override {
        removed = true;
    }
}

/*
    Copyright 2022 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

import { MutualUpgrade } from "../lib/MutualUpgrade.sol";


// Mock contract implementation of MutualUpgrade functions
contract MutualUpgradeMock is
    MutualUpgrade
{
    uint256 public testUint;
    address public owner;
    address public methodologist;

    constructor(address _owner, address _methodologist) {
        owner = _owner;
        methodologist = _methodologist;
    }

    function testMutualUpgrade(
        uint256 _testUint
    )
        external
        mutualUpgrade(owner, methodologist)
    {
        testUint = _testUint;
    }
}

/*
    Copyright 2022 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

import { MutualUpgradeV2 } from "../lib/MutualUpgradeV2.sol";


// Mock contract implementation of MutualUpgradeV2 functions
contract MutualUpgradeV2Mock is
    MutualUpgradeV2
{
    uint256 public testUint;
    address public owner;
    address public methodologist;

    constructor(address _owner, address _methodologist) {
        owner = _owner;
        methodologist = _methodologist;
    }

    function testMutualUpgrade(
        uint256 _testUint
    )
        external
        mutualUpgrade(owner, methodologist)
    {
        testUint = _testUint;
    }
}

/*
    Copyright 2022 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.19;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * Trade Adapter that doubles as a mock exchange
 */
contract TradeAdapterMock {

    /* ============ Helper Functions ============ */

    function withdraw(address _token)
        external
    {
        uint256 balance = ERC20(_token).balanceOf(address(this));
        require(ERC20(_token).transfer(msg.sender, balance), "ERC20 transfer failed");
    }

    /* ============ Trade Functions ============ */

    function trade(
        address _sourceToken,
        address _destinationToken,
        address _destinationAddress,
        uint256 _sourceQuantity,
        uint256 _minDestinationQuantity
    )
        external
    {
        uint256 destinationBalance = ERC20(_destinationToken).balanceOf(address(this));
        require(ERC20(_sourceToken).transferFrom(_destinationAddress, address(this), _sourceQuantity), "ERC20 TransferFrom failed");
        if (_minDestinationQuantity == 1) { // byte revert case, min nonzero uint256 minimum receive quantity
            bytes memory data = abi.encodeWithSelector(
                bytes4(keccak256("trade(address,address,address,uint256,uint256)")),
                _sourceToken,
                _destinationToken,
                _destinationAddress,
                _sourceQuantity,
                _minDestinationQuantity
            );
            assembly { revert(add(data, 32), mload(data)) }
        }
        require(destinationBalance >= _minDestinationQuantity, "Insufficient funds in exchange");
        require(ERC20(_destinationToken).transfer(_destinationAddress, destinationBalance), "ERC20 transfer failed");
    }

    /* ============ Adapter Functions ============ */

    function getSpender()
        external
        view
        returns (address)
    {
        return address(this);
    }

    function getTradeCalldata(
        address _sourceToken,
        address _destinationToken,
        address _destinationAddress,
        uint256 _sourceQuantity,
        uint256 _minDestinationQuantity,
        bytes memory /* _data */
    )
        external
        view
        returns (address, uint256, bytes memory)
    {
        // Encode method data for SetToken to invoke
        bytes memory methodData = abi.encodeWithSignature(
            "trade(address,address,address,uint256,uint256)",
            _sourceToken,
            _destinationToken,
            _destinationAddress,
            _sourceQuantity,
            _minDestinationQuantity
        );

        return (address(this), 0, methodData);
    }
}