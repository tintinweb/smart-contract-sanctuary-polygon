// SPDX-License-Identifier: ISC
pragma solidity ^0.8.15;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ======================= FraxlendWhitelist ==========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis Ettes: https://github.com/denett
// Sam Kazemian: https://github.com/samkazemian
// Travis Moore: https://github.com/FortisFortuna
// Jack Corddry: https://github.com/corddry
// Rich Gee: https://github.com/zer0blockchain

// ====================================================================

import "./interfaces/IFraxlendWhitelist.sol";

contract FraxlendWhitelist is IFraxlendWhitelist {
    // Constants
    address public immutable COMPTROLLER_ADDRESS;

    // Oracle Whitelist Storage
    mapping(address => bool) public oracleContractWhitelist;

    // Interest Rate Calculator Whitelist Storage
    mapping(address => bool) public rateContractWhitelist;

    // Fraxlend Deployer Whitelist Storage
    mapping(address => bool) public fraxlendDeployerWhitelist;

    constructor(address _comptroller) {
        COMPTROLLER_ADDRESS = _comptroller;
    }

    modifier onlyByAdmin() {
        require(msg.sender == COMPTROLLER_ADDRESS, "FraxlendWhitelist: Authorized addresses only");
        _;
    }

    // Oracle Whitelist setter
    function setOracleContractWhitelist(address[] calldata _addresses, bool _bool) external onlyByAdmin {
        for (uint256 i = 0; i < _addresses.length; i++) {
            oracleContractWhitelist[_addresses[i]] = _bool;
        }
    }

    // Interest Rate Calculator Whitelist setter
    function setRateContractWhitelist(address[] calldata _addresses, bool _bool) external onlyByAdmin {
        for (uint256 i = 0; i < _addresses.length; i++) {
            rateContractWhitelist[_addresses[i]] = _bool;
        }
    }

    // FraxlendDeployer Whitelist setter
    function setFraxlendDeployerWhitelist(address[] calldata _addresses, bool _bool) external onlyByAdmin {
        for (uint256 i = 0; i < _addresses.length; i++) {
            fraxlendDeployerWhitelist[_addresses[i]] = _bool;
        }
    }
}

// SPDX-License-Identifier: ISC
pragma solidity >=0.8.15;

interface IFraxlendWhitelist {
    function COMPTROLLER_ADDRESS() external view returns (address);

    function oracleContractWhitelist(address) external view returns (bool);

    function rateContractWhitelist(address) external view returns (bool);

    function fraxlendDeployerWhitelist(address) external view returns (bool);

    function setOracleContractWhitelist(address[] calldata _address, bool _bool) external;

    function setRateContractWhitelist(address[] calldata _address, bool _bool) external;

    function setFraxlendDeployerWhitelist(address[] calldata _address, bool _bool) external;
}