// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "IGamingProxy.sol";

// This will need to implement the delegation method
contract GamingProxy is IGamingProxy {
    //TODO: Probably make this an enumerable mapping or something like that
    mapping(address => mapping(bytes4 => bool)) public whitelistedFunctions;
    mapping(address => mapping(bytes4 => bool)) public oasisClaimFunctions;
    address[] public _gamingContracts;
    mapping(address => bytes4[]) public functionsForContract;
    address public immutable governance;
    address public immutable proxyRegistry;
    bool public killed;

    modifier onlyGovernance() {
        require(msg.sender == governance, "Only Governance is authorized");
        _;
    }

    modifier onlyGovernanceOrRegistry() {
        require(
            msg.sender == governance || msg.sender == proxyRegistry,
            "Only Governance or registry is authorized"
        );
        _;
    }

    constructor(address _governance, address _proxyRegistry) {
        governance = _governance;
        proxyRegistry = _proxyRegistry;
    }

    function postCallHook(
        address gameContract,
        bytes calldata data_,
        bytes calldata returnData
    ) external override {
        // This allows to do some post-processing which would be game specific...
    }

    function whitelistFunction(
        address gameContract,
        bytes4 selector,
        bool claimFunction
    ) external override onlyGovernance {
        _whitelistFunction(gameContract, selector, claimFunction);
    }

    function batchWhitelistFunction(
        address[] memory gameContracts,
        bytes4[] memory selectors,
        bool[] memory claimFunction
    ) external override onlyGovernance {
        uint256 length = gameContracts.length;
        require(
            length == selectors.length,
            "Must supply a game contract for each selector!"
        );
        for (uint32 i = 0; i < length; i++) {
            _whitelistFunction(
                gameContracts[i],
                selectors[i],
                claimFunction[i]
            );
        }
    }

    function removeFunctionsFromWhitelist(address gameContract, bytes4 selector)
        external
        override
        onlyGovernance
    {
        uint256 length = functionsForContract[gameContract].length;
        for (uint32 i = 0; i < length; i++) {
            if (functionsForContract[gameContract][i] == selector) {
                functionsForContract[gameContract][i] = functionsForContract[
                    gameContract
                ][length - 1];
                functionsForContract[gameContract].pop();
            }
        }
        length = _gamingContracts.length;
        for (uint32 i = 0; i < length; i++) {
            if (_gamingContracts[i] == gameContract) {
                if (functionsForContract[gameContract].length == 0) {
                    _gamingContracts[i] = _gamingContracts[length - 1];
                    _gamingContracts.pop();
                }
            }
        }
        whitelistedFunctions[gameContract][selector] = false;
    }

    function kill() external override onlyGovernanceOrRegistry {
        require(!killed, "Already killed");
        killed = true;
    }

    function validateCall(address gameContract, bytes calldata data_)
        external
        view
        override
        returns (bytes memory)
    {
        require(!killed, "Proxy is no longer active!");
        require(
            isFunctionsWhitelisted(gameContract, bytes4(data_[:4])),
            "Function not whitelisted!"
        );
        // This could be changed to modify the data if needed for some games
        return data_;
    }

    function validateOasisClaimCall(address gameContract, bytes calldata data_)
        external
        view
        override
        returns (bytes memory)
    {
        require(!killed, "Proxy is no longer active!");
        require(
            isClaimFunction(gameContract, bytes4(data_[:4])),
            "Function is not a claim function!"
        );
        // This could be changed to modify the data if needed for some games
        return data_;
    }

    function getFunctionsForContract(address gameContract)
        external
        view
        override
        returns (bytes4[] memory)
    {
        return functionsForContract[gameContract];
    }

    function gamingContracts()
        external
        view
        override
        returns (address[] memory)
    {
        return _gamingContracts;
    }

    function isFunctionsWhitelisted(address gameContract, bytes4 selector)
        public
        view
        override
        returns (bool)
    {
        return whitelistedFunctions[gameContract][selector];
    }

    function isClaimFunction(address gameContract, bytes4 selector)
        public
        view
        override
        returns (bool)
    {
        return oasisClaimFunctions[gameContract][selector];
    }

    function _whitelistFunction(
        address gameContract,
        bytes4 selector,
        bool claimFunction
    ) internal {
        whitelistedFunctions[gameContract][selector] = true;
        if (claimFunction) {
            oasisClaimFunctions[gameContract][selector] = true;
        }
        if (!_functionListedForContract(gameContract, selector)) {
            functionsForContract[gameContract].push(selector);
        }
        if (!_gamingContractListed(gameContract)) {
            _gamingContracts.push(gameContract);
        }
    }

    function _gamingContractListed(address gamingContract)
        internal
        view
        returns (bool)
    {
        uint256 length = _gamingContracts.length;
        for (uint32 i = 0; i < length; i++) {
            if (_gamingContracts[i] == gamingContract) {
                return true;
            }
        }
        return false;
    }

    function _functionListedForContract(address gamingContract, bytes4 selector)
        internal
        view
        returns (bool)
    {
        uint256 length = functionsForContract[gamingContract].length;
        for (uint32 i = 0; i < length; i++) {
            if (functionsForContract[gamingContract][i] == selector) {
                return true;
            }
        }
        return false;
    }
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