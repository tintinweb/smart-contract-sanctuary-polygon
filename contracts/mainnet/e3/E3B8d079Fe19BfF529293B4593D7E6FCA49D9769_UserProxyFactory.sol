// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "./interfaces/IUserProxy.sol";
import "./interfaces/IUserProxyInterface.sol";
import "./UserProxy.sol";
import "./ProxyImplementation.sol";

/**
 * @title UserProxyFactory
 * @author Penrose
 * @notice Factory responsible for generating new user proxies
 * @dev Keeps track of user proxy addresses and mappings
 */
contract UserProxyFactory is ProxyImplementation {
    /*******************************************************
     *                     Configuration
     *******************************************************/

    // Template
    address public userProxyTemplateAddress;

    // UserProxy mapping variables
    mapping(address => address) public userProxyByAccount;
    mapping(uint256 => address) public userProxyByIndex;
    mapping(address => bool) public isUserProxy;
    uint256 public userProxiesLength;

    // penLens
    address public penLensAddress;

    // UserProxyInterface
    address public userProxyInterfaceAddress;

    // Implementations
    address[] public implementationsAddresses;

    // Constructor
    /**
     * @dev Since this is meant to be a proxy's implementation, DO NOT implement logic in this constructor, use initializeProxyStorage() instead
     */
    constructor(
        address _userProxyTemplateAddress,
        address[] memory _implementationsAddresses
    ) {
        initializeProxyStorage(
            _userProxyTemplateAddress,
            _implementationsAddresses
        );
    }

    /**
     * @notice Initializes proxy contract storage with what's supposed to be done in the constructor
     * @dev Don't forget to include logic from parent contracts' constructors as well
     */
    function initializeProxyStorage(
        address _userProxyTemplateAddress,
        address[] memory _implementationsAddresses
    ) public checkProxyInitialized {
        userProxyTemplateAddress = _userProxyTemplateAddress;
        implementationsAddresses = _implementationsAddresses;
    }

    /**
     * @notice Initialize
     * @param _userProxyInterfaceAddress Address of user proxy interface
     * @param _salt to avoid hash collision with proxy's initialize()
     */
    function initialize(address _userProxyInterfaceAddress, bool _salt)
        external
    {
        require(userProxyInterfaceAddress == address(0), "Already initialized");
        userProxyInterfaceAddress = _userProxyInterfaceAddress;
        penLensAddress = IUserProxyInterface(userProxyInterfaceAddress)
            .penLensAddress();
    }

    /**
     * @notice Create and or get a user's proxy
     * @param accountAddress Address for which to build or fetch the proxy
     */
    function createAndGetUserProxy(address accountAddress)
        public
        returns (address)
    {
        // Only create proxies if they don't exist already
        bool userProxyExists = userProxyByAccount[accountAddress] != address(0);
        if (!userProxyExists) {
            require(
                msg.sender == userProxyInterfaceAddress,
                "Only UserProxyInterface can register new user proxies"
            );
            address userProxyAddress = address(
                new UserProxy(userProxyTemplateAddress, accountAddress)
            );

            // Set initial implementations
            IUserProxy(userProxyAddress).initialize(
                accountAddress,
                userProxyInterfaceAddress,
                penLensAddress,
                implementationsAddresses
            );

            // Update proxies mappings
            userProxyByAccount[accountAddress] = userProxyAddress;
            userProxyByIndex[userProxiesLength] = userProxyAddress;
            userProxiesLength++;
            isUserProxy[userProxyAddress] = true;
        }
        return userProxyByAccount[accountAddress];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IUserProxy {
    struct PositionStakingPool {
        address stakingPoolAddress;
        address penPoolAddress;
        address dystPoolAddress;
        uint256 balanceOf;
        RewardToken[] rewardTokens;
    }

    function initialize(
        address,
        address,
        address,
        address[] memory
    ) external;

    struct RewardToken {
        address rewardTokenAddress;
        uint256 rewardRate;
        uint256 rewardPerToken;
        uint256 getRewardForDuration;
        uint256 earned;
    }

    struct Vote {
        address poolAddress;
        int256 weight;
    }

    function convertNftToPenDyst(uint256) external;

    function convertDystToPenDyst(uint256) external;

    function depositLpAndStake(address, uint256) external;

    function depositLp(address, uint256) external;

    function stakingAddresses() external view returns (address[] memory);

    function initialize(address, address) external;

    function stakingPoolsLength() external view returns (uint256);

    function unstakeLpAndWithdraw(
        address,
        uint256,
        bool
    ) external;

    function unstakeLpAndWithdraw(address, uint256) external;

    function unstakeLpWithdrawAndClaim(address) external;

    function unstakeLpWithdrawAndClaim(address, uint256) external;

    function withdrawLp(address, uint256) external;

    function stakePenLp(address, uint256) external;

    function unstakePenLp(address, uint256) external;

    function ownerAddress() external view returns (address);

    function stakingPoolsPositions()
        external
        view
        returns (PositionStakingPool[] memory);

    function stakePenDyst(uint256) external;

    function unstakePenDyst(uint256) external;

    function unstakePenDyst(address, uint256) external;

    function convertDystToPenDystAndStake(uint256) external;

    function convertNftToPenDystAndStake(uint256) external;

    function claimPenDystStakingRewards() external;

    function claimPartnerStakingRewards() external;

    function claimStakingRewards(address) external;

    function claimStakingRewards(address[] memory) external;

    function claimStakingRewards() external;

    function claimVlPenRewards() external;

    function depositPen(uint256, uint256) external;

    function withdrawPen(bool, uint256) external;

    function voteLockPen(uint256, uint256) external;

    function withdrawVoteLockedPen(uint256, bool) external;

    function relockVoteLockedPen(uint256) external;

    function removeVote(address) external;

    function registerStake(address) external;

    function registerUnstake(address) external;

    function resetVotes() external;

    function setVoteDelegate(address) external;

    function clearVoteDelegate() external;

    function vote(address, int256) external;

    function vote(Vote[] memory) external;

    function votesByAccount(address) external view returns (Vote[] memory);

    function migratePenDystToPartner() external;

    function stakePenDystInPenV1(uint256) external;

    function unstakePenDystInPenV1(uint256) external;

    function redeemPenV1(uint256) external;

    function redeemAndStakePenV1(uint256) external;

    function whitelist(address) external;

    function implementationsAddresses()
        external
        view
        returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IUserProxyInterface {
    function penLensAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/**
 * @title UserProxy
 * @author Penrose
 * @notice Minimal upgradeable EIP-1967 proxy
 * @dev Each user gets their own user proxy contract
 * @dev Each user has complete control and custody of their UserProxy (similar to Maker's DSProxy)
 * @dev Users can upgrade their proxies if desired for additional functionality in the future
 */
contract UserProxy {
    bytes32 constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc; // keccak256('eip1967.proxy.implementation')
    bytes32 constant OWNER_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103; // keccak256('eip1967.proxy.admin')

    constructor(address _implementationAddress, address _ownerAddress) {
        assembly {
            sstore(IMPLEMENTATION_SLOT, _implementationAddress)
            sstore(OWNER_SLOT, _ownerAddress)
        }
    }

    function implementationAddress()
        external
        view
        returns (address _implementationAddress)
    {
        assembly {
            _implementationAddress := sload(IMPLEMENTATION_SLOT)
        }
    }

    function ownerAddress() public view returns (address _ownerAddress) {
        assembly {
            _ownerAddress := sload(OWNER_SLOT)
        }
    }

    function updateImplementationAddress(address _implementationAddress)
        external
    {
        require(
            msg.sender == ownerAddress(),
            "Only owners can update implementation"
        );
        assembly {
            sstore(IMPLEMENTATION_SLOT, _implementationAddress)
        }
    }

    function updateOwnerAddress(address _ownerAddress) external {
        require(msg.sender == ownerAddress(), "Only owners can update owners");
        assembly {
            sstore(OWNER_SLOT, _ownerAddress)
        }
    }

    fallback() external {
        assembly {
            let contractLogic := sload(IMPLEMENTATION_SLOT)
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                gas(),
                contractLogic,
                0x0,
                calldatasize(),
                0,
                0
            )
            let returnDataSize := returndatasize()
            returndatacopy(0, 0, returnDataSize)
            switch success
            case 0 {
                revert(0, returnDataSize)
            }
            default {
                return(0, returnDataSize)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11||0.6.12;

/**
 * @title Implementation meant to be used with a proxy
 * @author Penrose
 */
contract ProxyImplementation {
    bool public proxyStorageInitialized;

    /**
     * @notice Nothing in constructor, since it only affects the logic address, not the storage address
     * @dev public visibility so it compiles for 0.6.12
     */
    constructor() public {}

    /**
     * @notice Only allow proxy's storage to be initialized once
     */
    modifier checkProxyInitialized() {
        require(
            !proxyStorageInitialized,
            "Can only initialize proxy storage once"
        );
        proxyStorageInitialized = true;
        _;
    }
}