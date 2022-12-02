// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;
import "IProxyRegistry.sol";
import "IGamingProxy.sol";

contract ProxyRegistry is IProxyRegistry {
    address public immutable governance;

    mapping(address => address) public proxies;

    modifier onlyGovernance() {
        require(msg.sender == governance, "Only Governance is authorized");
        _;
    }

    constructor(address _governance) {
        governance = _governance;
    }

    function setProxyForGameContract(
        address gameContract,
        address proxyContract
    ) external override onlyGovernance {
        require(proxies[gameContract] == address(0), "Proxy already set!");
        proxies[gameContract] = proxyContract;
    }

    function updateProxyForGameContract(
        address gameContract,
        address proxyContract
    ) external override onlyGovernance {
        removeProxyForGameContract(gameContract);
        proxies[gameContract] = proxyContract;
    }

    function getProxyForGameContract(address gameContract)
        external
        view
        override
        returns (address)
    {
        return proxies[gameContract];
    }

    function isWhitelistedGameContract(address gameContract)
        external
        view
        override
        returns (bool)
    {
        return proxies[gameContract] != address(0);
    }

    function removeProxyForGameContract(address gameContract)
        public
        override
        onlyGovernance
    {
        require(proxies[gameContract] != address(0), "Proxy already set!");
        IGamingProxy(proxies[gameContract]).kill();
        proxies[gameContract] = address(0);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

// Registry of all currently used proxy contracts
interface IProxyRegistry {
    function setProxyForGameContract(
        address gameContract,
        address proxyContract
    ) external;

    function updateProxyForGameContract(
        address gameContract,
        address proxyContract
    ) external;

    function removeProxyForGameContract(address gameContract) external;

    function getProxyForGameContract(address gameContract)
        external
        view
        returns (address);

    // Function to check if the gameContract is whitelisted
    function isWhitelistedGameContract(address gameContract)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

// This will need to implement the delegation method
interface IGamingProxy {
    // Main point of entry for calling the gaming contracts (this will delegatecall to gaming contract)
    function postCallHook(
        address gameContract,
        bytes calldata data_,
        bytes calldata returnData
    ) external;

    function whitelistFunction(
        address gameContract,
        bytes4 selector,
        bool claimFunction
    ) external;

    function batchWhitelistFunction(
        address[] memory gameContracts,
        bytes4[] memory selectors,
        bool[] memory claimFunction
    ) external;

    function removeFunctionsFromWhitelist(address gameContract, bytes4 selector)
        external;

    function kill() external;

    function validateCall(address gameContract, bytes calldata data_)
        external
        view
        returns (bytes memory);

    function validateOasisClaimCall(address gameContract, bytes calldata data_)
        external
        view
        returns (bytes memory);

    function isFunctionsWhitelisted(address gameContract, bytes4 selector)
        external
        view
        returns (bool);

    function isClaimFunction(address gameContract, bytes4 selector)
        external
        view
        returns (bool);

    function gamingContracts() external view returns (address[] memory);

    function getFunctionsForContract(address gameContract)
        external
        view
        returns (bytes4[] memory);
}