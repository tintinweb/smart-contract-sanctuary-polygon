// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IArbitraryValueOracle Interface
/// @author Enzyme Council <[email protected]>
interface IArbitraryValueOracle {
    function getLastUpdated() external view returns (uint256 lastUpdated_);

    function getValue() external view returns (int256 value_);

    function getValueWithTimestamp() external view returns (int256 value_, uint256 lastUpdated_);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./ManualValueOracleLib.sol";
import "./ManualValueOracleProxy.sol";

/// @title ManualValueOracleFactory Contract
/// @author Enzyme Council <[email protected]>
/// @notice A contract factory for ManualValueOracleProxy instances
contract ManualValueOracleFactory {
    event ProxyDeployed(address indexed caller, address proxy);

    address private immutable LIB;

    constructor() public {
        LIB = address(new ManualValueOracleLib());
    }

    /// @notice Deploys a ManualValueOracleProxy instance
    /// @param _owner The owner of the oracle
    /// @param _updater The updater of the oracle
    /// @param _description A short encoded description for the oracle
    /// @return proxy_ The deployed ManualValueOracleProxy address
    function deploy(
        address _owner,
        address _updater,
        bytes32 _description
    ) external returns (address proxy_) {
        bytes memory constructData = abi.encodeWithSelector(
            ManualValueOracleLib.init.selector,
            _owner,
            _updater,
            _description
        );

        proxy_ = address(new ManualValueOracleProxy(constructData, LIB));

        emit ProxyDeployed(msg.sender, proxy_);

        return proxy_;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../release/utils/NominatedOwnerMixin.sol";
import "../IArbitraryValueOracle.sol";

/// @title ManualValueOracleLib Contract
/// @author Enzyme Council <[email protected]>
/// @notice Library contract for ManualValueOracleProxy instances
contract ManualValueOracleLib is IArbitraryValueOracle, NominatedOwnerMixin {
    event Initialized(bytes32 description);

    event UpdaterSet(address updater);

    event ValueUpdated(int256 value);

    address private updater;
    // Var packed
    int192 private value;
    uint64 private lastUpdated;

    /// @notice Initializes the proxy
    /// @param _owner The owner of the oracle
    /// @param _updater The updater of the oracle value
    /// @param _description A short encoded description for the oracle
    function init(
        address _owner,
        address _updater,
        bytes32 _description
    ) external {
        require(getOwner() == address(0), "init: Already initialized");
        require(_owner != address(0), "init: Empty _owner");

        __setOwner(_owner);

        emit Initialized(_description);

        if (_updater != address(0)) {
            __setUpdater(_updater);
        }
    }

    /// @notice Sets the updater
    /// @param _nextUpdater The next updater
    function setUpdater(address _nextUpdater) external onlyOwner {
        __setUpdater(_nextUpdater);
    }

    /// @notice Updates the oracle value
    /// @param _nextValue The next value
    function updateValue(int192 _nextValue) external {
        require(msg.sender == getUpdater(), "updateValue: Unauthorized");

        value = _nextValue;
        lastUpdated = uint64(block.timestamp);

        emit ValueUpdated(_nextValue);
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to set the updater
    function __setUpdater(address _nextUpdater) private {
        updater = _nextUpdater;

        emit UpdaterSet(_nextUpdater);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    // EXTERNAL FUNCTIONS

    /// @notice Gets the oracle value with last updated timestamp
    /// @return value_ The value
    /// @return lastUpdated_ The timestamp of the last update
    function getValueWithTimestamp()
        external
        view
        override
        returns (int256 value_, uint256 lastUpdated_)
    {
        return (getValue(), getLastUpdated());
    }

    // PUBLIC FUNCTIONS

    /// @notice Gets the last updated timestamp
    /// @return lastUpdated_ The timestamp of the last update
    function getLastUpdated() public view override returns (uint256 lastUpdated_) {
        return lastUpdated;
    }

    /// @notice Gets the updater of the oracle value
    /// @param updater_ The updater
    function getUpdater() public view returns (address updater_) {
        return updater;
    }

    /// @notice Gets the oracle value only
    /// @return value_ The value
    function getValue() public view override returns (int256 value_) {
        return value;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../release/utils/NonUpgradableProxy.sol";

/// @title ManualValueOracleProxy Contract
/// @author Enzyme Council <[email protected]>
/// @notice Proxy contract for all ManualValueOracle instances
contract ManualValueOracleProxy is NonUpgradableProxy {
    constructor(bytes memory _constructData, address _lib)
        public
        NonUpgradableProxy(_constructData, _lib)
    {}
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title NominatedOwnerMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice Mixin contract for a nominated contract ownership transfer pattern
/// @dev Initial owner must be set in inheriting contract via __setOwner()
abstract contract NominatedOwnerMixin {
    event NominatedOwnerSet(address indexed nominatedOwner);

    event OwnerSet(address owner);

    address private nominatedOwner;
    address private owner;

    modifier onlyOwner() {
        require(msg.sender == getOwner(), "onlyOwner: Unauthorized");
        _;
    }

    /// @notice Claim ownership of the contract
    /// @dev Note that this claims process means that `owner` can never be reset to address(0)
    function claimOwnership() external {
        address nextOwner = getNominatedOwner();
        require(msg.sender == nextOwner, "claimOwnership: Unauthorized");

        __setOwner(nextOwner);

        delete nominatedOwner;
    }

    /// @notice Nominate a new contract owner
    /// @param _nextNominatedOwner The account to nominate
    function setNominatedOwner(address _nextNominatedOwner) external onlyOwner {
        __setNominatedOwner(_nextNominatedOwner);
    }

    // INTERNAL FUNCTIONS

    /// @dev Helper to set the nominated owner
    function __setNominatedOwner(address _nextNominatedOwner) internal {
        nominatedOwner = _nextNominatedOwner;

        emit NominatedOwnerSet(_nextNominatedOwner);
    }

    /// @dev Helper to set the next owner.
    /// Should only be invoked once by inheriting contract to set initial ownership.
    /// Does not protect against address(0) on unclaimable address.
    function __setOwner(address _nextOwner) internal {
        owner = _nextOwner;

        emit OwnerSet(_nextOwner);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the account that is nominated to be the next contract owner
    /// @return nominatedOwner_ The next contract owner nominee
    function getNominatedOwner() public view returns (address nominatedOwner_) {
        return nominatedOwner;
    }

    /// @notice Gets the owner of this contract
    /// @return owner_ The contract owner
    function getOwner() public view returns (address owner_) {
        return owner;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title NonUpgradableProxy Contract
/// @author Enzyme Council <[email protected]>
/// @notice A proxy contract for use with non-upgradable libs
/// @dev The recommended constructor-fallback pattern of a proxy in EIP-1822, updated for solc 0.6.12,
/// and using an immutable lib value to save on gas (since not upgradable).
/// The EIP-1967 storage slot for the lib is still assigned,
/// for ease of referring to UIs that understand the pattern, i.e., Etherscan.
abstract contract NonUpgradableProxy {
    address private immutable CONTRACT_LOGIC;

    constructor(bytes memory _constructData, address _contractLogic) public {
        CONTRACT_LOGIC = _contractLogic;

        assembly {
            // EIP-1967 slot: `bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)`
            sstore(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc,
                _contractLogic
            )
        }
        (bool success, bytes memory returnData) = _contractLogic.delegatecall(_constructData);
        require(success, string(returnData));
    }

    // solhint-disable-next-line no-complex-fallback
    fallback() external payable {
        address contractLogic = CONTRACT_LOGIC;

        assembly {
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                sub(gas(), 10000),
                contractLogic,
                0x0,
                calldatasize(),
                0,
                0
            )
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
            case 0 {
                revert(0, retSz)
            }
            default {
                return(0, retSz)
            }
        }
    }
}