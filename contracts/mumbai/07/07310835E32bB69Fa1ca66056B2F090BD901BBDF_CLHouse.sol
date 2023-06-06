// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "Initializable.sol";
import "CLStorage.sol";
import "ICLHouse.sol";
import "IUnlock.sol";


/// @title Contract to implement and call the fuctions of CLHouses
/// @author Leonardo Urrego
contract CLHouse is CLStorage, Initializable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Constructor of the new CLH
    /// @dev This function can be called once after proxy creation
    /// @param _ownerWallet The address of the owner
    /// @param _ownerName The Nickname of the owner
    /// @param _houseName Name given by the owner
    /// @param _housePrivate If is set to 1, the CLH is set to private
    /// @param _houseOpen If is set to 1, the CLH is set to Open
    /// @param _govRuleMaxUsers Max users in the house
    /// @param _CLC Array for CL Contracts and others see `enum eCLC`
    function Init(
        address _ownerWallet, 
        string memory _ownerName,
        string memory _houseName,
        bool _housePrivate,
        bool _houseOpen,
        uint256 _govRuleMaxUsers,
        address[7] memory _CLC
    )
        external
        reinitializer( __UPGRADEABLE_CLH_VERSION__ )
    {
        /// @custom:oz-upgrades-unsafe-allow delegatecall
        (bool successDGTCLL, ) = _CLC[ uint256( eCLC.CLLConstructorCLH ) ].delegatecall(
            abi.encodeWithSignature(
                "__CLHConstructor(address,string,string,bool,bool,uint256,address[7])",
                _ownerWallet, 
                _ownerName,
                _houseName,
                _housePrivate,
                _houseOpen,
                _govRuleMaxUsers,
                _CLC
            )
        );

        if( !successDGTCLL ) {
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }


    /// @notice Used to vote a proposal
    /// @dev After vote the proposal automatically try to be executed
    /// @param _propId ID of the proposal, based on `arrProposals`
    /// @param _support True for accept, false to reject
    /// @param _justification About your vote
    /// @param _signature EIP712 Signature
    function VoteProposal(
        uint256 _propId,
        bool _support,
        string memory _justification,
        bytes memory _signature
    )
        external
    {
        /// @custom:oz-upgrades-unsafe-allow delegatecall
        (bool successDGTCLL, ) = pxyCLF.CLLGovernance().delegatecall(
            abi.encodeWithSignature( 
                "VoteProposal(uint256,bool,string,bytes)",
                _propId,
                _support,
                _justification,
                _signature
            )
        );

        if( !successDGTCLL ) {
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }

    /// @notice Generate a new proposal to invite a new user
    /// @dev the execution of this proposal only create an invitation 
    /// @param _walletAddr Wallet of the user
    /// @param _nickname Can be the nickname or other reference to the User
    /// @param _description A text for the proposal
    /// @param _isManager True if is for a manager
    /// @param _delayTime Time of live od the proposal in seconds
    /// @param _signature EIP712 Signature
    /// @return propId ID of the new proposal, based on `arrProposals`
    function PropInvitUser(
        address _walletAddr,
        string memory _nickname,
        string memory _description,
        bool _isManager,
        uint256 _delayTime,
        bytes memory _signature
    )
        external
        returns( uint256 propId )
    {
        /// @custom:oz-upgrades-unsafe-allow delegatecall
        (bool successDGTCLL, ) = pxyCLF.CLLGovernance().delegatecall(
            abi.encodeWithSignature( 
                "PropInvitUser(address,string,string,bool,uint256,bytes)",
                _walletAddr,
                _nickname,
                _description,
                _isManager,
                _delayTime,
                _signature
            )
        );

        assembly {
            let ptr := mload(0x40)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            if iszero( successDGTCLL ) {
                revert(ptr, size)
            }
            propId := mload(ptr)
        }
    }

    /// @notice Generate a new proposal for remove a user
    /// @dev The user to remove can be a managaer
    /// @param _walletAddr user Address to be removed
    /// @param _description About the proposal
    /// @param _delayTime Time of live od the proposal in seconds
    /// @param _signature EIP712 Signature
    /// @return propId ID of the new proposal, based on `arrProposals`
    function PropRemoveUser(
        address _walletAddr,
        string memory _description,
        uint256 _delayTime,
        bytes memory _signature
    )
        external
        returns( uint256 propId )
    {
        /// @custom:oz-upgrades-unsafe-allow delegatecall
        (bool successDGTCLL, ) = pxyCLF.CLLGovernance().delegatecall(
            abi.encodeWithSignature( 
                "PropRemoveUser(address,string,uint256,bytes)",
                _walletAddr,
                _description,
                _delayTime,
                _signature
            )
        );

        assembly {
            let ptr := mload(0x40)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            if iszero( successDGTCLL ) {
                revert(ptr, size)
            }
            propId := mload(ptr)
        }
    }

    /// @notice Generate a proposal from a user that want to join to the CLH
    /// @dev Only avaiable in non private CLH
    /// @param _name Nickname or other user identification
    /// @param _description About the request
    /// @param _signerWallet Address of signer to check OffChain signature
    /// @param _signature EIP712 Signature
    /// @return propId ID of the new proposal, based on `arrProposals`
    function PropRequestToJoin(
        string memory _name,
        string memory _description,
        address _signerWallet,
        bytes memory _signature
    )
        external
        returns( uint256 )
    {
        /// @custom:oz-upgrades-unsafe-allow delegatecall
        (bool successDGTCLL, ) = pxyCLF.CLLGovernance().delegatecall(
            abi.encodeWithSignature( 
                "PropRequestToJoin(string,string,address,bytes)",
                _name,
                _description,
                _signerWallet,
                _signature
            )
        );

        assembly {
            let ptr := mload(0x40)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            if iszero( successDGTCLL ) {
                revert(ptr, size)
            }
            return(ptr, size)
        }
    }

    /// @notice For an user that have an invitation pending
    /// @param _acceptance True for accept the invitation
    /// @param _nickname A nickname for the user
    /// @param _signature EIP712 Signature
    function AcceptRejectInvitation(
        bool _acceptance,
        string memory _nickname,
        bytes memory _signature
    )
        external
    {
        /// @custom:oz-upgrades-unsafe-allow delegatecall
        (bool successDGTCLL, ) = pxyCLF.CLLUserManagement().delegatecall(
            abi.encodeWithSignature( 
                "AcceptRejectInvitation(bool,string,bytes)",
                _acceptance,
                _nickname,
                _signature
            )
        );

        if( !successDGTCLL ) {
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }


    /// @notice Vote for multiple proposal
    /// @param _propIds Array with ID of the proposal to votes
    /// @param _support is the Vote (True or False) for all proposals
    /// @param _justification Description of the vote
    /// @param _signature EIP712 Signature
    function bulkVote(
        uint256[] memory _propIds,
        bool _support,
        string memory _justification,
        bytes memory _signature
    )
        external
    {
        /// @custom:oz-upgrades-unsafe-allow delegatecall
        (bool successDGTCLL, ) = pxyCLF.CLLGovernance().delegatecall(
            abi.encodeWithSignature( 
                "bulkVote(uint256[],bool,string,bytes)",
                _propIds,
                _support,
                _justification,
                _signature
            )
        );

        assembly {
            let ptr := mload(0x40)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            if iszero( successDGTCLL ) {
                revert(ptr, size)
            }
            // return(ptr, size)
        }
    }

    /// @notice Length of arrUsers array
    function GetArrUsersLength() external view returns( uint256 ){
        return arrUsers.length;
    }

    /// @notice Length of arrProposals array
    function GetArrProposalsLength() external view returns( uint256 ){
        return arrProposals.length;
    }

    /// @notice The list of all Proposals
    /// @return arrProposals the array with all proposals
    function GetProposalList() external view returns( strProposal[] memory ) {
        return arrProposals;
    }

    /// @notice Get complete array of arrDataPropUser
    /// @return arrDataPropUser the array with all data
    function GetArrDataPropUser() external view returns( strDataUser[] memory ) {
        return arrDataPropUser;
    }

    /// @notice Get a version of CLH
    /// @return version
    function GetCLHouseVersion() external pure returns ( string memory ) {
        return __CLHOUSE_VERSION__;
    }

    /// @notice Set a new NFT Collection for Invitations
    /// @param _whiteListNFT contract address of NFT
    /// @param _signature EIP712 Signature
    function UpdateCLHWLNFT(
        address _whiteListNFT,
        bytes memory _signature
    ) external {
        address realSender = msg.sender;

        if( _signature.length == 65 ) {
            realSender = pxyApiCLH.SignerOCUpCLHWLNFT(
                _whiteListNFT,
                address(this),
                _signature
            );

            CheckECDSA( realSender );
        }

        CheckIsManager( realSender );

        whiteListNFT = _whiteListNFT;

        emit evtUpCLHWLNFT( _whiteListNFT );
    }


    /// @notice Create a new Lock proxy contract from Lock Factory
    /// @param _expirationDuration Expiration for lcok in seconds
    /// @param _keyPrice Price for each lock in wei
    /// @param _maxNumberOfKeys How many locks
    /// @param _lockName Lock Name
    /// @param _signature EIP712 Signature
    /// @return Contract address of the new lock
    function CreateLock(
        uint256 _expirationDuration,
        uint256 _keyPrice,
        uint256 _maxNumberOfKeys,
        string memory _lockName,
        bytes memory _signature
    )
        external
        returns (
            address
        )
    {
        address realSender = msg.sender;

        if( _signature.length == 65 ) {
            realSender = pxyApiCLH.SignerOCNewLock(
                _expirationDuration,
                _keyPrice,
                _maxNumberOfKeys,
                _lockName,
                address(this),
                _signature
            );

            CheckECDSA( realSender );
        }

        CheckIsManager( realSender );

        bytes memory params = abi.encodeWithSignature(
            'initialize(address,uint256,address,uint256,uint256,string)',
            realSender,
            _expirationDuration,
            address(0),
            _keyPrice,
            _maxNumberOfKeys,
            _lockName
        );

        // https://docs.unlock-protocol.com/core-protocol/unlock/networks/
        address aULF;
        
        if( 5 == block.chainid ) // Goerli
            aULF = 0x627118a4fB747016911e5cDA82e2E77C531e8206;
        else if( 137 == block.chainid ) // Polygon
            aULF = 0xE8E5cd156f89F7bdB267EabD5C43Af3d5AF2A78f;
        else if( 80001 == block.chainid ) // Mumbai
            aULF = 0x1FF7e338d5E582138C46044dc238543Ce555C963;
        else if( 1 == block.chainid ) // Mainnet
            aULF = 0x3d5409CcE1d45233dE1D4eBDEe74b8E004abDD13;
        else
            revert("CreateLock: unsupported chain");

        IUnlock iULF = IUnlock( aULF );

        whiteListNFT = iULF.createUpgradeableLockAtVersion( params, 11 );

        return whiteListNFT;
    }


    /// @notice Retrieve some of the internal variables of the house
    function HouseProperties() 
        external
        view
        returns(
            string memory clhName,
            bool[2] memory booleanVar,
            uint256[5] memory uint256Var,
            address[6] memory addressVar,
            bytes32 govModelVar
        )
    {
        clhName = houseName;
        booleanVar[0] = housePrivate;
        booleanVar[1] = houseOpen;

        uint256Var[0] = numUsers;
        uint256Var[1] = numManagers;
        uint256Var[2] = govRuleApprovPercentage;
        uint256Var[3] = govRuleMaxUsers;
        uint256Var[4] = govRuleMaxManagers;

        addressVar[0] = address( pxyCLF );
        addressVar[1] = address( pxyApiCLH );
        addressVar[2] = address( pxyNFTManager );
        addressVar[3] = address( pxyNFTMember );
        addressVar[4] = address( pxyNFTInvitation );
        addressVar[5] = whiteListNFT;

        govModelVar = HOUSE_GOVERNANCE_MODEL;
    }


    /// @notice Change the name of the House
    /// @param _houseName New House Name
    /// @param _signature EIP712 Signature
    function UpdateCLHName(
        string memory _houseName,
        bytes memory _signature
    ) external {
        address realSender = msg.sender;

        if( _signature.length == 65 ) {
            realSender = pxyApiCLH.SignerOCUpCLHName(
                _houseName,
                address(this),
                _signature
            );

            CheckECDSA( realSender );
        }

        CheckIsManager( realSender );
        houseName = _houseName;
        emit evtUpCLHName( _houseName );
    }


    /// @notice Change the number of MaxUsers House
    /// @param _govRuleMaxUsers New value of MaxUsers
    /// @param _signature EIP712 Signature
    function UpdateCLHMaxUsers(
        uint256 _govRuleMaxUsers,
        bytes memory _signature
    ) external {
        address realSender = msg.sender;

        if( _signature.length == 65 ) {
            realSender = pxyApiCLH.SignerOCUpCLHMaxUsers(
                _govRuleMaxUsers,
                address(this),
                _signature
            );

            CheckECDSA( realSender );
        }

        CheckIsManager( realSender );
        require( _govRuleMaxUsers >= numUsers, "Invalid MaxUsers value" );
        uint256 oldValue = govRuleMaxUsers;
        govRuleMaxUsers = _govRuleMaxUsers;
        emit evtUpCLHGovRules( govRulesEvent.changeMaxUsers, oldValue, _govRuleMaxUsers );
    }

    /// @notice Change the flag of housePrivate
    /// @param _housePrivate New value of housePrivate
    /// @param _signature EIP712 Signature
    function UpdateCLHPrivacy(
        bool _housePrivate,
        bytes memory _signature
    ) external {
        address realSender = msg.sender;

        if( _signature.length == 65 ) {
            realSender = pxyApiCLH.SignerOCUpCLHPrivacy(
                _housePrivate,
                address(this),
                _signature
            );

            CheckECDSA( realSender );
        }

        CheckIsManager( realSender );

        // if( true == _housePrivate )
        //     require( false == houseOpen, "House is Open" );

        bool oldValue = housePrivate;
        housePrivate = _housePrivate;
        emit evtUpCLHFlag( flagEvent.changeHousePrivate, oldValue, _housePrivate );

        if( true == housePrivate && true == houseOpen ){
            houseOpen = false;
            emit evtUpCLHFlag( flagEvent.changeHouseOpen, true, false );
        }
    }


    /// @notice Change the flag of houseOpen
    /// @param _houseOpen New value of houseOpen
    /// @param _signature EIP712 Signature
    function UpdateCLHOpen(
        bool _houseOpen,
        bytes memory _signature
    ) external {
        address realSender = msg.sender;

        if( _signature.length == 65 ) {
            realSender = pxyApiCLH.SignerOCUpCLHOpen(
                _houseOpen,
                address(this),
                _signature
            );

            CheckECDSA( realSender );
        }

        CheckIsManager( realSender );

        if( true == _houseOpen )
            require( false == housePrivate, "House is Private" );

        bool oldValue = houseOpen;
        houseOpen = _houseOpen;
        emit evtUpCLHFlag( flagEvent.changeHouseOpen, oldValue, _houseOpen );
    }


    /// @notice Change the User Nickname
    /// @param _nickname New nickname of user
    /// @param _signature EIP712 Signature
    function UpdateUsrNickname(
        string memory _nickname,
        bytes memory _signature
    ) external {
        address realSender = msg.sender;

        if( _signature.length == 65 ) {
            realSender = pxyApiCLH.SignerOCUpUsrNickname(
                _nickname,
                address(this),
                _signature
            );

            CheckECDSA( realSender );
        }

        CheckIsUser( realSender );

        mapUsers[ realSender ].nickname = _nickname;
        emit evtUser(
            userEvent.changeNickname,
            realSender,
            _nickname
        );
    }

    
    /// @notice Change the User Nickname
    /// @param _walletAddr User Wallet to Add
    /// @param _nickname New nickname of user
    /// @param _isManager True if is for a manager
    /// @param _signature EIP712 Signature
    function UserAggregate(
        address _walletAddr,
        string memory _nickname,
        bool _isManager,
        bytes memory _signature
    ) external {
        address realSender = msg.sender;

        if( _signature.length == 65 ) {
            realSender = pxyApiCLH.SignerOCUserAggregate(
                _walletAddr,
                _nickname,
                _isManager,
                address(this),
                _signature
            );

            CheckECDSA( realSender );
        }

        CheckIsManager( realSender );

        (bool successDGTCLL, ) = pxyCLF.CLLUserManagement().delegatecall(
            abi.encodeWithSignature(
                "AddUser(address,string,bool)",
                _walletAddr,
                _nickname,
                _isManager
            )
        );

        if( !successDGTCLL ) {
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCall(target, data, "Address: low-level call failed");
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "CLHNFT.sol";
import "ICLFactory.sol";
import "CLHouseApi.sol";


/// @title Contract to store data of CLHouse (var stack)
/// @author Leonardo Urrego
/// @notice This contract is part of CLH
abstract contract CLStorage {

	/**
     * ### CLH Variables ###
     */

    bool internal housePrivate;
    bool internal houseOpen;
    bool[30] private __gapBool;

    uint256 public numUsers;
    uint256 internal numManagers;
    uint256 internal govRuleApprovPercentage;
    uint256 internal govRuleMaxUsers;
    uint256 internal govRuleMaxManagers;
    uint256[27] private __gapUint256;

    address internal whiteListNFT;
    address[31] private __gapAddress;

    string internal houseName;
    uint256[31] private __gapString;

    bytes32 internal HOUSE_GOVERNANCE_MODEL;
    bytes32[31] private __gapBytes32;

    address[] public arrUsers;
    strProposal[] public arrProposals;
    strDataUser[] public arrDataPropUser;
    strDataGovRules[] public arrDataPropGovRules;
    uint256[28] private __gapArrays;

    mapping( address => strUser ) public mapUsers;
    mapping( address => uint256 ) public mapReq2Join; // wallet => propId
    mapping( uint256 => mapping( address => strVote ) ) public mapVotes; // mapVotes[propId][wallet].strVote
    uint256[29] private __gapMappings;

    ICLFactory internal pxyCLF;
    CLHouseApi internal pxyApiCLH;
    CLHNFT internal pxyNFTManager;
    CLHNFT internal pxyNFTMember;
    CLHNFT internal pxyNFTInvitation;

    /**
     * ### Contract events ###
     */

    event evtUser( userEvent eventUser, address walletAddr, string name );
    event evtVoted( uint256 propId, bool position, address voter, string justification );
    event evtProposal( proposalEvent eventProposal, uint256 propId, proposalType typeProposal, string description, address realSender );
    event evtUpCLHGovRules( govRulesEvent typeGovRule, uint256 oldValue, uint256 newValue );
    event evtUpCLHName( string houseName );
    event evtUpCLHWLNFT( address whiteListNFT );
    event evtUpCLHFlag( flagEvent typeFlag, bool oldValue, bool newValue );


    function CheckPropExists( uint256 _propId ) internal view {
        require( _propId < arrProposals.length , "Proposal does not exist" );
    }

    function CheckPropNotExecuted( uint256 _propId ) internal view {
        require( false == arrProposals[ _propId ].executed , "Proposal already executed" );
    }

    function CheckPropNotRejected( uint256 _propId ) internal view {
        require( false == arrProposals[ _propId ].rejected , "Proposal was rejected" );
    }

    function CheckDeadline( uint256 _propId ) internal view {
        require( block.timestamp < arrProposals[ _propId ].deadline , "Proposal deadline" );
    }

    function CheckIsManager( address _walletAddr ) internal view {
        require( true == mapUsers[ _walletAddr ].isManager , "Not manager rights" );
    }

    function CheckIsUser( address _walletAddr ) internal view {
        require( 0 != mapUsers[ _walletAddr ].userID , "User don't exist!!" );
    }

    function CheckNotUser( address _walletAddr ) internal view {
        require( 0 == mapUsers[ _walletAddr ].userID , "User exist!!" );
    }

    function CheckNotPendingInvitation( address _walletAddr ) internal view {
        require(
            0 == pxyNFTInvitation.mapCLHUSRNFTID( address(this), _walletAddr ),
            "User have a pending Invitation"
        );
    }

    function CheckECDSA( address _walletAddr ) internal pure {
        require( address(0) != _walletAddr, "ECDSA: invalid signature" );
    }

    function CheckNotPendingReq2Join( address _walletAddr ) internal view {
        uint256 propId = mapReq2Join[ _walletAddr ];
        if(
            propId > 0 &&
            false == arrProposals[ propId ].executed &&
            false == arrProposals[ propId ].rejected &&
            block.timestamp < arrProposals[ propId ].deadline
        )
            revert( "User have a pending request to Join" );
    }

    function CheckMaxManager( bool _isManager ) internal view {
        if( _isManager )
            require( numManagers < govRuleMaxManagers, "No avaliable spots for managers" );
    }

    function CheckMaxUsers() internal view {
        require( numUsers < govRuleMaxUsers, "No avaliable spots for new users");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "Initializable.sol";
import "ICLFactory.sol";
import "ERC721CL.sol";

uint8 constant __UPGRADEABLE_CLHNFT_VERSION__ = 1;

/// @title Especial ERC-721 for CLH
/// @dev The sender will be a CLH to mint or burn. Approves and transfers isn't allowed  
contract CLHNFT is ERC721CL, Initializable {
    ICLFactory public CLF;
    uint256 public nftID;
    string private tokenURL;
    mapping( address => mapping ( address => uint256 ) ) public mapCLHUSRNFTID; // [ CLH ][ wallet ] = nftID
    
    constructor() {
        _disableInitializers();
    }

    /// @notice Constructor for new NFT
    /// @dev This function can be called once after proxy creation
    /// @param _name Name of the NFT Collection
    /// @param _symbol Symbol of the NFT Collection
    /// @param _tokenURL The URL for metadata
    /// @param _pxyCLF The address of the proxy Factory
    function Init(
        string memory _name,
        string memory _symbol,
        string memory _tokenURL,
        address _pxyCLF
    )
        external
        reinitializer( __UPGRADEABLE_CLHNFT_VERSION__ )
    {
        name = _name;
        symbol = _symbol;
        tokenURL = _tokenURL;
        CLF = ICLFactory( _pxyCLF );
    }
    
    /**
     * @dev Throws if the sender is not a CLHouse.
     */
    function _checkCLH() internal view {
        require( 0 != CLF.mapIdCLH( msg.sender ), "Caller is not a CLHouse" );
    }

    function tokenURI( uint256 ) external view override returns ( string memory ) {
        return tokenURL;
    }

    /// @notice Relacionate wallet user address with the CLH
    /// @param _pxyCLH Address of the CLH
    /// @param _to user wallet Address
    function mintToCLH( address _pxyCLH, address _to ) private {
        require(
            0 == mapCLHUSRNFTID[ _pxyCLH ][ _to ],
            "User has a NFT for this CLH"
        );
        _safeMint( _to, ++nftID );
        mapCLHUSRNFTID[ _pxyCLH ][ _to ] = nftID;
    }

    /// @notice To mint from CLF
    function forceMint( address _pxyCLH, address _to ) external {
        require( msg.sender == address( CLF ), "Caller is not a CLFactory" );
        mintToCLH( _pxyCLH, _to );
    }

    function safeMint( address _to ) external {
        _checkCLH();
        mintToCLH( msg.sender, _to );
    }

    function burn( address _wallet  ) external {
        _checkCLH();
        uint256 nid = mapCLHUSRNFTID[ msg.sender ][ _wallet ];
        require(
            0 != nid,
            "User hasn't a NFT for this CLH"
        );
        _burn( nid );
        delete mapCLHUSRNFTID[ msg.sender ][ _wallet ];
    }

    function approve(
        address,
        uint256
    ) public override pure {
        revert( "Approve isn't allowed" );
    }

    function setApprovalForAll(
        address,
        bool
    ) public override pure {
        revert( "Approve isn't allowed" );
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public override pure {
        revert( "Transfer isn't allowed" );
    }

    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes calldata
    ) public override pure {
        revert( "Transfer isn't allowed" );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "CLTypes.sol";
import "CLBeacon.sol";
import "CLHouseApi.sol";
import "CLHNFT.sol";
import "ICLHouse.sol";


interface ICLFactory {
    // View fuctions
    function numCLH() external view returns( uint256 );
    function mapCLH( uint256 ) external view returns( ICLHouse );
    function mapIdCLH( address ) external view returns( uint256 );
    function pxyApiCLH() external view returns( CLHouseApi );
    function CLLConstructorCLH() external view returns( address );
    function CLLUserManagement() external view returns( address );
    function CLLGovernance() external view returns( address );
    function beaconCLH() external view returns( CLBeacon );
    function getCLHImplementation() external view returns ( address );
    function pxyNFTManager() external view returns( CLHNFT );
    function pxyNFTMember() external view returns( CLHNFT );
    function pxyNFTInvitation() external view returns( CLHNFT );
    
    // Write Functions
    function Init(
        address _CLLUserManagement,
        address _CLLGovernance,
        address _CLLConstructorCLH,
        address _pxyApiCLH,
        address _beaconCLH,
        address _pxyNFTManager,
        address _pxyNFTMember,
        address _pxyNFTInvitation,
        address _pxyNFTAccessPass,
        address _ownerCLF
    ) external;

    function CreateCLH(
        string memory _ownerName,
        string memory _houseName,
        bool _housePrivate,
        bool _houseOpen,
        uint256 _govRuleMaxUsers,
        address _whiteListNFT,
        address _signerWallet,
        bytes memory _signature
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/*
 * ### CLH constant Types ###
 */
string constant __CLHOUSE_VERSION__ = "0.2.1";

uint8 constant __UPGRADEABLE_CLH_VERSION__ = 1;
uint8 constant __UPGRADEABLE_CLF_VERSION__ = 1;

bytes32 constant __GOV_DICTATORSHIP__ = keccak256("__GOV_DICTATORSHIP__");
bytes32 constant __GOV_COMMITTEE__ = keccak256("__GOV_COMMITTEE__");
bytes32 constant __GOV_SIMPLE_MAJORITY__ = keccak256("__GOV_SIMPLE_MAJORITY__");
bytes32 constant __CONTRACT_NAME_HASH__ = keccak256("CLHouse");
bytes32 constant __CONTRACT_VERSION_HASH__ = keccak256(
    abi.encodePacked( __CLHOUSE_VERSION__ )
);
bytes32 constant __STR_EIP712DOMAIN_HASH__ = keccak256(
    abi.encodePacked(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    )
);
bytes32 constant __STR_OCINVIT_HASH__ = keccak256(
    abi.encodePacked(
        "strOCInvit(bool acceptance,string nickname)"
    )
);
bytes32 constant __STR_OCVOTE_HASH__ = keccak256(
    abi.encodePacked(
        "strOCVote(uint256 propId,bool support,string justification)"
    )
);
bytes32 constant __STR_OCBULKVOTE_HASH__ = keccak256(
    abi.encodePacked(
        "strOCBulkVote(uint256[] propIds,bool support,string justification)"
    )
);
bytes32 constant __STR_OCNEWUSER_HASH__ = keccak256(
    abi.encodePacked(
        "strOCNewUser(address walletAddr,string name,string description,bool isManager,uint256 delayTime)"
    )
);
bytes32 constant __STR_OCDELUSER_HASH__ = keccak256(
    abi.encodePacked(
        "strOCDelUser(address walletAddr,string description,uint256 delayTime)"
    )
);
bytes32 constant __STR_OCREQUEST_HASH__ = keccak256(
    abi.encodePacked(
        "strOCRequest(string name,string description)"
    )
);
bytes32 constant __STR_OCNEWCLH_HASH__ = keccak256(
    abi.encodePacked(
        "strOCNewCLH(string ownerName,string houseName,bool housePrivate,bool houseOpen,uint256 govRuleMaxUsers,address whiteListNFT)"
    )
);
bytes32 constant __STR_OCNEWLOCK_HASH__ = keccak256(
    abi.encodePacked(
        "strOCNewLock(uint256 expirationDuration,uint256 keyPrice,uint256 maxNumberOfKeys,string lockName)"
    )
);
bytes32 constant __STR_OCUPCLH_NAME_HASH__ = keccak256(
    abi.encodePacked(
        "strOCUpCLHName(string houseName)"
    )
);

bytes32 constant __STR_OCUPCLH_WLNFT_HASH__ = keccak256(
    abi.encodePacked(
        "strOCUpCLHWLNFT(address whiteListNFT)"
    )
);

bytes32 constant __STR_OCUPCLH_GOVMAXUSERS_HASH__ = keccak256(
    abi.encodePacked(
        "strOCUpCLHMaxUsers(uint256 govRuleMaxUsers)"
    )
);

bytes32 constant __STR_OCUPCLH_HOUSEPRIVATE_HASH__ = keccak256(
    abi.encodePacked(
        "strOCUpCLHPrivacy(bool housePrivate)"
    )
);

bytes32 constant __STR_OCUPCLH_HOUSEOPEN_HASH__ = keccak256(
    abi.encodePacked(
        "strOCUpCLHOpen(bool houseOpen)"
    )
);

bytes32 constant __STR_OCUPUSR_NICKNAME_HASH__ = keccak256(
    abi.encodePacked(
        "strOCUpUsrNickname(string nickname)"
    )
);

bytes32 constant __STR_OCUSERAGGREGATE_HASH__ = keccak256(
    abi.encodePacked(
        "strOCUserAggregate(address walletAddr,string nickname,bool isManager)"
    )
);

/*
 * ### CLH enum Types ###
 */

enum userEvent{
    addUser,
    delUser,
    inviteUser,
    acceptInvitation,
    rejectInvitation,
    requestJoin,
    changeNickname
}

enum govRulesEvent{
    changeApprovPercentage,
    changeMaxUsers,
    changeMaxManagers
}

enum flagEvent{
    changeHousePrivate,
    changeHouseOpen
}

enum proposalEvent {
    addProposal,
    execProposal,
    rejectProposal
}

enum proposalType {
    newUser,
    removeUser,
    requestJoin,
    changeGovRules
}

/// @param CLLConstructorCLH Address of Logic Contract of CLH Constructor
/// @param pxyCLF Address of proxy Contract for CLFactory
/// @param pxyApiCLH Address of proxy Contract for CLHouseAPI
/// @param pxyNFTManager Address of proxy Contract for NFT Manager
/// @param pxyNFTMember Address of proxy Contract for NFT Member
/// @param pxyNFTInvitation Address of proxy Contract for NFT Invitation
/// @param whiteListNFT Address of proxy Contract for CLH Constructor
enum eCLC {
    CLLConstructorCLH,
    pxyCLF,
    pxyApiCLH,
    pxyNFTManager,
    pxyNFTMember,
    pxyNFTInvitation,
    whiteListNFT
}


/*
 * ### CLH struct Types ###
 */

struct strUser {
    uint256 userID;
    string nickname;
    bool isManager;
}

struct strProposal {
    address proponent;
    proposalType typeProposal;
    string description;
    uint256 propDataId;
    uint256 numVotes;
    uint256 againstVotes;
    bool executed;
    bool rejected;
    uint256 deadline;
}

struct strVote {
    bool voted;
    bool inSupport;
    string justification;
}

struct strDataUser {
    address walletAddr;
    string name;
    bool isManager;
}

struct strDataTxAssets {
    address to;
    uint256 amountOutCLV;
    address tokenOutCLV;
    address tokenInCLV;
}

struct strDataGovRules {
    uint256 newApprovPercentage;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "UpgradeableBeacon.sol";

contract CLBeacon is UpgradeableBeacon {
    constructor(
        address _CLLogicContract
    )
        UpgradeableBeacon(
            _CLLogicContract
        )
    {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/UpgradeableBeacon.sol)

pragma solidity ^0.8.0;

import "IBeacon.sol";
import "Ownable.sol";
import "Address.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeacon is IBeacon, Ownable {
    address private _implementation;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address implementation_) {
        _setImplementation(implementation_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableBeacon: implementation is not a contract");
        _implementation = newImplementation;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
pragma solidity ^0.8.11;

import "ICLHouse.sol";

/// @title Some view funtions to interact with a CLHouse
/// @author Leonardo Urrego
contract CLHouseApi {

    /// @notice A funtion to verify the signer of a menssage
    /// @param _msghash Hash of the message
    /// @param _signature Signature of the message
    /// @return Signer address of the message
    function SignerOfMsg(
        bytes32  _msghash,
        bytes memory _signature
    )
        public
        pure
        returns( address )
    {
        require( _signature.length == 65, "Bad signature length" );

        bytes32 signR;
        bytes32 signS;
        uint8 signV;

        assembly {
            // first 32 bytes, after the length prefix
            signR := mload( add( _signature, 32 ) )
            // second 32 bytes
            signS := mload( add( _signature, 64 ) )
            // final byte (first byte of the next 32 bytes)
            signV := byte( 0, mload( add( _signature, 96 ) ) )
        }

        return ecrecover( _msghash, signV, signR, signS );
    }


    struct strInfoUser {
        address wallet;
        uint256 userID;
        string nickname;
        bool isManager;
    }

    /// @notice The list of all users address
    /// @param _houseAddr address of the CLH
    /// @return arrUsers array of user address
    function GetHouseUserList(
        address _houseAddr
    )
        external
        view
        returns(
            strInfoUser[] memory arrUsers
        )
    {
        ICLHouse daoCLH = ICLHouse( _houseAddr );

        uint256 numUsers = daoCLH.numUsers( );
        uint256 arrUsersLength = daoCLH.GetArrUsersLength();
        arrUsers = new strInfoUser[] ( numUsers );

        uint256 index = 0 ;

        for( uint256 uid = 1 ; uid < arrUsersLength ; uid++ ) {
            strInfoUser memory houseUser;

            houseUser.wallet = daoCLH.arrUsers( uid );

            (   houseUser.userID,
                houseUser.nickname,
                houseUser.isManager ) = daoCLH.mapUsers( houseUser.wallet );

            if( 0 != houseUser.userID ){
                arrUsers[ index ] = houseUser;
                index++;
            }
        }
    }


    /// @notice Retrieve the signer from Offchain Invitation signature
    /// @param _acceptance True for accept the invitation
    /// @param _nickname A nickname for the user
    /// @param _houseAddr address of the CLH
    /// @param _signature EIP712 Signature
    /// @return Wallet address of the signer
    function SignerOCInvit(
        bool _acceptance,
        string memory _nickname,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCINVIT_HASH__,
                _acceptance,
                keccak256( abi.encodePacked( _nickname ) )
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    /// @notice Retrieve the signer from Offchain Vote signature
    /// @param _propId ID of the proposal, based on `arrProposals`
    /// @param _support True for accept, false to reject
    /// @param _justification About your vote
    /// @param _houseAddr address of the CLH
    /// @param _signature EIP712 Signature
    /// @return Wallet address of the signer
    function SignerOCVote(
        uint _propId,
        bool _support,
        string memory _justification,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCVOTE_HASH__,
                _propId,
                _support,
                keccak256( abi.encodePacked( _justification ) )
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    /// @notice Retrieve the signer from Offchain BulkVote signature
    /// @param _propIds Array with ID of the proposal to votes
    /// @param _support is the Vote (True or False) for all proposals
    /// @param _justification Description of the vote
    /// @param _houseAddr address of the CLH
    /// @param _signature EIP712 Signature
    /// @return Wallet address of the signer
    function SignerOCBulkVote(
        uint256[] memory _propIds,
        bool _support,
        string memory _justification,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCBULKVOTE_HASH__,
                keccak256( abi.encodePacked( _propIds ) ),
                _support,
                keccak256( abi.encodePacked( _justification ) )
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    /// @notice Retrieve the signer from Offchain Invite User signature
    /// @param _walletAddr  Address of the new user
    /// @param _name Can be the nickname or other reference to the User
    /// @param _description A text for the proposal
    /// @param _isManager True if is for a manager
    /// @param _houseAddr address of the CLH
    /// @param _signature EIP712 Signature
    /// @return Wallet address of the signer
    function SignerOCInvitUser(
        address _walletAddr,
        string memory _name,
        string memory _description,
        bool _isManager,
        uint256 _delayTime,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCNEWUSER_HASH__,
                _walletAddr,
                keccak256( abi.encodePacked( _name ) ),
                keccak256( abi.encodePacked( _description ) ),
                _isManager,
                _delayTime
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    /// @notice Retrieve the signer from Offchain Remove User signature
    /// @param _walletAddr user Address to be removed
    /// @param _description About the proposal
    /// @param _houseAddr address of the CLH
    /// @param _signature EIP712 Signature
    /// @return Wallet address of the signer
    function SignerOCRemoveUser(
        address _walletAddr,
        string memory _description,
        uint256 _delayTime,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCDELUSER_HASH__,
                _walletAddr,
                keccak256( abi.encodePacked( _description ) ),
                _delayTime
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    /// @notice Retrieve the signer from Offchain request to join signature
    /// @param _name Nickname or other user identification
    /// @param _description About the request
    /// @param _houseAddr address of the CLH
    /// @param _signature EIP712 Signature
    /// @return Wallet address of the signer
    function SignerOCRequestToJoin(
        string memory _name,
        string memory _description,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCREQUEST_HASH__,
                keccak256( abi.encodePacked( _name ) ),
                keccak256( abi.encodePacked( _description ) )
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    /// @notice Retrieve the signer from Offchain New house signature
    /// @param _ownerName Nickname of the Owner
    /// @param _houseName Name of the CLH
    /// @param _housePrivate If is set to 1, the CLH is set to private
    /// @param _houseOpen If is set to 1, the CLH is set to open
    /// @param _govRuleMaxUsers Max users in the house
    /// @param _whiteListNFT Address of NFT Collection for users invitation
    /// @param _pxyCLF address of the CLF
    /// @param _signature EIP712 Signature
    /// @return Wallet address of the signer
    function SignerOCNewCLH(
        string memory _ownerName,
        string memory _houseName,
        bool _housePrivate,
        bool _houseOpen,
        uint256 _govRuleMaxUsers,
        address _whiteListNFT,
        address _pxyCLF,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _pxyCLF
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCNEWCLH_HASH__,
                keccak256( abi.encodePacked( _ownerName ) ),
                keccak256( abi.encodePacked( _houseName ) ),
                _housePrivate,
                _houseOpen,
                _govRuleMaxUsers,
                _whiteListNFT
                // keccak256( abi.encodePacked( _whiteListWallets ) )
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    /// @notice Retrieve the signer from Offchain New Lock signature
    /// @param _expirationDuration Expiration for lcok in seconds
    /// @param _keyPrice Price for each lock in wei
    /// @param _maxNumberOfKeys How many locks
    /// @param _lockName Lock Name
    /// @param _houseAddr address of the CLH
    /// @param _signature EIP712 Signature
    /// @return Wallet address of the signer
    function SignerOCNewLock(
        uint256 _expirationDuration,
        uint256 _keyPrice,
        uint256 _maxNumberOfKeys,
        string memory _lockName,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCNEWLOCK_HASH__,
                _expirationDuration,
                _keyPrice,
                _maxNumberOfKeys,
                keccak256( abi.encodePacked( _lockName ) )
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    /// @notice Retrieve the signer from Offchain Update CLH Name
    /// @param _houseName new CLH Name
    /// @param _houseAddr address of the CLH
    /// @param _signature EIP712 Signature
    /// @return Wallet address of the signer
    function SignerOCUpCLHName(
        string memory _houseName,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCUPCLH_NAME_HASH__,
                keccak256( abi.encodePacked( _houseName ) )
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    /// @notice Retrieve the signer from Offchain Update CLH Whitelist NFT
    /// @param _whiteListNFT New contract address of NFT
    /// @param _houseAddr address of the CLH
    /// @param _signature EIP712 Signature
    /// @return Wallet address of the signer
    function SignerOCUpCLHWLNFT(
        address _whiteListNFT,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCUPCLH_WLNFT_HASH__,
                _whiteListNFT
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    /// @notice Retrieve the signer from Offchain Update CLH govRuleMaxUsers
    /// @param _govRuleMaxUsers New value of MaxUsers
    /// @param _houseAddr address of the CLH
    /// @param _signature EIP712 Signature
    /// @return Wallet address of the signer
    function SignerOCUpCLHMaxUsers(
        uint256 _govRuleMaxUsers,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCUPCLH_GOVMAXUSERS_HASH__,
                _govRuleMaxUsers
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    /// @notice Retrieve the signer from Offchain Update CLH flag of housePrivate
    /// @param _housePrivate New value of housePrivate
    /// @param _houseAddr address of the CLH
    /// @param _signature EIP712 Signature
    /// @return Wallet address of the signer
    function SignerOCUpCLHPrivacy(
        bool _housePrivate,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCUPCLH_HOUSEPRIVATE_HASH__,
                _housePrivate
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    /// @notice Retrieve the signer from Offchain Update CLH flag of houseOpen
    /// @param _houseOpen New value of houseOpen
    /// @param _houseAddr address of the CLH
    /// @param _signature EIP712 Signature
    /// @return Wallet address of the signer
    function SignerOCUpCLHOpen(
        bool _houseOpen,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCUPCLH_HOUSEOPEN_HASH__,
                _houseOpen
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    /// @notice Retrieve the signer from Offchain Update CLH flag of houseOpen
    /// @param _nickname New nickname of user
    /// @param _houseAddr address of the CLH
    /// @param _signature EIP712 Signature
    /// @return Wallet address of the signer
    function SignerOCUpUsrNickname(
        string memory _nickname,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCUPUSR_NICKNAME_HASH__,
                keccak256( abi.encodePacked( _nickname ) )
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    /// @notice Retrieve the signer from Offchain to Aggregate User to CLH
    /// @param _walletAddr User Wallet to Add
    /// @param _nickname New nickname of user
    /// @param _isManager True if is for a manager
    /// @param _houseAddr address of the CLH
    /// @param _signature EIP712 Signature
    /// @return Wallet address of the signer
    function SignerOCUserAggregate(
        address _walletAddr,
        string memory _nickname,
        bool _isManager,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCUSERAGGREGATE_HASH__,
                _walletAddr,
                keccak256( abi.encodePacked( _nickname ) ),
                _isManager
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "CLTypes.sol";


interface ICLHouse {

    // View fuctions
    function numUsers() external view returns( uint256 );
    function arrUsers( uint256 ) external view returns( address );
    function mapUsers( address ) external view returns( uint256, string memory, bool );
    function arrProposals( uint256 ) external view returns( address, proposalType, string memory, uint16, uint8, uint8, bool, bool, uint256 );
    function arrDataPropUser( uint256 ) external view returns( address, string memory, bool );
    function arrDataPropGovRules( uint256 ) external view returns( uint256 );
    function GetArrUsersLength() external view returns( uint256 );
    function mapVotes( uint256,  address ) external view returns( bool, bool, string memory);


    // no-view functions
    function ExecProp(
        uint _propId
    )
        external 
        returns(
            bool status, 
            string memory message
        );

    function VoteProposal(
        uint _propId,
        bool _support,
        string memory _justification,
        bytes memory _signature
    )
        external;

    function PropInvitUser(
        address _walletAddr,
        string memory _name,
        string memory _description,
        bool _isManager,
        uint256 _delayTime,
        bytes memory _signature
    )
        external
        returns(
            uint propId
        );

    function PropRemoveUser(
        address _walletAddr,
        string memory _description,
        uint256 _delayTime,
        bytes memory _signature
    )
        external
        returns(
            uint propId
        );

    function PropRequestToJoin(
        string memory _name,
        string memory _description,
        address _signerWallet,
        bytes memory _signature
    )
        external
        returns(
            uint propId
        );

    function AcceptRejectInvitation(
        bool __acceptance,
        bytes memory _signature
    )
        external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
// Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface ERC721Metadata {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory _symbol);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,    // _operator
        address,    // _from
        uint256,    // _tokenId
        bytes calldata  // _data
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

/// @notice Re-implementation of ERC-721 based on Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
/// @author LeoUL (LE0xUL)
abstract contract ERC721CL is ERC721Metadata {
    /**
        METADATA STORAGE/LOGIC
    */
    string public name;
    string public symbol;

    /**
        ERC721 BALANCE/OWNER STORAGE
    */
    mapping( uint256 => address ) internal __ownerOf;
    mapping( address => uint256) internal __balanceOf;

    /**
        ERC721 APPROVAL STORAGE
    */
    mapping( uint256 => address ) public getApproved;
    mapping( address => mapping( address => bool ) ) public isApprovedForAll;

    /**
        EVENTS
    */
    event Transfer( address indexed from, address indexed to, uint256 indexed id );
    event Approval( address indexed owner, address indexed spender, uint256 indexed id );
    event ApprovalForAll( address indexed owner, address indexed operator, bool approved );


    /**
        ERC721 LOGIC
    */
    function tokenURI( uint256 _id ) external view virtual returns( string memory );

    function ownerOf( uint256 _id ) public view virtual returns( address  _owner ) {
        require( ( _owner = __ownerOf[ _id ] ) != address(0), "NOT_MINTED");
    }

    function balanceOf( address  _owner ) public view virtual returns( uint256 ) {
        require( _owner  != address(0), "ZERO_ADDRESS");

        return __balanceOf[ _owner ];
    }

    function approve( address _spender, uint256 _id ) public virtual {
        address owner = __ownerOf[ _id ];

        require( msg.sender == owner || isApprovedForAll[ owner ][ msg.sender ], "NOT_AUTHORIZED" );

        getApproved[ _id ] = _spender;

        emit Approval( owner, _spender, _id );
    }

    function setApprovalForAll( address operator, bool approved ) public virtual {
        isApprovedForAll[ msg.sender ][ operator ] = approved;

        emit ApprovalForAll( msg.sender, operator, approved );
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == __ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            __balanceOf[from]--;

            __balanceOf[to]++;
        }

        __ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(
            to.code.length == 0 ||
            ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
            ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );

        transferFrom(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        require(
            to.code.length == 0 ||
            ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
            ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );

        transferFrom(from, to, id);
    }

    /**
        ERC165 LOGIC
    */

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /**
        INTERNAL MINT/BURN LOGIC
    */

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(__ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            __balanceOf[to]++;
        }

        __ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = __ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            __balanceOf[owner]--;
        }

        delete __ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /**
        INTERNAL SAFE MINT LOGIC
    */

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint( to, id );

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;

/**
 * @title The Unlock Interface
 **/

interface IUnlock {
  // Use initialize instead of a constructor to support proxies(for upgradeability via zos).
  function initialize(address _unlockOwner) external;

  /**
   * @dev deploy a ProxyAdmin contract used to upgrade locks
   */
  function initializeProxyAdmin() external;

  /**
   * Retrieve the contract address of the proxy admin that manages the locks
   * @return the address of the ProxyAdmin instance
   */
  function proxyAdminAddress()
    external
    view
    returns (address);

  /**
   * @notice Create lock (legacy)
   * This deploys a lock for a creator. It also keeps track of the deployed lock.
   * @param _expirationDuration the duration of the lock (pass 0 for unlimited duration)
   * @param _tokenAddress set to the ERC20 token address, or 0 for ETH.
   * @param _keyPrice the price of each key
   * @param _maxNumberOfKeys the maximum nimbers of keys to be edited
   * @param _lockName the name of the lock
   * param _salt [deprec] -- kept only for backwards copatibility
   * This may be implemented as a sequence ID or with RNG. It's used with `create2`
   * to know the lock's address before the transaction is mined.
   * @dev internally call `createUpgradeableLock`
   */
  function createLock(
    uint _expirationDuration,
    address _tokenAddress,
    uint _keyPrice,
    uint _maxNumberOfKeys,
    string calldata _lockName,
    bytes12 // _salt
  ) external returns (address);

  /**
   * @notice Create lock (default)
   * This deploys a lock for a creator. It also keeps track of the deployed lock.
   * @param data bytes containing the call to initialize the lock template
   * @dev this call is passed as encoded function - for instance:
   *  bytes memory data = abi.encodeWithSignature(
   *    'initialize(address,uint256,address,uint256,uint256,string)',
   *    msg.sender,
   *    _expirationDuration,
   *    _tokenAddress,
   *    _keyPrice,
   *    _maxNumberOfKeys,
   *    _lockName
   *  );
   * @return address of the create lock
   */
  function createUpgradeableLock(
    bytes memory data
  ) external returns (address);

  /**
   * Create an upgradeable lock using a specific PublicLock version
   * @param data bytes containing the call to initialize the lock template
   * (refer to createUpgradeableLock for more details)
   * @param _lockVersion the version of the lock to use
   */
  function createUpgradeableLockAtVersion(
    bytes memory data,
    uint16 _lockVersion
  ) external returns (address);

  /**
   * @notice Upgrade a lock to a specific version
   * @dev only available for publicLockVersion > 10 (proxyAdmin /required)
   * @param lockAddress the existing lock address
   * @param version the version number you are targeting
   * Likely implemented with OpenZeppelin TransparentProxy contract
   */
  function upgradeLock(
    address payable lockAddress,
    uint16 version
  ) external returns (address);

  /**
   * This function keeps track of the added GDP, as well as grants of discount tokens
   * to the referrer, if applicable.
   * The number of discount tokens granted is based on the value of the referal,
   * the current growth rate and the lock's discount token distribution rate
   * This function is invoked by a previously deployed lock only.
   */
  function recordKeyPurchase(
    uint _value,
    address _referrer // solhint-disable-line no-unused-vars
  ) external;

  /**
   * @notice [DEPRECATED] Call to this function has been removed from PublicLock > v9.
   * @dev [DEPRECATED] Kept for backwards compatibility
   * This function will keep track of consumed discounts by a given user.
   * It will also grant discount tokens to the creator who is granting the discount based on the
   * amount of discount and compensation rate.
   * This function is invoked by a previously deployed lock only.
   */
  function recordConsumedDiscount(
    uint _discount,
    uint _tokens // solhint-disable-line no-unused-vars
  ) external view;

  /**
   * @notice [DEPRECATED] Call to this function has been removed from PublicLock > v9.
   * @dev [DEPRECATED] Kept for backwards compatibility
   * This function returns the discount available for a user, when purchasing a
   * a key from a lock.
   * This does not modify the state. It returns both the discount and the number of tokens
   * consumed to grant that discount.
   */
  function computeAvailableDiscountFor(
    address _purchaser, // solhint-disable-line no-unused-vars
    uint _keyPrice // solhint-disable-line no-unused-vars
  ) external pure returns (uint discount, uint tokens);

  // Function to read the globalTokenURI field.
  function globalBaseTokenURI()
    external
    view
    returns (string memory);

  /**
   * @dev Redundant with globalBaseTokenURI() for backwards compatibility with v3 & v4 locks.
   */
  function getGlobalBaseTokenURI()
    external
    view
    returns (string memory);

  // Function to read the globalTokenSymbol field.
  function globalTokenSymbol()
    external
    view
    returns (string memory);

  // Function to read the chainId field.
  function chainId() external view returns (uint);

  /**
   * @dev Redundant with globalTokenSymbol() for backwards compatibility with v3 & v4 locks.
   */
  function getGlobalTokenSymbol()
    external
    view
    returns (string memory);

  /**
   * @notice Allows the owner to update configuration variables
   */
  function configUnlock(
    address _udt,
    address _weth,
    uint _estimatedGasForPurchase,
    string calldata _symbol,
    string calldata _URI,
    uint _chainId
  ) external;

  /**
   * @notice Add a PublicLock template to be used for future calls to `createLock`.
   * @dev This is used to upgrade conytract per version number
   */
  function addLockTemplate(
    address impl,
    uint16 version
  ) external;

  /**
   * Match lock templates addresses with version numbers
   * @param _version the number of the version of the template
   * @return address of the lock templates
   */
  function publicLockImpls(
    uint16 _version
  ) external view returns (address);

  /**
   * Match version numbers with lock templates addresses
   * @param _impl the address of the deployed template contract (PublicLock)
   * @return number of the version corresponding to this address
   */
  function publicLockVersions(
    address _impl
  ) external view returns (uint16);

  /**
   * Retrive the latest existing lock template version
   * @return the version number of the latest template (used to deploy contracts)
   */
  function publicLockLatestVersion()
    external
    view
    returns (uint16);

  /**
   * @notice Upgrade the PublicLock template used for future calls to `createLock`.
   * @dev This will initialize the template and revokeOwnership.
   */
  function setLockTemplate(
    address payable _publicLockAddress
  ) external;

  // Allows the owner to change the value tracking variables as needed.
  function resetTrackedValue(
    uint _grossNetworkProduct,
    uint _totalDiscountGranted
  ) external;

  function grossNetworkProduct()
    external
    view
    returns (uint);

  function totalDiscountGranted()
    external
    view
    returns (uint);

  function locks(
    address
  )
    external
    view
    returns (
      bool deployed,
      uint totalSales,
      uint yieldedDiscountTokens
    );

  // The address of the public lock template, used when `createLock` is called
  function publicLockAddress()
    external
    view
    returns (address);

  // Map token address to exchange contract address if the token is supported
  // Used for GDP calculations
  function uniswapOracles(
    address
  ) external view returns (address);

  // The WETH token address, used for value calculations
  function weth() external view returns (address);

  // The UDT token address, used to mint tokens on referral
  function udt() external view returns (address);

  // The approx amount of gas required to purchase a key
  function estimatedGasForPurchase()
    external
    view
    returns (uint);

  /**
   * Helper to get the network mining basefee as introduced in EIP-1559
   * @dev this helper can be wrapped in try/catch statement to avoid
   * revert in networks where EIP-1559 is not implemented
   */
  function networkBaseFee() external view returns (uint);

  // The version number of the current Unlock implementation on this network
  function unlockVersion() external pure returns (uint16);

  /**
   * @notice allows the owner to set the oracle address to use for value conversions
   * setting the _oracleAddress to address(0) removes support for the token
   * @dev This will also call update to ensure at least one datapoint has been recorded.
   */
  function setOracle(
    address _tokenAddress,
    address _oracleAddress
  ) external;

  // Initialize the Ownable contract, granting contract ownership to the specified sender
  function __initializeOwnable(address sender) external;

  /**
   * @dev Returns true if the caller is the current owner.
   */
  function isOwner() external view returns (bool);

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() external view returns (address);

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() external;

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) external;
}