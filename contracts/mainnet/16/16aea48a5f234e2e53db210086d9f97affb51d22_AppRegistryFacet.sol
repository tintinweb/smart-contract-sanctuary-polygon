/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../diamond/IDiamondFacet.sol";
import "../../diamond/IAppRegistry.sol";
import "./AppRegistryInternal.sol";
import "./AppRegistryConfig.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract AppRegistryFacet is IDiamondFacet, IAppRegistry {

    function getFacetName() external pure override returns (string memory) {
        return "app-registry";
    }

    function getFacetVersion() external pure override returns (string memory) {
        return "2.0.0";
    }

    function getFacetPI() external pure override returns (string[] memory) {
        string[] memory pi = new string[](6);
        pi[0] = "getAllApps()";
        pi[1] = "getEnabledApps()";
        pi[2] = "isAppEnabled(string,string)";
        pi[3] = "addApp(string,string,address[],bool)";
        pi[4] = "enableApp(string,string,bool)";
        pi[5] = "getAppFacets(string,string)";
        return pi;
    }

    function getFacetProtectedPI() external pure override returns (string[] memory) {
        string[] memory pi = new string[](2);
        pi[0] = "addApp(string,string,address[],bool)";
        pi[1] = "enableApp(string,string,bool)";
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external view override virtual returns (bool) {
        return interfaceId == type(IDiamondFacet).interfaceId ||
               interfaceId == type(IAppRegistry).interfaceId;
    }

    function getAllApps() external view returns (string[] memory) {
        return AppRegistryInternal._getAllApps();
    }

    function getEnabledApps() external view returns (string[] memory) {
        return AppRegistryInternal._getEnabledApps();
    }

    function isAppEnabled(
        string memory name,
        string memory version
    ) external view returns (bool) {
        return AppRegistryInternal._isAppEnabled(name, version);
    }

    function addApp(
        string memory name,
        string memory version,
        address[] memory facets,
        bool enabled
    ) external {
        return AppRegistryInternal._addApp(name, version , facets, enabled);
    }

    // NOTE: This is the only mutator for the app entries
    function enableApp(
        string memory name,
        string memory version,
        bool enabled
    ) external {
        return AppRegistryInternal._enableApp(name, version, enabled);
    }

    function getAppFacets(
        string memory name,
        string memory version
    ) external view override returns (address[] memory) {
        return AppRegistryInternal._getAppFacets(name, version);
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface IDiamondFacet is IERC165 {

    // NOTE: The override MUST remain 'pure'.
    function getFacetName() external pure returns (string memory);

    // NOTE: The override MUST remain 'pure'.
    function getFacetVersion() external pure returns (string memory);

    // NOTE: The override MUST remain 'pure'.
    function getFacetPI() external pure returns (string[] memory);

    // NOTE: The override MUST remain 'pure'.
    function getFacetProtectedPI() external pure returns (string[] memory);
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface IAppRegistry {

    function getAppFacets(
        string memory appName,
        string memory appVersion
    ) external view returns (address[] memory);
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./AppRegistryStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library AppRegistryInternal {

    function _appExists(string memory name, string memory version) internal view returns (bool) {
        bytes32 nvh = __getNameVersionHash(name, version);
        return __getStrLen(__s().apps[nvh].name) > 0 &&
               __getStrLen(__s().apps[nvh].version) > 0;
    }

    function _getAllApps() internal view returns (string[] memory) {
        string[] memory apps = new string[](__s().appsArray.length);
        uint256 index = 0;
        for (uint256 i = 0; i < __s().appsArray.length; i++) {
            (string memory name, string memory version) = __deconAppArrayEntry(i);
            bytes32 nvh = __getNameVersionHash(name, version);
            if (__s().apps[nvh].enabled) {
                apps[index] = string(abi.encodePacked("E:", name, ":", version));
            } else {
                apps[index] = string(abi.encodePacked("D:", name, ":", version));
            }
            index += 1;
        }
        return apps;
    }

    function _getEnabledApps() internal view returns (string[] memory) {
        uint256 count = 0;
        {
            for (uint256 i = 0; i < __s().appsArray.length; i++) {
                (string memory name, string memory version) = __deconAppArrayEntry(i);
                bytes32 nvh = __getNameVersionHash(name, version);
                if (__s().apps[nvh].enabled) {
                    count += 1;
                }
            }
        }
        string[] memory apps = new string[](count);
        {
            uint256 index = 0;
            for (uint256 i = 0; i < __s().appsArray.length; i++) {
                (string memory name, string memory version) = __deconAppArrayEntry(i);
                bytes32 nvh = __getNameVersionHash(name, version);
                if (__s().apps[nvh].enabled) {
                    apps[index] = string(abi.encodePacked(name, ":", version));
                    index += 1;
                }
            }
        }
        return apps;
    }

    function _isAppEnabled(
        string memory name,
        string memory version
    ) internal view returns (bool) {
        require(_appExists(name, version), "AREG:ANF");
        bytes32 nvh = __getNameVersionHash(name, version);
        return (__s().apps[nvh].enabled);
    }

    function _addApp(
        string memory name,
        string memory version,
        address[] memory facets,
        bool enabled
    ) internal {
        require(facets.length > 0, "AREG:ZLEN");
        require(!_appExists(name, version), "AREG:AEX");

        __validateString(name);
        __validateString(version);

        // update apps entry
        bytes32 nvh = __getNameVersionHash(name, version);
        __s().apps[nvh].name = name;
        __s().apps[nvh].version = version;
        __s().apps[nvh].enabled = enabled;
        for (uint256 i = 0; i < facets.length; i++) {
            address facet = facets[i];
            __s().apps[nvh].facets.push(facet);
        }

        // update apps array
        bytes memory toAdd = abi.encode([name], [version]);
        __s().appsArray.push(toAdd);
    }

    // NOTE: This is the only mutator for the app entries
    function _enableApp(string memory name, string memory version, bool enabled) internal {
        require(_appExists(name, version), "AREG:ANF");
        bytes32 nvh = __getNameVersionHash(name, version);
        __s().apps[nvh].enabled = enabled;
    }

    function _getAppFacets(
        string memory appName,
        string memory appVersion
    ) internal view returns (address[] memory) {
        require(_appExists(appName, appVersion), "AREG:ANF");
        bytes32 nvh = __getNameVersionHash(appName, appVersion);
        return __s().apps[nvh].facets;
    }

    function __validateString(string memory str) private pure {
        bytes memory strBytes = bytes(str);
        for (uint256 i = 0; i < strBytes.length; i++) {
            bytes1 b = strBytes[i];
            if (
                !(b >= 0x30 && b <= 0x39) && // [0-9]
                !(b >= 0x41 && b <= 0x5a) && // [A-Z]
                !(b >= 0x61 && b <= 0x7a) && // [a-z]
                 b != 0x21 && // !
                 b != 0x23 && // #
                 b != 0x24 && // $
                 b != 0x25 && // %
                 b != 0x26 && // &
                 b != 0x28 && // (
                 b != 0x29 && // )
                 b != 0x2a && // *
                 b != 0x2b && // +
                 b != 0x2c && // ,
                 b != 0x2d && // -
                 b != 0x2e && // .
                 b != 0x3a && // =
                 b != 0x3d && // =
                 b != 0x3f && // ?
                 b != 0x3b && // ;
                 b != 0x40 && // @
                 b != 0x5e && // ^
                 b != 0x5f && // _
                 b != 0x5b && // [
                 b != 0x5d && // ]
                 b != 0x7b && // {
                 b != 0x7d && // }
                 b != 0x7e    // ~
            ) {
                revert("AREG:ISTR");
            }
        }
    }

    function __getStrLen(string memory str) private pure returns (uint256) {
        return bytes(str).length;
    }

    function __deconAppArrayEntry(uint256 index) private view returns (string memory, string memory) {
        (string[1] memory names, string[1] memory versions) =
            abi.decode(__s().appsArray[index], (string[1], string[1]));
        string memory name = names[0];
        string memory version = versions[0];
        return (name, version);
    }

    function __getNameVersionHash(string memory name, string memory version) private pure returns (bytes32) {
        return bytes32(keccak256(abi.encode(name, ":", version)));
    }

    function __s() private pure returns (AppRegistryStorage.Layout storage) {
        return AppRegistryStorage.layout();
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library AppRegistryConfig {

    uint256 constant public ROLE_APP_REGISTRY_ADMIN = uint256(keccak256(bytes("ROLE_REGISTRY_APP_ADMIN")));
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library AppRegistryStorage {

    struct AppEntry {
        string name;
        string version;
        bool enabled;
        address[] facets;
    }

    struct Layout {
        bytes[] appsArray;
        mapping(bytes32 => AppEntry) apps;
        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.diamond.facets.app-registry.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}