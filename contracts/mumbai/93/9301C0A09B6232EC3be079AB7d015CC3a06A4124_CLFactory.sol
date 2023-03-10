// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "Initializable.sol";
import "ICLHouse.sol";
import "ICLFactory.sol";
import "CLBeacon.sol";
import "CLPBeacon.sol";
import "CLHouseApi.sol";
import "CLHNFT.sol";
import "CLANFT.sol";


/// @title Crypto League House Factory
/// @notice Create and config CLHouses
/// @dev This contract is the standard way to create CLH
/// @author Leonardo Urrego
contract CLFactory is ICLFactory, Initializable {
    /// @notice Store the number of houses created
    uint256 public numCLH;

    /// @notice Proxy Contract to CLH Constructor logic
    address public CLLConstructorCLH;

    /// @notice Proxy Contract to functions for user management
    address public CLLUserManagement;

    /// @notice Proxy Contract to functions for Governance
    address public CLLGovernance;

    /// @notice Wallet address owner of the CLFactory
    address public ownerCLF;

    /// @notice Proxy Contract to CLHouse API
    CLHouseApi public pxyApiCLH;

    /// @notice Contract Object of the beacon (store the add)
    /// @dev The beacon store the updated address of CLH
    CLBeacon public beaconCLH;
    
    /// @notice Contract Proxy of NFT Manager
    CLHNFT public pxyNFTManager;

    /// @notice Contract Proxy of NFT Member
    CLHNFT public pxyNFTMember;

    /// @notice Contract Proxy of NFT Invitation
    CLHNFT public pxyNFTInvitation;

    /// @notice Contract Proxy of NFT AccessPass
    CLANFT public pxyNFTAccessPass;

    /// @notice Relation houseAddr with houseId
    mapping( address => uint256 ) public mapIdCLH;
    
    /// @notice Mapping to store all the created houses
    mapping( uint256 => ICLHouse ) public mapCLH;


    /// @notice Event when house is created
    /// @param houseAddr Address of the created house
    /// @param houseName Name of the created house
    /// @param houseId Id of CLH of the created house
    event evtNewCLH( address houseAddr, string houseName, uint256 houseId );

    /// @notice Event when a CL Contract address is updated
    /// @param CLCName Name of contract var
    /// @param oldAddress Old Address value of the var
    /// @param newAddress New Address value of the var
    event evtUpdateCLC( string CLCName, address oldAddress, address newAddress );

    modifier onlyOwner() {
        require( msg.sender == ownerCLF, "Only Owner of CLF" );
        _;
    }

    function checkAccessNFT( address _wallet ) public {
        require( 0 != pxyNFTAccessPass.balanceOf( _wallet ) , "Don't have Access NFT" );
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Config the CLFactory with the CL Logic Contracts
    /// @param _beaconCLH Address Beacon CLH Contract
    /// @param _pxyApiCLH Address of pxyApiCLH Contract
    /// @param _pxyNFTManager Address of proxy Contract for NFT Manager
    /// @param _pxyNFTMember Address of proxy Contract for NFT Member
    /// @param _pxyNFTInvitation Address of proxy Contract for NFT Invitation
    /// @param _CLLUserManagement Address Contract Logic for user management
    /// @param _CLLGovernance Address Contract Logic for governance
    /// @param _CLLConstructorCLH Address Contract with the Constructor logic
    /// @param _ownerCLF Address Owner for this Contract
    function Init(
        address _beaconCLH,
        address _pxyApiCLH,
        address _pxyNFTManager,
        address _pxyNFTMember,
        address _pxyNFTInvitation,
        address _pxyNFTAccessPass,
        address _CLLUserManagement,
        address _CLLGovernance,
        address _CLLConstructorCLH,
        address _ownerCLF
    )
        public
        reinitializer( __UPGRADEABLE_CLF_VERSION__ )
    {
        beaconCLH = CLBeacon( _beaconCLH );
        
        pxyApiCLH = CLHouseApi( _pxyApiCLH );

        CLLUserManagement = _CLLUserManagement;
        CLLGovernance = _CLLGovernance;
        CLLConstructorCLH = _CLLConstructorCLH;

        pxyNFTManager = CLHNFT( _pxyNFTManager );
        pxyNFTMember = CLHNFT( _pxyNFTMember );
        pxyNFTInvitation = CLHNFT( _pxyNFTInvitation );
        pxyNFTAccessPass = CLANFT( _pxyNFTAccessPass );
        
        numCLH = 0;
        mapCLH[ numCLH ] = ICLHouse( address(0) );
        mapIdCLH[ address(0) ] = numCLH;

        ownerCLF = _ownerCLF;
    }


    /// @notice Create a new CLHouse proxy Contract
    /// @param _houseName Name of the CLH
    /// @param _housePrivate If is set to 1, the CLH is set to private
    /// @param _houseOpen If is set to 1, the CLH is set to open
    /// @param _govRuleMaxUsers Max users in the house
    /// @param _whiteListNFT Address of NFT Collection for users invitation
    /// @param _signerWallet Wallet address of the signer for OffChain Tx
    /// @param _signature Signature for validate OffChain Tx
    function CreateCLH(
        string memory _houseName,
        bool _housePrivate,
        bool _houseOpen,
        uint256 _govRuleMaxUsers,
        address _whiteListNFT,
        address _signerWallet,
        bytes memory _signature
    ) 
        public
    {
        address houseOwner = msg.sender;

        if( _signerWallet != address(0) ) {
            require( _signature.length == 65, "CreateCLH: Bad signature length" );
            
            require(
                _signerWallet == pxyApiCLH.SignerOCNewCLH(
                    _houseName,
                    _housePrivate,
                    _houseOpen,
                    _govRuleMaxUsers,
                    _whiteListNFT,
                    address(this),
                    _signature
                ),
                "CreateCLH: Invalid Signature"
            );

            houseOwner = _signerWallet;
        }

        checkAccessNFT( houseOwner );

        CLPBeacon pxyCLH = new CLPBeacon(
            address( beaconCLH ),
            abi.encodeWithSignature(
                "Init(address,string,bool,bool,uint256,address[7])",
                houseOwner, 
                _houseName,
                _housePrivate,
                _houseOpen,
                _govRuleMaxUsers,
                [ 
                    CLLConstructorCLH,
                    address( this ),
                    address( pxyApiCLH ),
                    address( pxyNFTManager ),
                    address( pxyNFTMember ),
                    address( pxyNFTInvitation ),
                    _whiteListNFT
                ]
            )
        );

        numCLH++;
        mapCLH[ numCLH ] = ICLHouse( address( pxyCLH ) );
        mapIdCLH[ address( pxyCLH ) ] = numCLH;

        pxyNFTManager.forceMint( address( pxyCLH ), houseOwner );

        emit evtNewCLH( address( pxyCLH ), _houseName, numCLH );
    }


    /// @notice Get the address of the CLH contract logic
    function getCLHImplementation() external view returns (address) {
        return beaconCLH.implementation();
    }

    /// @notice Update the CLLConstructorCLH contract Address
    function UpdateCLLConstructorCLH( address _CLLConstructorCLH ) external onlyOwner {
        address oldAddr = CLLConstructorCLH;
        CLLConstructorCLH = _CLLConstructorCLH;
        emit evtUpdateCLC( "CLLConstructorCLH", oldAddr, _CLLConstructorCLH );
    }

    /// @notice Update the CLLUserManagement contract Address
    function UpdateCLLUserManagement( address _CLLUserManagement ) external onlyOwner {
        address oldAddr = CLLUserManagement;
        CLLUserManagement = _CLLUserManagement;
        emit evtUpdateCLC( "CLLUserManagement", oldAddr, _CLLUserManagement );
    }

    /// @notice Update the CLLGovernance contract Address
    function UpdateCLLGovernance( address _CLLGovernance ) external onlyOwner {
        address oldAddr = CLLGovernance;
        CLLGovernance = _CLLGovernance;
        emit evtUpdateCLC( "CLLGovernance", oldAddr, _CLLGovernance );
    }

    /// @notice Update the pxyApiCLH contract Address
    function UpdateCLHAPI( address _pxyApiCLH ) external onlyOwner {
        address oldAddr = address( pxyApiCLH );
        pxyApiCLH = CLHouseApi( _pxyApiCLH );
        emit evtUpdateCLC( "pxyApiCLH", oldAddr, _pxyApiCLH );
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/*
 * ### CLH constant Types ###
 */
string constant __CLHOUSE_VERSION__ = "0.2.0";

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
        "strOCNewCLH(string houseName,bool housePrivate,bool houseOpen,uint256 govRuleMaxUsers,address whiteListNFT)"
    )
);
bytes32 constant __STR_OCNEWLOCK_HASH__ = keccak256(
    abi.encodePacked(
        "strOCNewLock(uint256 expirationDuration,uint256 keyPrice,uint256 maxNumberOfKeys,string lockName)"
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
    requestJoin
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
    /// @param _houseName Name of the CLH
    /// @param _housePrivate If is set to 1, the CLH is set to private
    /// @param _houseOpen If is set to 1, the CLH is set to open
    /// @param _govRuleMaxUsers Max users in the house
    /// @param _whiteListNFT Address of NFT Collection for users invitation
    /// @param _pxyCLF address of the CLF
    /// @param _signature EIP712 Signature
    /// @return Wallet address of the signer
    function SignerOCNewCLH(
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

    function tokenURI( uint256 _id ) external view override returns ( string memory ) {
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
        address _spender,
        uint256 _id
    ) public override {
        revert( "Approve isn't allowed" );
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override {
        revert( "Approve isn't allowed" );
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _id
    ) public override {
        revert( "Transfer isn't allowed" );
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        bytes calldata _data
    ) public override {
        revert( "Transfer isn't allowed" );
    }
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
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
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
pragma solidity ^0.8.11;

import "BeaconProxy.sol";

contract CLPBeacon is BeaconProxy {
    constructor(
        address _beacon,
        bytes memory _data
    )
        BeaconProxy(
            _beacon,
            _data
        )
    {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/beacon/BeaconProxy.sol)

pragma solidity ^0.8.0;

import "IBeacon.sol";
import "Proxy.sol";
import "ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from an {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializing the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "IBeacon.sol";
import "draft-IERC1822.sol";
import "Address.sol";
import "StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "Initializable.sol";
import "ERC721CL.sol";

uint8 constant __UPGRADEABLE_CLANFT_VERSION__ = 1;

/// @title Especial ERC-721 for CLH
/// @dev The sender will be a CLH to mint or burn. Approves and transfers isn't allowed  
contract CLANFT is ERC721CL, Initializable {
    uint256 public nftID;
    string private tokenURL;
    mapping( address => uint256 ) public mapIdNFT;
    mapping( address => bool ) public adminWallet;
    
    constructor() {
        _disableInitializers();
    }

    /// @notice Constructor for new NFT
    /// @dev This function can be called once after proxy creation
    /// @param _name Name of the NFT Collection
    /// @param _symbol Symbol of the NFT Collection
    /// @param _tokenURL The URL for metadata
    function Init(
        string memory _name,
        string memory _symbol,
        string memory _tokenURL,
        address _walletAdmin
    )
        external
        reinitializer( __UPGRADEABLE_CLANFT_VERSION__ )
    {
        name = _name;
        symbol = _symbol;
        tokenURL = _tokenURL;
        adminWallet[ _walletAdmin ] = true;
        _safeMint( _walletAdmin, ++nftID );
        mapIdNFT[ _walletAdmin ] = nftID;
    }
    
    /**
     * @dev Throws if the sender is not an Admin.
     */
    modifier onlyAdmin() {
        require( true == adminWallet[ msg.sender ], "Caller is not an NFT Admin" );
        _;
    }

    function tokenURI( uint256 _id ) external view override returns ( string memory ) {
        return tokenURL;
    }


    function safeMint( address _to ) external onlyAdmin {
        require( 0 == __balanceOf[ _to ], "User already has an NFT" );
        _safeMint( _to, ++nftID );
        mapIdNFT[ _to ] = nftID;
    }

    function burn( address _wallet  ) external onlyAdmin {
        uint256 nid = mapIdNFT[ _wallet ];
        require( 0 != nid , "User doesn't have an NFT" );
        // require( __balanceOf( _wallet ) > 0 , "User doesn't have an NFT" );
        _burn( nid );
        delete mapIdNFT[ _wallet ];
    }

    function approve(
        address _spender,
        uint256 _id
    ) public override {
        revert( "Approve isn't allowed" );
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override {
        revert( "Approve isn't allowed" );
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _id
    ) public override {
        revert( "Transfer isn't allowed" );
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        bytes calldata _data
    ) public override {
        revert( "Transfer isn't allowed" );
    }

    function AddAdmin( address _wallet ) external onlyAdmin {
        adminWallet[ _wallet ] = true;
    }

    function DelAdmin( address _wallet ) external onlyAdmin {
        delete adminWallet[ _wallet ];
    }
}