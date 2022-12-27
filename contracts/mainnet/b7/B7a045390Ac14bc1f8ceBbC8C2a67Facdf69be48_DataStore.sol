// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

import { Governable } from "../governance/Governable.sol";
import { Initializable } from "../utils/Initializable.sol";
import { IDataVault } from "./interfaces/IDataVault.sol";


contract DataStore is Initializable, Governable {
    struct Message {
        uint256 id;
        address vault;
        uint256 balance;
        uint256 tvl;
        uint256 chainId;
        uint256 timestamp;
        uint8 source;
        address[2] _gap_address;
        uint256[2] _gap_uint256;
        bool[2] _gap_bool;
    }
    address[] public vaults; // Vault present in the parent chains

    mapping(address => Message) public childMessageOffChain; // Latest message of child
    mapping(address => Message[]) public childMessagesOffChain; // All messages offchain

    mapping(address => Message) public childMessageOnChain; // Latest message of child
    mapping(address => Message[]) public childMessagesOnChain; // All messages onchain

    mapping(address => address[]) public children;

    address[] public offchainManagers;
    mapping(address => bool) public isOffchainManager;

    uint256 public timeEpsilonBps;
    uint256 public tvlEpsilonBps;
    uint256 public balanceEpsilonBps;

    modifier onlyGovernorOrOffchainManager() {
        require(
            msg.sender == governor() || isOffchainManager[msg.sender],
            "!Governor || Offchain Mgr"
        );
        _;
    }

    function setEpsilon(
        uint256 _timeEpsilonBps,
        uint256 _tvlEpsilonBps,
        uint256 _balanceEpsilonBps
    ) external onlyGovernor {
        timeEpsilonBps = _timeEpsilonBps;
        tvlEpsilonBps = _tvlEpsilonBps;
        balanceEpsilonBps = _balanceEpsilonBps;
    }

    function addVault(address _vault) external onlyGovernor{
        vaults.push(_vault);
    }
    function removeVault(address _vault) external onlyGovernor {
        for (uint256 i = 0; i < vaults.length; i++) {
            if (vaults[i] == _vault) {
                vaults[i] = vaults[vaults.length - 1];
                vaults.pop();
                break;
            }
        }
    }

    function addOffchainManager(address _offchainManager) external onlyGovernor {
        offchainManagers.push(_offchainManager);
        isOffchainManager[_offchainManager] = true;
    }

    function removeOffchainManager(address _offchainManager) external onlyGovernor {
        for (uint256 i = 0; i < offchainManagers.length; i++) {
            if (offchainManagers[i] == _offchainManager) {
                offchainManagers[i] = offchainManagers[offchainManagers.length - 1];
                offchainManagers.pop();
                break;
            }
        }
        isOffchainManager[_offchainManager] = false;
    }

    function addChild(address _vault, address _child) external onlyGovernor {
        require(_vaultExist(_vault), "!vault");
        children[_vault].push(_child);
    }
    function removeChild(address _vault, address _child) external onlyGovernor {
        for (uint256 i = 0; i < children[_vault].length; i++) {
            if (children[_vault][i] == _child) {
                children[_vault][i] = children[_vault][children[_vault].length - 1];
                children[_vault].pop();
                break;
            }
        }
    }

    function balance(address _vault) external view returns (uint256) {
        require(_vaultExist(_vault), "!vault");
        uint256 _bal = IDataVault(_vault).balance();
        for (uint256 i = 0; i < children[_vault].length; i++) {
            _checkEpsilon(children[_vault][i]);
            _bal += childMessageOffChain[children[_vault][i]].balance;
        }
        return _bal;
    }

    function tvl(address _vault) external view returns (uint256) {
        require(_vaultExist(_vault), "!vault");
        uint256 _tvl = IDataVault(_vault).tvl();
        for (uint256 i = 0; i < children[_vault].length; i++) {
            _checkEpsilon(children[_vault][i]);
            _tvl += childMessageOffChain[children[_vault][i]].tvl;
        }
        return _tvl;
    }
    function _checkDiffBps(uint256 _a, uint256 _b, uint256 _epsilonBps) internal pure returns (bool) {
        uint256 _diff = _a > _b ? _a - _b : _b - _a;
        uint256 _max = _a > _b ? _a : _b;
        return (_diff * 10000) / _max <= _epsilonBps;
    }
    function _checkEpsilon(address _childVault) internal view  {
        require( _checkDiffBps(childMessageOffChain[_childVault].timestamp, block.timestamp, timeEpsilonBps), "Time Epsilon");
        require( _checkDiffBps(childMessageOffChain[_childVault].tvl, childMessageOnChain[_childVault].tvl, tvlEpsilonBps), "TVL Epsilon");
        require( _checkDiffBps(childMessageOffChain[_childVault].balance, childMessageOnChain[_childVault].balance, balanceEpsilonBps), "Balance Epsilon");
    }
    function _vaultExist(address _vault) internal view returns (bool) {
        for (uint256 i = 0; i < vaults.length; i++) {
            if (vaults[i] == _vault) {
                return true;
            }
        }
        return false;
    }

    function writeOffchain(
        address _vault,
        address _childVault,
        uint256 _balance,
        uint256 _tvl,
        uint256 _chainId,
        uint256 _timestamp,
        uint8 _source
    ) external onlyGovernorOrOffchainManager {
        require(_vaultExist(_vault), "!vault");
        childMessageOffChain[_childVault] = Message(
            childMessageOffChain[_childVault].id + 1,
            _childVault,
            _balance,
            _tvl,
            _chainId,
            _timestamp,
            _source,
            [address(0), address(0)],
            [uint256(0), uint256(0)],
            [false, false]
        );
        childMessagesOffChain[_childVault].push(childMessageOffChain[_vault]);
    }

  

}

// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

interface IDataVault {
    function balance() external view returns (uint256);
    function tvl() external view returns (uint256);
    
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/**
 * @title CASH Governable Contract
 * @dev Copy of the openzeppelin Ownable.sol contract with nomenclature change
 *      from owner to governor and renounce methods removed. Does not use
 *      Context.sol like Ownable.sol does for simplification.
 * @author XStabl Protocol Inc
 */
contract Governable {
    // Storage position of the owner and pendingOwner of the contract
    // keccak256("CASH.governor");
    bytes32 private constant governorPosition =
        0x83f34c88ec39d54d1e423bd8a181ebc59ede5dcc9996c2df334668b4f89fdd73;

    // keccak256("CASH.pending.governor");
    bytes32 private constant pendingGovernorPosition =
        0x7eaf9a7750884803435dfabc67aa617a7d8fefb23d8d84b3c9722bd69e48c4bc;

    // keccak256("CASH.reentry.status");
    bytes32 private constant reentryStatusPosition =
        0x48a06827bfe8bfc0a59fe65d0fa78f553938265ed1f971326fc09947d19a593c;

    // See OpenZeppelin ReentrancyGuard implementation
    uint256 constant _NOT_ENTERED = 1;
    uint256 constant _ENTERED = 2;

    event PendingGovernorshipTransfer(
        address indexed previousGovernor,
        address indexed newGovernor
    );

    event GovernorshipTransferred(
        address indexed previousGovernor,
        address indexed newGovernor
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial Governor.
     */
    constructor() {
        _setGovernor(msg.sender);
        emit GovernorshipTransferred(address(0), _governor());
    }

    /**
     * @dev Returns the address of the current Governor.
     */
    function governor() public view returns (address) {
        return _governor();
    }

    /**
     * @dev Returns the address of the current Governor.
     */
    function _governor() internal view returns (address governorOut) {
        bytes32 position = governorPosition;
        assembly {
            governorOut := sload(position)
        }
    }

    /**
     * @dev Returns the address of the pending Governor.
     */
    function _pendingGovernor()
        internal
        view
        returns (address pendingGovernor)
    {
        bytes32 position = pendingGovernorPosition;
        assembly {
            pendingGovernor := sload(position)
        }
    }

    /**
     * @dev Throws if called by any account other than the Governor.
     */
    modifier onlyGovernor() {
        require(isGovernor(), "Caller is not the Governor");
        _;
    }

    /**
     * @dev Returns true if the caller is the current Governor.
     */
    function isGovernor() public view returns (bool) {
        return msg.sender == _governor();
    }

    function _setGovernor(address newGovernor) internal {
        bytes32 position = governorPosition;
        assembly {
            sstore(position, newGovernor)
        }
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        bytes32 position = reentryStatusPosition;
        uint256 _reentry_status;
        assembly {
            _reentry_status := sload(position)
        }

        // On the first call to nonReentrant, _notEntered will be true
        require(_reentry_status != _ENTERED, "Reentrant call");

        // Any calls to nonReentrant after this point will fail
        assembly {
            sstore(position, _ENTERED)
        }

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        assembly {
            sstore(position, _NOT_ENTERED)
        }
    }

    function _setPendingGovernor(address newGovernor) internal {
        bytes32 position = pendingGovernorPosition;
        assembly {
            sstore(position, newGovernor)
        }
    }

    /**
     * @dev Transfers Governance of the contract to a new account (`newGovernor`).
     * Can only be called by the current Governor. Must be claimed for this to complete
     * @param _newGovernor Address of the new Governor
     */
    function transferGovernance(address _newGovernor) external onlyGovernor {
        _setPendingGovernor(_newGovernor);
        emit PendingGovernorshipTransfer(_governor(), _newGovernor);
    }

    /**
     * @dev Claim Governance of the contract to a new account (`newGovernor`).
     * Can only be called by the new Governor.
     */
    function claimGovernance() external {
        require(
            msg.sender == _pendingGovernor(),
            "Only the pending Governor can complete the claim"
        );
        _changeGovernor(msg.sender);
    }

    /**
     * @dev Change Governance of the contract to a new account (`newGovernor`).
     * @param _newGovernor Address of the new Governor
     */
    function _changeGovernor(address _newGovernor) internal {
        require(_newGovernor != address(0), "New Governor is address(0)");
        emit GovernorshipTransferred(_governor(), _newGovernor);
        _setGovernor(_newGovernor);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(
            initializing || !initialized,
            "Initializable: contract is already initialized"
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    uint256[50] private ______gap;
}