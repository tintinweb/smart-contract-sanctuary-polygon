// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title Upgradeable interface(abstract contract) for approval and transfer control mechanism
 * @author 0xedy
 * @notice This abstract contract is base for RestrcitApprove, Lockcable, etc..
 */

abstract contract AntiScamAbstract {

    error ApproveToNotAllowedTransferer();
    error TransferForNotAllowedToken();

    modifier onlyTokenApprovable (address transferer, uint256 tokenId) virtual {
        _checkTokenApprovable(transferer, tokenId);
        _;
    }

    modifier onlyWalletApprovable (address transferer, address holder, bool approved) virtual {
        _checkWalletApprovable(transferer, holder, approved);
        _;
    }

    modifier onlyTransferable (
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) virtual {
        _checkTransferable(from, to, startTokenId, quantity);
        _;
    }

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================
    function _initializeAntiScam() internal virtual {
        
    }

    // =============================================================
    //                          INTERNAL LOGIC FUNCTIONS
    // =============================================================

    function _isTokenApprovable (address /*transferer*/, uint256 /*tokenId*/) 
        internal
        view
        virtual
        returns (bool)
    {
        return true;
    }
    function _checkTokenApprovable (address transferer, uint256 tokenId)
        internal 
        view 
        virtual 
    {
        // Approving to Zero adress is alwayd allowed because it is disapproving.
        if (transferer != address(0)) {
            if (!_isTokenApprovable(transferer, tokenId)) revert ApproveToNotAllowedTransferer();
        }
    }

    function _isWalletApprovable(address /*transferer*/, address /*holder*/)
        internal
        view
        virtual
        returns (bool)
    {
        return true;
    }


    function _checkWalletApprovable (address transferer, address holder, bool approved)
        internal 
        view 
        virtual 
    {
        // Disapproving is always 
        if (approved) {
            if (!_isWalletApprovable(transferer, holder)) revert ApproveToNotAllowedTransferer();
        }
    }

    function _isTransferable (
        address /*from*/,
        address /*to*/,
        uint256 /*startTokenId*/,
        uint256 /*quantity*/
    ) internal view virtual returns (bool) {
        return true;
    }

    function _checkTransferable (
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal view virtual {
        if (!_isTransferable(from, to, startTokenId, quantity)) revert TransferForNotAllowedToken();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable diamond facet contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */

import {AntiScamInitializableStorage} from "./AntiScamInitializableStorage.sol";

abstract contract AntiScamInitializable {
    using AntiScamInitializableStorage for AntiScamInitializableStorage.Layout;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializerAntiScam() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(
            AntiScamInitializableStorage.layout()._initializing
                ? _isConstructor()
                : !AntiScamInitializableStorage.layout()._initialized,
            'AntiScamInitializable: contract is already initialized'
        );

        bool isTopLevelCall = !AntiScamInitializableStorage.layout()._initializing;
        if (isTopLevelCall) {
            AntiScamInitializableStorage.layout()._initializing = true;
            AntiScamInitializableStorage.layout()._initialized = true;
        }

        _;

        if (isTopLevelCall) {
            AntiScamInitializableStorage.layout()._initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializingAntiScam() {
        require(
            AntiScamInitializableStorage.layout()._initializing,
            'AntiScamInitializable: contract is not initializing'
        );
        _;
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base storage for the  initialization function for upgradeable diamond facet contracts
 **/

library AntiScamInitializableStorage {
    struct Layout {
        /*
         * Indicates that the contract has been initialized.
         */
        bool _initialized;
        /*
         * Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("AntiScam.contracts.storage.initializable.facet");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./RestrictApprove/RestrictApprove.sol";
import "./Lockable/WalletLockable.sol";

abstract contract AntiScamWallet is RestrictApprove, WalletLockable {

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================
    /*
    function _initializeAntiScam() internal virtual override(RestrictApprove, WalletLockable) {
        RestrictApprove._initializeAntiScam();
        WalletLockable._initializeAntiScam();
    }
    */
    function __AntiScamWallet_init() internal onlyInitializingAntiScam {
        __AntiScamWallet_init_unchained();
    }

    function __AntiScamWallet_init_unchained() internal onlyInitializingAntiScam {
        __RestrictApprove_init_unchained();
        __WalletLockable_init_unchained();
        
    }

    function _isTokenApprovable (address transferer, uint256 tokenId) 
        internal
        view
        virtual
        override(RestrictApprove, WalletLockable)
        returns (bool)
    {
        return RestrictApprove._isTokenApprovable(transferer, tokenId) &&
            WalletLockable._isTokenApprovable(transferer, tokenId);
    }

    function _isWalletApprovable(address transferer, address holder)
        internal
        view
        virtual
        override(RestrictApprove, WalletLockable) 
        returns (bool)
    {
        return RestrictApprove._isWalletApprovable(transferer, holder) &&
            WalletLockable._isWalletApprovable(transferer, holder);
    }

    function _isTransferable (
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal view virtual override(AntiScamAbstract, WalletLockable)  returns (bool) {
        return WalletLockable._isTransferable(from, to, startTokenId, quantity);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {LockStatus} from "./storage/LockableStorage.sol";

interface IWalletLockable {

    /**
     * @dev Emit event when wallet lock status is changed.
     */
    event WalletLockChanged(address indexed holder, address indexed operator, LockStatus lockStatus);

    /**
     * @dev 
     */
    function lockEnabled() external view returns (bool);

    function defaultLock() external view returns (LockStatus);

    function contractLock() external view returns (LockStatus);

    function walletLock(address holder) external view returns (LockStatus);

    /**
     * @dev Set lock status of self wallet.
     */
    function setWalletLock(LockStatus lockStatus) external;

    /**
     * @dev Set default lock status.
     */
    function setDefaultLock(LockStatus lockStatus) external;

    /**
     * @dev Set contract lock status.
     */
    function setContractLock(LockStatus lockStatus) external;

    /**
     * @dev Returns which specified token is locked.
     */
    function isTokenLocked(uint256 tokenId) external view returns (bool);
    
    /**
     * @dev Return which specified holder is locked.
     */
    function isWalletLocked(address holder) external view returns (bool);
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title Upgradeable WalletLockable
 * @author 0xedy
 * 
 */

import "../AntiScamInitializable.sol";
import "./storage/LockableStorage.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "contract-allow-list/contracts/proxy/interface/IContractAllowListProxy.sol";
import "./IWalletLockable.sol";
import "../AntiScamAbstract.sol";

abstract contract WalletLockable is AntiScamAbstract, AntiScamInitializable, IWalletLockable {
    using LockableStorage for LockableStorage.Layout;

    // 
    error TransferForLockedToken();

    // defualtLock cannot be set "Unset"
    error UnsetForDefaultLock();

    // contractLock cannot be set "Unset"
    error UnsetForContractLock();

    // Address Zero error
    error LockToZeroAddress();

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================
    /*
    function _initializeAntiScam() internal virtual override {
        LockableStorage.layout().lockEnabled = true;
        LockableStorage.layout().defaultLock = LockStatus.UnLock;
        LockableStorage.layout().contractLock  = LockStatus.UnLock;
    }
    */
    function __WalletLockable_init() internal onlyInitializingAntiScam {
        __WalletLockable_init_unchained();
    }

    function __WalletLockable_init_unchained() internal onlyInitializingAntiScam {
        LockableStorage.layout().lockEnabled = true;
        LockableStorage.layout().defaultLock = LockStatus.UnLock;
        LockableStorage.layout().contractLock  = LockStatus.UnLock;
    }

    // =============================================================
    //                        IWalletLockable
    // =============================================================
    function lockEnabled() external view returns (bool) {
        return LockableStorage.layout().lockEnabled;
    }

    function defaultLock() external view returns (LockStatus) {
        return LockableStorage.layout().defaultLock;
    }

    function contractLock() external view returns (LockStatus) {
        return LockableStorage.layout().contractLock;
    }

    function walletLock(address holder) external view returns (LockStatus) {
        return LockableStorage.layout().walletLock[holder];
    }

    function isTokenLocked(uint256 tokenId) public view virtual override returns (bool) {
        if (LockableStorage.layout().lockEnabled) {
            if (LockableStorage.layout().contractLock == LockStatus.Lock){
                return true;
            }
            address holder = _callOwnerOf(tokenId);
            if (_isWalletLocked(holder)) {
                return true;
            }
        }
        return false;   
    }

    function isWalletLocked(address holder) public view virtual override returns (bool) {
        if (LockableStorage.layout().lockEnabled) {
            if (LockableStorage.layout().contractLock == LockStatus.Lock){
                return true;
            }
            if (_isWalletLocked(holder)) {
                return true;
            }
        }
        return false;   

    }

    function _isWalletLocked(address holder) internal view virtual returns (bool) {
        // copy wallet lock status from storage to stack
        LockStatus walletLock_ = LockableStorage.layout().walletLock[holder];
        // When WalletLock, return true
        if (walletLock_ == LockStatus.Lock) {
            return true;
        } 
        if (walletLock_ == LockStatus.UnSet) {
            if (LockableStorage.layout().defaultLock == LockStatus.Lock) {
                return true;
            }
        } 
        return false;   

    }

    // =============================================================
    //      Internal setter functions
    // =============================================================
    function _setLockEnabled(bool value) internal virtual {
        LockableStorage.layout().lockEnabled = value;
    }
    
    function _setDefaultLock(LockStatus value) internal virtual {
        if (value == LockStatus.UnSet) revert UnsetForDefaultLock();
        LockableStorage.layout().defaultLock = value;
    }
    
    function _setContractLock(LockStatus value) internal virtual {
        if (value == LockStatus.UnSet) revert UnsetForContractLock();
        LockableStorage.layout().contractLock = value;
    }
    
    function _setWalletLock(address holder, LockStatus value) internal virtual {
        if (holder == address(0)) revert LockToZeroAddress();
        LockableStorage.layout().walletLock[holder] = value;
        emit WalletLockChanged(holder, msg.sender, value);
    }
    
    // =============================================================
    //      AntiScamAbstract Override
    // =============================================================

    function _isTokenApprovable(address /*transferer*/, uint256 tokenId)
        internal
        view
        virtual
        override
        returns (bool)
    {
        return !isTokenLocked(tokenId);
    }

    function _isWalletApprovable(address /*transferer*/, address holder)
        internal
        view
        virtual
        override
        returns (bool)
    {
        return !isWalletLocked(holder);
    }

    function _isTransferable(
        address from,
        address to,
        uint256 /*startTokenId*/,
        uint256 /*quantity*/
    ) internal view virtual override returns (bool ret) {
        // If not minting nor burning:
        if (from != address(0)) {
            if (to != address(0)) {
                // Get wallet lock status
                if (isWalletLocked(from)) return false;
                // Get token lock status
                // This contract has only wallet lock, so the following procedures are skipped.
                /*
                uint256 lastTokenId = startTokenId + quantity;
                for (uint256 i = startTokenId; i < lastTokenId; ){
                    // If token locked, revert transfer.
                    if (isTokenLocked(i)) revert TransferForLockedToken();
                    unchecked {
                        ++i;
                    }
                }
                */
            }
        }
        return true;
    }

    

    // =============================================================
    //      Internal Parent Function Caller
    // =============================================================

    /**
     * @dev Parent function caller for ownerOf() of ERC721
     */
    function _callOwnerOf(uint256 tokenId) internal view virtual returns (address addr) {
        bytes memory payload;// = abi.encodeWithSignature("ownerOf(uint256)", tokenId); 
        // Prepare calldata
        assembly {
            // Set free memory
            payload := mload(0x40)
            // Shift free memory poiinter
            mstore(0x40, add(payload, 0x60))
            // Set length of calldata (selector[4bytes] + parameter[32 bytes])
            mstore(payload, 36)
            // Signature of "ownerOf(uint256)".
            let sigOwnerOf := 0x6352211e
            // Generate calldata 
            mstore(add(payload, 0x20), shl(224, sigOwnerOf))
            mstore(add(payload, 0x24), tokenId)
        }
        // Static call
        (bool success, bytes memory b) = address(this).staticcall(payload);

        // Extract return value
        if (!success) {
            revert();
        } else {
            assembly {
                addr := mload(add(b, 0x20))
            }
        }
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

enum LockStatus {
    UnSet,
    UnLock,
    Lock
}

library LockableStorage {

    struct Layout {
        // Flag of restriction by lock.
        bool lockEnabled; // = true;
        // Default lock status.
        LockStatus defaultLock; // = LockStatus.UnLock;
        // Contract lock status. If true, all tokens are locked.
        LockStatus contractLock;
        // Lock status of token ID
        mapping(uint256 => LockStatus) tokenLock;
        // Lock status of wallet address
        mapping(address => LockStatus) walletLock;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('Lockable.contracts.storage.facet');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title Upgradeable RestrictApprove with contract-allow-list
 * @author 0xedy
 * 
 */

import "../AntiScamInitializable.sol";
import "./storage/RestrictApproveStorage.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "contract-allow-list/contracts/proxy/interface/IContractAllowListProxy.sol";
import "contract-allow-list/contracts/ERC721AntiScam/restrictApprove/IERC721RestrictApprove.sol";
import "../AntiScamAbstract.sol";

abstract contract RestrictApprove is AntiScamAbstract, AntiScamInitializable, IERC721RestrictApprove {
    using RestrictApproveStorage for RestrictApproveStorage.Layout;
    using EnumerableSet for EnumerableSet.AddressSet;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================
    /*
    function _initializeAntiScam() internal virtual override {
        RestrictApproveStorage.layout().CALLevel = 1;
        RestrictApproveStorage.layout().restrictEnabled = true;
    }
    */
    function __RestrictApprove_init() internal onlyInitializingAntiScam {
        __RestrictApprove_init_unchained();
    }

    function __RestrictApprove_init_unchained() internal onlyInitializingAntiScam {
        RestrictApproveStorage.layout().CALLevel = 1;
        RestrictApproveStorage.layout().restrictEnabled = true;
    }

    // =============================================================
    //                        IERC721RestrictApprove
    // =============================================================
    function CAL() public view virtual  returns (IContractAllowListProxy) {
        return RestrictApproveStorage.layout().CAL;
    }

    function CALLevel() public view virtual  returns (uint256) {
        return RestrictApproveStorage.layout().CALLevel;
    }

    function restrictEnabled() public view virtual returns (bool) {
        return RestrictApproveStorage.layout().restrictEnabled;
    }

    // =============================================================
    //                        Internal setter functions
    // =============================================================
    function _addLocalContractAllowList(address transferer)
        internal
        virtual
    {
        RestrictApproveStorage.layout().localAllowedAddresses.add(transferer);
        emit LocalCalAdded(msg.sender, transferer);
    }

    function _removeLocalContractAllowList(address transferer)
        internal
        virtual
    {
        RestrictApproveStorage.layout().localAllowedAddresses.remove(transferer);
        emit LocalCalRemoved(msg.sender, transferer);
    }

    function _setCALLevel(uint256 value)
        internal
        virtual
    {
        RestrictApproveStorage.layout().CALLevel = value;
        emit CalLevelChanged(msg.sender, value);
    }

    function _setCAL(address calAddress)
        internal
        virtual
    {
        RestrictApproveStorage.layout().CAL = IContractAllowListProxy(calAddress);
    }

    function _setRestrictEnabled(bool enabled)
        internal
        virtual
    {
        RestrictApproveStorage.layout().restrictEnabled = enabled;
    }
    // =============================================================
    //                        IERC721RestrictApprove
    // =============================================================
    function getLocalContractAllowList()
        public
        virtual
        view
        returns(address[] memory)
    {
        return RestrictApproveStorage.layout().localAllowedAddresses.values();
    }

    // =============================================================
    //                        Allowed status
    // =============================================================
    function isLocalAllowed(address transferer)
        public
        view
        virtual
        returns (bool)
    {
        return RestrictApproveStorage.layout().localAllowedAddresses.contains(transferer);
    }

    function isAllowed(address transferer)
        public
        view
        virtual
        returns (bool)
    {
        if (!RestrictApproveStorage.layout().restrictEnabled) {
            return true;
        }

        return isLocalAllowed(transferer) || RestrictApproveStorage.layout().CAL.isAllowed(
                transferer, 
                RestrictApproveStorage.layout().CALLevel
        );
    }

    // =============================================================
    //      AntiScam Approve logic function
    // =============================================================

    function _isTokenApprovable(address transferer, uint256 /*tokenId*/)
        internal
        view
        virtual
        override
        returns (bool)
    {
        return isAllowed(transferer);
    }

    function _isWalletApprovable(address transferer, address /*holder*/)
        internal
        view
        virtual
        override
        returns (bool)
    {
        return isAllowed(transferer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "contract-allow-list/contracts/proxy/interface/IContractAllowListProxy.sol";

library RestrictApproveStorage {

    struct Layout {
        // CAL Proxy address
        IContractAllowListProxy CAL;
        // stores local allowed addresses
        EnumerableSet.AddressSet localAllowedAddresses;
        // flag of restriction by CAL
        bool restrictEnabled;// = true;
        // stores CAL restriction level
        uint256 CALLevel;// = 1;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('RestrictApprove.contracts.storage.facet');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
/**
  ______ _____   _____ ______ ___  __ _  _  _ 
 |  ____|  __ \ / ____|____  |__ \/_ | || || |
 | |__  | |__) | |        / /   ) || | \| |/ |
 |  __| |  _  /| |       / /   / / | |\_   _/ 
 | |____| | \ \| |____  / /   / /_ | |  | |   
 |______|_|  \_\\_____|/_/   |____||_|  |_|   

 - github: https://github.com/estarriolvetch/ERC721Psi
 - npm: https://www.npmjs.com/package/erc721psi
                                          
 */

/// @author 0xedy derived from original ERC721Psi v0.7.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "solidity-bits/contracts/BitMaps.sol";

///////////////////////////////////////////////////////////////////////////////////////////////
// Injection code to access private storage variables as internal
struct Uint256 {
    uint256 value;
}
// End of injection code
///////////////////////////////////////////////////////////////////////////////////////////////

contract ERC721PsiUpgradeable is Initializable, ContextUpgradeable, 
    ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap private _batchHead;

    string private _name;
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) internal _owners;
    uint256 private _currentIndex;

    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721Psi_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721Psi_init_unchained(name_, symbol_);
    }

    function __ERC721Psi_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////
    // Injection code to access private storage variables as internal
    /**
     * @dev Returns _batchHead as storage.
     */
    function _batchHead_() internal pure returns (BitMaps.BitMap storage s) {
        assembly {
            s.slot := _batchHead.slot
        }
    }
    /**
     * @dev Returns _currentIndex as storage.
     */
    function _currentIndex_() internal pure returns (Uint256 storage s) {
        assembly {
            s.slot := _currentIndex.slot
        }
    }
    // End of injection code
    ///////////////////////////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////////////////////////
    // Adding virtual to function
    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal pure virtual returns (uint256) {
        // It will become modifiable in the future versions
        return 0;
    }
    // End of adding virtual to function
    ///////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        return _currentIndex - _startTokenId();
    }


    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            interfaceId == type(IERC721EnumerableUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) 
        public 
        view 
        virtual 
        override 
        returns (uint) 
    {
        require(owner != address(0), "ERC721Psi: balance query for the zero address");

        uint count;
        for( uint i = _startTokenId(); i < _nextTokenId(); ++i ){
            if(_exists(i)){
                if( owner == ownerOf(i)){
                    ++count;
                }
            }
        }
        return count;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        (address owner, ) = _ownerAndBatchHeadOf(tokenId);
        return owner;
    }

    function _ownerAndBatchHeadOf(uint256 tokenId) internal view returns (address owner, uint256 tokenIdBatchHead){
        require(_exists(tokenId), "ERC721Psi: owner query for nonexistent token");
        tokenIdBatchHead = _getBatchHead(tokenId);
        owner = _owners[tokenIdBatchHead];
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Psi: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }


    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721Psi: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721Psi: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721Psi: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721Psi: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Psi: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Psi: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, 1,_data),
            "ERC721Psi: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId < _nextTokenId();
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721Psi: operator query for nonexistent token"
        );
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, "");
    }

    
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        uint256 startTokenId = _nextTokenId();
        _mint(to, quantity);
        require(
            _checkOnERC721Received(address(0), to, startTokenId, quantity, _data),
            "ERC721Psi: transfer to non ERC721Receiver implementer"
        );
    }


    function _mint(
        address to,
        uint256 quantity
    ) internal virtual {
        uint256 nextTokenId = _nextTokenId();
        
        require(quantity > 0, "ERC721Psi: quantity must be greater 0");
        require(to != address(0), "ERC721Psi: mint to the zero address");
        
        _beforeTokenTransfers(address(0), to, nextTokenId, quantity);
        _currentIndex += quantity;
        _owners[nextTokenId] = to;
        _batchHead.set(nextTokenId);
        _afterTokenTransfers(address(0), to, nextTokenId, quantity);
        
        // Emit events
        for(uint256 tokenId=nextTokenId; tokenId < nextTokenId + quantity; tokenId++){
            emit Transfer(address(0), to, tokenId);
        } 
    }


    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        (address owner, uint256 tokenIdBatchHead) = _ownerAndBatchHeadOf(tokenId);

        require(
            owner == from,
            "ERC721Psi: transfer of token that is not own"
        );
        require(to != address(0), "ERC721Psi: transfer to the zero address");

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);   

        uint256 nextTokenId = tokenId + 1;

        if(!_batchHead.get(nextTokenId) &&  
            nextTokenId < _nextTokenId()
        ) {
            _owners[nextTokenId] = from;
            _batchHead.set(nextTokenId);
        }

        _owners[tokenId] = to;
        if(tokenId != tokenIdBatchHead) {
            _batchHead.set(tokenId);
        }

        emit Transfer(from, to, tokenId);

        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param startTokenId uint256 the first ID of the tokens to be transferred
     * @param quantity uint256 amount of the tokens to be transfered.
     * @param _data bytes optional data to send along with the call
     * @return r bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity,
        bytes memory _data
    ) private returns (bool r) {
        if (to.isContract()) {
            r = true;
            for(uint256 tokenId = startTokenId; tokenId < startTokenId + quantity; tokenId++){
                try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                    r = r && retval == IERC721Receiver.onERC721Received.selector;
                } catch (bytes memory reason) {
                    if (reason.length == 0) {
                        revert("ERC721Psi: transfer to non ERC721Receiver implementer");
                    } else {
                        assembly {
                            revert(add(32, reason), mload(reason))
                        }
                    }
                }
            }
            return r;
        } else {
            return true;
        }
    }

    function _getBatchHead(uint256 tokenId) internal view returns (uint256 tokenIdBatchHead) {
        tokenIdBatchHead = _batchHead.scanForward(tokenId); 
    }

    
    function totalSupply() public virtual view returns (uint256) {
        return _totalMinted();
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * This function is compatiable with ERC721AQueryable.
     */
    function tokensOfOwner(address owner) external view virtual returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                if (_exists(i)) {
                    if (ownerOf(i) == owner) {
                        tokenIds[tokenIdsIdx++] = i;
                    }
                }
            }
            return tokenIds;   
        }
    }


    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
/**
  ______ _____   _____ ______ ___  __ _  _  _ 
 |  ____|  __ \ / ____|____  |__ \/_ | || || |
 | |__  | |__) | |        / /   ) || | \| |/ |
 |  __| |  _  /| |       / /   / / | |\_   _/ 
 | |____| | \ \| |____  / /   / /_ | |  | |   
 |______|_|  \_\\_____|/_/   |____||_|  |_|   
                                              
                                            
 */
/// @author 0xedy derived from original ERC721Psi v0.7.0

pragma solidity ^0.8.0;

import "solidity-bits/contracts/BitMaps.sol";
import "../ERC721PsiUpgradeable.sol";


abstract contract ERC721PsiBurnableUpgradeable is ERC721PsiUpgradeable {
    using BitMaps for BitMaps.BitMap;
    BitMaps.BitMap private _burnedToken;
    // modification for savinge gas
    uint256 internal _burnCounter;

    ///////////////////////////////////////////////////////////////////////////////////////////////
    // Injection code to access private storage variables as internal
    /**
     * @dev Returns _burnedToken as storage.
     */
    function _burnedToken_() internal pure returns (BitMaps.BitMap storage s) {
        assembly {
            s.slot := _burnedToken.slot
        }
    }
    // End of injection code
    ///////////////////////////////////////////////////////////////////////////////////////////////


    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address from = ownerOf(tokenId);
        _beforeTokenTransfers(from, address(0), tokenId, 1);
        _burnedToken.set(tokenId);
        
        emit Transfer(from, address(0), tokenId);

        _afterTokenTransfers(from, address(0), tokenId, 1);

        // modification for savinge gas
        unchecked {
            ++_burnCounter;
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view override virtual returns (bool){
        if(_burnedToken.get(tokenId)) {
            return false;
        } 
        return super._exists(tokenId);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // return _totalMinted() - _burned();
        // modification for savinge gas
        return _totalMinted() - _burnCounter;
    }

    /**
     * @dev Returns number of token burned.
     */
    function _burned() internal view returns (uint256 burned){
        // modification for savinge gas
        return _burnCounter;
        /*
        uint256 startBucket = _startTokenId() >> 8;
        uint256 lastBucket = (_nextTokenId() >> 8) + 1;

        for(uint256 i=startBucket; i < lastBucket; i++) {
            uint256 bucket = _burnedToken.getBucket(i);
            burned += _popcount(bucket);
        }
        */
    }

    /**
     * @dev Returns number of set bits.
     */
    function _popcount(uint256 x) private pure returns (uint256 count) {
        unchecked{
            for (count=0; x!=0; count++)
                x &= x - 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @notice Gas optimized airdrop extension with SSTORE2 technique for ERC721Psi Upgradeable.
/// @author 0xedy

import "../ERC721Psi/ERC721PsiUpgradeable.sol";
import "./storage/ERC721PsiAirdropStorage.sol";
import "solidity-bits/contracts/BitMaps.sol";
import "../libs/ImmutableArray.sol";

abstract contract ERC721PsiAirdropUpgradeable is ERC721PsiUpgradeable {
    using ERC721PsiAirdropStorage for ERC721PsiAirdropStorage.Layout;
    using BitMaps for BitMaps.BitMap;
    using ImmutableArray for address;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    /// @dev constant variable of Zero Address.
    address private constant _ZERO_ADDRESS = address(0);

    /// @dev Pointer should not be Zero Address.
    error SetPointerAsZeroAddress();
    /// @dev Pointers length should not be zero.
    error SetNoPointer();
    /// @dev Pointers length should not be under max of uint16.
    error SetExceededPointers();
    /// @dev Pointer cannot be overrided after airdroped.
    error OverrideAirdroppedPointer();
    /// @dev There is no pointers which are not airdropped.
    error UnairdroppedPointersNonExistent();
    /// @dev Specified function parameter is not valid.
    error InvalidParameter();
    /// @dev Specified pointer is not Immutable Array.
    error InvalidArrayPointer();
    /// @dev `addressLengthInPointer` can only be set once.
    error AddressLengthInPointerAlreadySet();
    /// @dev Address length should be non-zero
    error ZeroAddressLength();
    /// @dev Address length should be match with `addressLengthInPointer`
    error InvalidAddressLength(uint256 index);
    /// Airdrop should be done continously but the state is incontinous.
    error AirdropConsistencyBroken();
    /// @dev Specified `tokenId` is not existent.
    error NonExistentTokenId(uint256 tokenId);
    /// @dev Airdrop to Zero Address
    error AirdropZeroAddress(uint256 tokenId);
    /// @dev Transfer of token that is not own.
    error TransferForNotOwnToken();
    /// @dev Transfer of token to zero address.
    error TransferToZeroAddress();

    // =============================================================
    //     CONSTRUCTOR
    // =============================================================
    function __ERC721PsiAirdrop_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721Psi_init_unchained(name_, symbol_);
        __ERC721PsiAirdrop_init_unchain();
    }

    function __ERC721PsiAirdrop_init_unchain() internal onlyInitializing {
    }

    // =============================================================
    //     INTERNAL SETTER FUNCTIONS
    // =============================================================
    function _addAirdropListPointers(address[] memory pointers) internal virtual {
        uint256 len = pointers.length;
        if (len == 0) revert SetNoPointer();
        if (len > type(uint16).max) revert SetExceededPointers();
        for (uint256 i; i < len;) {
            if (pointers[i] == address(0)) revert SetPointerAsZeroAddress();
            ERC721PsiAirdropStorage.layout().airdropListPointers.push(pointers[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _updateAirdropListPointer(uint256 index, address pointer) internal virtual {
        if (pointer == address(0)) revert SetPointerAsZeroAddress();
        // Airdroped index cannot be changed.
        if (index < uint256(ERC721PsiAirdropStorage.layout().nextPointerIndex))
            revert OverrideAirdroppedPointer();
        ERC721PsiAirdropStorage.layout().airdropListPointers[index] = pointer;
    }

    function _setAddressLengthInPointer(uint16 value) internal virtual {
        if (ERC721PsiAirdropStorage.layout().addressLengthInPointer != 0)
            revert AddressLengthInPointerAlreadySet();
        if (value > 1228) revert InvalidParameter();
        if (value == 0) revert InvalidParameter();
        ERC721PsiAirdropStorage.layout().addressLengthInPointer = value;
    }

    // =============================================================
    //     PUBLIC GETTER FUNCTIONS
    // =============================================================
    function startAirdropIndex() public view virtual returns (uint32) {
        return ERC721PsiAirdropStorage.layout().startAirdropIndex;
    }

    function addressLengthInPointer() public view virtual returns (uint16) {
        return ERC721PsiAirdropStorage.layout().addressLengthInPointer;
    }

    function airdropListPointers(uint256 index) public view virtual returns (address) {
        return ERC721PsiAirdropStorage.layout().airdropListPointers[index];
    }

    function nextPointerIndex() public view virtual returns (uint16) {
        return ERC721PsiAirdropStorage.layout().nextPointerIndex;
    }

    function airdropListPointersLength() external view virtual returns (uint256) {
        return ERC721PsiAirdropStorage.layout().airdropListPointers.length;
    }

    // =============================================================
    //     AIRDROP MINT FUNCTION
    // =============================================================
    /**
     * @dev Internal airdrop mint function with airdrop list pointers
     * @param airdropPointerCount Count of pointers to be airdroped
     */
    function _airdropMint(uint256 airdropPointerCount) internal virtual {
        // If count is 0, revert.
        if (airdropPointerCount == 0) revert InvalidParameter();

        uint256 currentPointerIndex_ = uint256(ERC721PsiAirdropStorage.layout().nextPointerIndex);
        uint256 totalPointers = ERC721PsiAirdropStorage.layout().airdropListPointers.length;
        // If there are no airdropped pointers, revert.
        if (currentPointerIndex_ + 1 > totalPointers) revert UnairdroppedPointersNonExistent();
        // If last pointer index is out of bound, override index
        if (currentPointerIndex_ + airdropPointerCount > totalPointers) {
            airdropPointerCount = totalPointers - currentPointerIndex_;
        }
        // Preserve and iterate tokneId
        uint256 currentIndex_ = _currentIndex_().value;
        // Address length in pointer at stuck
        uint256 addressLengthInPointer_ = ERC721PsiAirdropStorage.layout().addressLengthInPointer;

        if (currentPointerIndex_ > 0) {
            // If airdrop has already started, currentIndex should be equal to estimated token ID.
            if (currentIndex_ != 
                ERC721PsiAirdropStorage.layout().startAirdropIndex
                + addressLengthInPointer_ * currentPointerIndex_
            ) revert AirdropConsistencyBroken();
        } else {
            // If airdrop does not start yet, set start airdrop tokenID as currentIndex.
            ERC721PsiAirdropStorage.layout().startAirdropIndex = uint32(currentIndex_);
        }

        // Address count contained in a pointer
        uint256 addressCount;
        // Return value from array property
        uint256 format;
        // Return value from array property
        uint256 codeSize;
        // Current processed pointer
        address currentPointer;
        // Owner for airdrop
        address currentOwner;

        // Until here, gas used : about 5200-5500 (optimizer 200)

        // Outer loop for address list
        for (uint256 i; i < airdropPointerCount; ) {
            // Get pointer
            currentPointer = ERC721PsiAirdropStorage.layout().airdropListPointers[currentPointerIndex_];
            // Read property of ImmutableArray
            (format, addressCount, codeSize) = currentPointer.readProperty();
            // Check consistency
            if (format != 20) revert InvalidArrayPointer();
            if (addressCount == 0) revert ZeroAddressLength();
            // Check address count
            if (currentPointerIndex_ < airdropPointerCount -1) {
                if (addressCount != addressLengthInPointer_) revert InvalidAddressLength(currentPointerIndex_);
            }

            // In outer loop, until here, gas used : about 1000 (optimizer 200)

            // Inner loop for token ID to emit `Transfer`.
            for (uint256 j; j < addressCount; ) { 
                currentOwner = currentPointer.readAddress_unchecked(j);
                if (currentOwner != _ZERO_ADDRESS) {
                    // This assembly emitting saves gas 39 and uses 2008 in each token.
                    assembly {
                        // Emit the `Transfer` event.
                        log4(
                            0, // Start of data (0, since no data).
                            0, // End of data (0, since no data).
                            _TRANSFER_EVENT_SIGNATURE, // Signature.
                            0x00, // `from`.
                            currentOwner, // `to`.
                            currentIndex_ // `tokenId`.
                        )
                    }
                } else {
                    _beforeAirdropZeroAddress(currentIndex_);
                }
                // increments
                unchecked {
                    ++j;
                    ++currentIndex_;
                }
            }
            // increments
            unchecked {
                ++i;
                ++currentPointerIndex_;
            }

        }
        // Set batchHead to all airdropped tokens
        //_batchHead_().setBatch(startIndex_, currentIndex_ - startIndex_);
        // Update currentIndex
        _currentIndex_().value = currentIndex_;
        // Update nextPointerIndex
        ERC721PsiAirdropStorage.layout().nextPointerIndex = uint16(currentPointerIndex_);
    }

    /**
     * @dev Internal before processing when token is airdropped to zero address.
     * Without burn, airdropping to zero address should be revert.
     * @param tokenId Airdropping token ID to zero address
     */
    function _beforeAirdropZeroAddress(uint256 tokenId) internal virtual {
        revert AirdropZeroAddress(tokenId);
    }

    // =============================================================
    //     ERC721Psi Override function
    // =============================================================
    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) 
        internal 
        virtual 
        override
    {
        // Since this function is always called with quantity 1 when not minting,
        // only check bit of `startTokenId`.
        if (from != _ZERO_ADDRESS ) {
            if (!ERC721PsiAirdropStorage.layout().transferred.get(startTokenId)) {
                // If not transferred after airdropped, set bit as trasnferred.
                ERC721PsiAirdropStorage.layout().transferred.set(startTokenId);
            }
        } else {
            // If minting, set all bits as transferred.
            ERC721PsiAirdropStorage.layout().transferred.setBatch(startTokenId, quantity);
        }
        // Call parent function.
        super._afterTokenTransfers(from, to, startTokenId, quantity);
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        // Calculate airdropIndex because there is difference between it and token ID.
        // If not transferred, 
        if (!ERC721PsiAirdropStorage.layout().transferred.get(tokenId)) {
            // Check exisitence
            if (!_exists(tokenId)) revert NonExistentTokenId(tokenId);
            uint256 addressLength = uint256(ERC721PsiAirdropStorage.layout().addressLengthInPointer);
            uint256 nextPointerIndex_ = ERC721PsiAirdropStorage.layout().nextPointerIndex;
            uint256 airdropIndex = _getAirdropIndex(tokenId);
            uint256 pointerIndex = airdropIndex / addressLength;
            unchecked{
                // Check airdropped. If not, the airdrop consistency is broken.
                if ((pointerIndex + 1) > nextPointerIndex_) revert AirdropConsistencyBroken();
                uint256 addressIndex = airdropIndex % addressLength;
                return ERC721PsiAirdropStorage.layout()
                    .airdropListPointers[pointerIndex].readAddress_unchecked(addressIndex);
            }
        } else {
            return super.ownerOf(tokenId);
        }
    }

    function _getAirdropIndex(uint256 tokenId) internal view virtual returns (uint256) {
        return tokenId - ERC721PsiAirdropStorage.layout().startAirdropIndex;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721PsiUpgradeable) {
        if (!ERC721PsiAirdropStorage.layout().transferred.get(tokenId)) {
            address owner = ownerOf(tokenId);

            if (owner != from) revert TransferForNotOwnToken();
            if (to == address(0)) revert TransferToZeroAddress();

            _beforeTokenTransfers(from, to, tokenId, 1);

            // Clear approvals from the previous owner
            _approve(address(0), tokenId);   

            _owners[tokenId] = to;
            _batchHead_().set(tokenId);
            ERC721PsiAirdropStorage.layout().transferred.set(tokenId);
            _afterTokenTransfers(from, to, tokenId, 1);

            emit Transfer(from, to, tokenId);
        } else {
            ERC721PsiUpgradeable._transfer(from, to, tokenId);
        }

    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @notice Gas optimized airdrop extension with SSTORE2 technique for ERC721PsiBurnable Upgradeable.
/// @author 0xedy

import "./ERC721PsiAirdropUpgradeable.sol";
import "./storage/ERC721PsiAirdropStorage.sol";
import "solidity-bits/contracts/BitMaps.sol";
import "../ERC721Psi/extension/ERC721PsiBurnableUpgradeable.sol";

abstract contract ERC721PsiBurnableAirdropUpgradeable is ERC721PsiBurnableUpgradeable, ERC721PsiAirdropUpgradeable {
    using ERC721PsiAirdropStorage for ERC721PsiAirdropStorage.Layout;
    using BitMaps for BitMaps.BitMap;

    // =============================================================
    //     CONSTRUCTOR
    // =============================================================
    function __ERC721PsiBurnableAirdrop_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721Psi_init_unchained(name_, symbol_);
        __ERC721PsiBurnableAirdrop_init_unchain();
    }

    function __ERC721PsiBurnableAirdrop_init_unchain() internal onlyInitializing {
    }

    // =============================================================
    //     ERC721PsiAirdrop Override function
    // =============================================================
    /**
     * @dev This override for the custom ERC721PsiBurnable v0.7.0 to save the gas of calling totalSupply().
     * If use the original one, eliminate `++burnCounter;` command.
     */
    function _beforeAirdropZeroAddress(uint256 tokenId) internal virtual override {
        _burnedToken_().set(tokenId);
        unchecked{
            ++_burnCounter;
        }
        ERC721PsiAirdropStorage.layout().transferred.set(tokenId);
    }

    // =============================================================
    //     ERC721Psi Override functions
    // =============================================================
    function _exists(uint256 tokenId) 
        internal 
        view 
        virtual 
        override(ERC721PsiUpgradeable, ERC721PsiBurnableUpgradeable) 
        returns (bool) 
    {
        return ERC721PsiBurnableUpgradeable._exists(tokenId);
    }

    function totalSupply()
        public 
        view 
        virtual 
        override(ERC721PsiUpgradeable, ERC721PsiBurnableUpgradeable) 
        returns (uint256) 
    {
        return ERC721PsiBurnableUpgradeable.totalSupply();
    }

    function ownerOf(uint256 tokenId) 
        public 
        view 
        virtual 
        override(ERC721PsiUpgradeable, ERC721PsiAirdropUpgradeable) 
        returns (address)
    {
        return ERC721PsiAirdropUpgradeable.ownerOf(tokenId);
    }
    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) 
        internal 
        virtual 
        override(ERC721PsiUpgradeable, ERC721PsiAirdropUpgradeable)
    {
        ERC721PsiAirdropUpgradeable._afterTokenTransfers(from, to, startTokenId, quantity);
    }

    function _transfer(address from, address to, uint256 tokenId) 
        internal 
        virtual 
        override(ERC721PsiUpgradeable, ERC721PsiAirdropUpgradeable)
    {
        ERC721PsiAirdropUpgradeable._transfer(from, to, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "solidity-bits/contracts/BitMaps.sol";

library ERC721PsiAirdropStorage {
    using BitMaps for BitMaps.BitMap;

    struct Layout {
        // total supply by airdrop.
        uint32 startAirdropIndex;
        // Address length in pointer. Only last pointer is allowed it is less than this legnth.
        uint16 addressLengthInPointer;
        // Next unairdroped index of airdrop list pointers. Manipulating pointers is irreversible.
        uint16 nextPointerIndex;
        // Pointers of the list of address list contract. Each contract should have the address list for airdrop.
        // The Format of the list follows ImmutableArray. 
        address[] airdropListPointers;
        // A flag indicating that the token ID has already been transferred after airdrop.
        BitMaps.BitMap transferred;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('ERC721PsiAirdrop.contracts.storage.facet');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSE
/*

*/
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
//import {IERC2981Upgradeable, ERC2981Upgradeable} 
//    from "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "./libs/ERC2981Upgradeable.sol";
import "./ERC721PsiAirdrop/ERC721PsiBurnableAirdropUpgradeable.sol";
import "./AntiScam/AntiScamWallet.sol";
import "closedsea/src/OperatorFilterer.sol";
import "./storage/TAGStorage.sol";
import "./descriptor/IDescriptor.sol";

contract Mock is 
    Initializable, 
    UUPSUpgradeable, 
    AccessControlUpgradeable,
    OwnableUpgradeable,
    ERC721PsiBurnableAirdropUpgradeable, 
    OperatorFilterer,
    AntiScamWallet,
    ERC2981Upgradeable
{
    using TAGStorage for TAGStorage.Layout;

    ///////////////////////////////////////////////////////////////////////////
    // Constants
    ///////////////////////////////////////////////////////////////////////////

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    uint256 public constant MAX_SUPPLY = 10000;

    address private constant ADDRESS_OWNER = 0x6d8a59858211cc3ffA87e0e84cd1a648072082d1;

    error NotPermittedOperationExceptHolder();
    error NotPermittedOperationExceptAdmin();
    error NoTokenIdToBurn();
    error MintExceedingMaxSupply();

    ///////////////////////////////////////////////////////////////////////////
    // UUPS constructor and initializer and upgrade function
    ///////////////////////////////////////////////////////////////////////////

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer initializerAntiScam{
        // Call initilizing functions
        __ERC721PsiBurnableAirdrop_init("Mock Airdrop NFT", "MAN");
        __UUPSUpgradeable_init();
        __Ownable_init();       // Transfer ownership for msg.sender in init
        __AccessControl_init();
        __AntiScamWallet_init();
        __ERC2981_init();
        
        // Set airdrop configuration
        _setAddressLengthInPointer(1200);

        // OpenSea Filterer by ClosedSea
        _registerForOperatorFiltering();
        TAGStorage.layout().operatorFilteringEnabled = true;

        // Set royalty receiver to the project owner,
        // at 10% (default denominator is 10000).
        _setDefaultRoyalty(ADDRESS_OWNER, 1000);

        // Grant roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, ADDRESS_OWNER);
        _grantRole(UPGRADER_ROLE, msg.sender);

        // Set CAL Proxy for mumbai
        _setCAL(0xAB575A53B5Ad49B7ff7424B43168C2ddC6cB9e4d);

        // Set ContractLock as Lock until finish to airdrop
        _setContractLock(LockStatus.Lock);

    }

    function _authorizeUpgrade(address) internal override onlyRole(UPGRADER_ROLE) {}

    ///////////////////////////////////////////////////////////////////////////
    // Access Control modifiers
    ///////////////////////////////////////////////////////////////////////////

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert NotPermittedOperationExceptAdmin();
        _;
    }

    ///////////////////////////////////////////////////////////////////////////
    // ERC721 Internal mint logic override
    ///////////////////////////////////////////////////////////////////////////

    /// @dev Override to check minting over maximum supply.
    function _mint(address to, uint256 quantity) internal virtual override {
        if (totalSupply() + quantity > MAX_SUPPLY) revert MintExceedingMaxSupply();
        super._mint(to, quantity);
    }

    ///////////////////////////////////////////////////////////////////////////
    // ERC721 Mint / Burn
    ///////////////////////////////////////////////////////////////////////////
    function airdropMint(uint256 airdropPointerCount)
        external
        onlyAdmin
    {
        _airdropMint(airdropPointerCount);
    }
    function externalSafeMint(address to, uint256 quantity) 
        external 
        onlyRole(MINTER_ROLE) 
    {
        _safeMint(to, quantity);
    }

    function externalMint(address to, uint256 quantity) 
        external 
        onlyRole(MINTER_ROLE) 
    {
        _mint(to, quantity);
    }

    function externalBurn(uint256 tokenId) 
        external 
        onlyRole(BURNER_ROLE) 
    {
        _burn(tokenId);
    }

    function externalBurnBatch(uint256[] memory tokenIds) 
        external 
        onlyRole(BURNER_ROLE) 
    {
        uint256 len = tokenIds.length;
        if (len == 0) revert NoTokenIdToBurn();
        for (uint256 i; i < len; ){
            _burn(tokenIds[i]);
            unchecked{
                ++i;
            }
        }
    }

    ///////////////////////////////////////////////////////////////////////////
    // ERC721Psi Override
    ///////////////////////////////////////////////////////////////////////////
    function _startTokenId() internal pure virtual override returns (uint256) {
        return 1;
    }

    function balanceOf(address holder) 
        public 
        view 
        virtual 
        override 
        returns (uint) 
    {
        require(holder != address(0), "ERC721Psi: balance query for the zero address");

        uint256 count;
        uint256 nextTokenId = _nextTokenId();
        unchecked{
            for( uint i = _startTokenId(); i < nextTokenId; ++i ){
                if(_exists(i)){
                    if( holder == ownerOf(i)){
                        ++count;
                    }
                }
            }
        }
        return count;
    }

    /**
     * @dev Balance query function for specified range to prevent running out gas.
     * @param holder Specifies address for query
     * @param start Start token ID for query
     * @param end End token ID for query. Not include this token ID.
     */
    function balanceQuery(address holder, uint256 start, uint256 end)
        public 
        view 
        virtual 
        returns (uint) 
    {
        require(holder != address(0), "ERC721Psi: balance query for the zero address");

        uint256 count;
        uint256 nextTokenId = _nextTokenId();
        uint256 firstId = _startTokenId();
        if (start  < firstId) revert InvalidParameter();
        if (end  > nextTokenId) revert InvalidParameter();
        
        unchecked{
            for( uint i = start; i < end; ++i ){
                if(_exists(i)){
                    if( holder == ownerOf(i)){
                        ++count;
                    }
                }
            }
        }
        return count;
    }

    ///////////////////////////////////////////////////////////////////////////
    // ERC721Psi Interface to external
    ///////////////////////////////////////////////////////////////////////////
    function getStartTokenId() external pure virtual returns (uint256) {
        return _startTokenId();
    }

    ///////////////////////////////////////////////////////////////////////////
    // ERC721Psi Approve and transfer functions with ClosedSea and AntiScam
    ///////////////////////////////////////////////////////////////////////////
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) 
        internal 
        virtual 
        override
        onlyTransferable(from, to, startTokenId, quantity)
    {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function approve(address to, uint256 tokenId) 
        public 
        virtual 
        override
        onlyAllowedOperatorApproval(to)
        onlyTokenApprovable(to, tokenId)
    {
        super.approve(to, tokenId);
    }

    function isApprovedForAll(address holder, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return super.isApprovedForAll(holder, operator) && _isWalletApprovable(operator, holder);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
        onlyAllowedOperatorApproval(operator)
        onlyWalletApprovable(operator, msg.sender, approved)
    {
        super.setApprovalForAll(operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev Override parent caller for ownerOf() function directly.
     */
    function _callOwnerOf(uint256 tokenId) internal view virtual override returns (address) {
        return ownerOf(tokenId);
    }

    ///////////////////////////////////////////////////////////////////////////
    // ERC165 Override
    ///////////////////////////////////////////////////////////////////////////
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC721PsiUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            AccessControlUpgradeable.supportsInterface(interfaceId) ||
            ERC721PsiUpgradeable.supportsInterface(interfaceId) ||
            interfaceId == type(IERC721RestrictApprove).interfaceId ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    ///////////////////////////////////////////////////////////////////////////
    // ERC721PsiAirdrop Setter function
    ///////////////////////////////////////////////////////////////////////////
    function addAirdropListPointers(address[] memory pointers)
        external
        onlyAdmin
    {
        _addAirdropListPointers(pointers);
    }

    function updateAirdropListPointer(uint256 index, address pointer)
        external
        onlyAdmin
    {
        _updateAirdropListPointer(index, pointer);
    }

    ///////////////////////////////////////////////////////////////////////////
    // IERC721RestrictApprove Override
    ///////////////////////////////////////////////////////////////////////////
    /**
     * @dev Set CAL Level.
     */
    function setCALLevel(uint256 level)
        external 
        onlyAdmin
    {
        _setCALLevel(level);
    }

    /**
     * @dev Set `calAddress` as the new proxy of the contract allow list.
     */
    function setCAL(address calAddress) 
        external
        onlyAdmin
    {
        _setCAL(calAddress);
    }

    /**
     * @dev Add `transferer` to local contract allow list.
     */
    function addLocalContractAllowList(address transferer)
        external
        onlyAdmin
    {
        _addLocalContractAllowList(transferer);
    }

    /**
     * @dev Remove `transferer` from local contract allow list.
     */
    function removeLocalContractAllowList(address transferer)
        external
        onlyAdmin
    {
        _removeLocalContractAllowList(transferer);
    }

    /**
     * @dev Set which the restriction by CAL is enabled.
     */
    function setRestrictEnabled(bool value)
        external
        onlyAdmin
    {
        _setRestrictEnabled(value);
    }

    ///////////////////////////////////////////////////////////////////////////
    // WalletLockable Override
    ///////////////////////////////////////////////////////////////////////////
    /**
     * @dev Set which the lock is enabled.
     */
    function setLockEnabled(bool value) 
        external
        onlyAdmin
    {
        _setLockEnabled(value);
    }

    /**
     * @dev Set lock status of specified address.
     */
    function setWalletLock(LockStatus lockStatus) 
        external
    {
        _setWalletLock(msg.sender, lockStatus);
    }

    /**
     * @dev Set default lock status.
     */
    function setDefaultLock(LockStatus lockStatus)
        external
        onlyAdmin
    {
        _setDefaultLock(lockStatus);
    }

    /**
     * @dev Set contract lock status.
     */
    function setContractLock(LockStatus lockStatus)
        external
        onlyAdmin
    {
        _setContractLock(lockStatus);
    }

    ///////////////////////////////////////////////////////////////////////////
    // WalletLockable Admin function
    ///////////////////////////////////////////////////////////////////////////
    /**
     * @dev Unlock wallet lock. This is to prevent floor price attack by wallet lock.
     */
    function unlockWalletByAdmin(address to) 
        external
        onlyAdmin
    {
        _setWalletLock(to, LockStatus.UnLock);
    }

    ///////////////////////////////////////////////////////////////////////////
    // ERC2981 Setter function
    ///////////////////////////////////////////////////////////////////////////
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) 
        public 
        onlyAdmin 
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    ///////////////////////////////////////////////////////////////////////////
    // ClosedSea Setter functions
    ///////////////////////////////////////////////////////////////////////////
    function setOperatorFilteringEnabled(bool value) 
        public 
        onlyAdmin 
    {
        TAGStorage.layout().operatorFilteringEnabled = value;
    }

    ///////////////////////////////////////////////////////////////////////////
    // ClosedSea Override
    ///////////////////////////////////////////////////////////////////////////
    function _operatorFilteringEnabled() internal view override returns (bool) {
        return TAGStorage.layout().operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    ///////////////////////////////////////////////////////////////////////////
    // ClosedSea getter functions
    ///////////////////////////////////////////////////////////////////////////
    function operatorFilteringEnabled() external view returns (bool) {
        return TAGStorage.layout().operatorFilteringEnabled;
    }

    ///////////////////////////////////////////////////////////////////////////
    // TAG functions
    ///////////////////////////////////////////////////////////////////////////
    function descriptor() external view returns (IDescriptor) {
        return TAGStorage.layout().descriptor;
    }

    function setDescriptor(IDescriptor addr)
        external 
        onlyAdmin
    {
        TAGStorage.layout().descriptor = addr;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory uri) {
        _exists(tokenId);
        return TAGStorage.layout().descriptor.tokenURI(tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IDescriptor {
    function tokenURI(uint256 tokenId) external view returns (string memory uri);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 * 
 * 
 * Derived to eliminate unused token royalty to save contract size.
 * This uses specified storage slot for variable.
 */
abstract contract ERC2981Upgradeable is Initializable, IERC2981Upgradeable, ERC165Upgradeable {

    /// @dev keccak256(bytes("defaultRoyaltyInfo.ERC2981.storage.slot"))`
    uint256 private constant _DEFAULT_ROYALTY_INFO_SLOT = 
        0xe13efb267772d9dd1f57f287ca10777e913a634928a8a50de35000071a83d57f;

    function __ERC2981_init() internal onlyInitializing {
    }

    function __ERC2981_init_unchained() internal onlyInitializing {
    }
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    function _defaultRoyaltyInfo() internal pure returns (RoyaltyInfo storage s) {
        assembly {
            s.slot := _DEFAULT_ROYALTY_INFO_SLOT
        }
    }

    //RoyaltyInfo private _defaultRoyaltyInfo;
    //mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC2981Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981Upgradeable
     */
    function royaltyInfo(uint256 /*_tokenId*/, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _defaultRoyaltyInfo();

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo().receiver = receiver;
        _defaultRoyaltyInfo().royaltyFraction = feeNumerator;
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        _defaultRoyaltyInfo().receiver = address(0);
        _defaultRoyaltyInfo().royaltyFraction = 0;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for reading data of contract by SSTORE2 as immutable array.
/// @author 0xedy

//import "forge-std/console.sol";

library ImmutableArray {

    uint256 private constant _DATA_OFFSET = 1;
    uint256 private constant _HEADER_LENGTH = 3;
    
    uint256 private constant _BYTES_ARRAY_LENGTH_ADDRESS = 2;
    uint256 private constant _ADDRESS_SIZE_BYTES = 20;
    uint256 private constant _ADDRESS_OFFSET_BYTES = 12;
    uint256 private constant _UINT256_SIZE_BYTES = 32;

    uint256 private constant _FORMAT_BYTES = 0x40;
    error InvalidPointer();

    error InconsistentArray();

    error FormatMismatch();

    error IndexOutOfBound();
    

    /**
     * @dev Reads header and code size of immutable array.
     */
    function readProperty(address pointer) 
        internal 
        view 
        returns (uint256 format, uint256 length, uint256 codeSize) 
    {
        assembly{
            codeSize := extcodesize(pointer)
            if lt(codeSize, add(_DATA_OFFSET, _HEADER_LENGTH)) {
                // Store the function selector of `InvalidPointer()`.
                mstore(0x00, 0x11052bb4)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
        (format, length) = readProperty_unchecked(pointer);
    }

    /**
     * @dev Reads header and code size of immutable array without checking.
     */
    function readProperty_unchecked(address pointer) 
        internal 
        view 
        returns (uint256 format, uint256 length) 
    {
        /// @solidity memory-safe-assembly
        assembly {
            // reset scratch space
            mstore(0x00, 0)
            // copy data from pointer
            extcodecopy(
                pointer, 
                0, 
                _DATA_OFFSET, 
                _HEADER_LENGTH
            )
            // load header to stack
            let val := mload(0x00)
            // extract 8 bits in most left for packType
            format := shr(248, val)
            // extract next 16 bits for length
            length := shr(240, shl(8, val))
        }
    }
    function readUint256(address pointer, uint256 index) 
        internal 
        view 
        returns (uint256 ret, uint256 format, uint256 length, uint256 codeSize)
    {
        (format, length, codeSize) = readProperty(pointer);

        // Check the consistency of array and the validity of `index`.
        if (format > 32) revert FormatMismatch();
        if (format == 0) revert FormatMismatch();
        // Check the validity of `index`.
        if (index + 1 > length) revert IndexOutOfBound();
        // Check boundary
        if (_HEADER_LENGTH + length * format + _DATA_OFFSET > codeSize) revert InconsistentArray();
        // Read value as uint256
        ret = readUint256_unchecked(pointer, index, format);
    }
    
    function readUint256Next(address pointer, uint256 index, uint256 format, uint256 length) 
        internal 
        view 
        returns (uint256 ret)
    {
        // Check the validity of `index`.
        if (index + 1 > length) revert IndexOutOfBound();
        // Read value as uint256
        ret = readUint256_unchecked(pointer, index, format);
    }

    function readUint256_unchecked(address pointer, uint256 index, uint256 format) 
        internal 
        view 
        returns (uint256 ret)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // calculates start position
            let start := add(_HEADER_LENGTH, mul(format, index))
            // reset scratch space
            mstore(0x00, 0)
            // copy data from pointer
            extcodecopy(
                pointer, 
                sub(_UINT256_SIZE_BYTES, format), 
                add(start, _DATA_OFFSET), 
                format
            )
            // copy from memory to return stack
            ret := mload(0x00)
        }
    }

    /**
     * @dev Reads address at `index` in immutable array at first call in a function.
     * This function returns code size and header information from `pointer` contract.
     * Once call this, {readAddressNext} or {readAddressNext_unchecked} can be called to save gas.
     */
    function readAddress(address pointer, uint256 index) 
        internal 
        view 
        returns (address ret, uint256 length, uint256 codeSize) 
    {
        uint256 format;
        (format, length, codeSize) = readProperty(pointer);
        // Check format as address
        if (format != _ADDRESS_SIZE_BYTES) revert FormatMismatch();
        // Check the validity of `index`.
        if (index + 1 > length) revert IndexOutOfBound();
        // Check boundary
        if (_HEADER_LENGTH + length * _ADDRESS_SIZE_BYTES + _DATA_OFFSET > codeSize) revert InconsistentArray();
        // read address
        ret = readAddress_unchecked(pointer, index);
    }

    /**
     * @dev Reads address at `index` in immutable array after first call in a function.
     * This function must be provided with lenght and codeSize from the first call.
     */
    function readAddressNext(address pointer, uint256 index, uint256 length) 
        internal 
        view 
        returns (address ret) 
    {
        // Check the validity of `index`.
        if (index + 1 > length) revert IndexOutOfBound();
        // read address
        ret = readAddress_unchecked(pointer, index);
    }

    /**
     * @dev Reads address at `index` in immutable array after first call in a function.
     * This function must be provided with codeSize from the first call.
     * Also unchecking index bound to save gas.
     */
    function readAddress_unchecked(
        address pointer, 
        uint256 index
    ) internal view returns (address ret) {
        /// @solidity memory-safe-assembly
        assembly {
            // calculates start position
            let start := add(_HEADER_LENGTH, mul(_ADDRESS_SIZE_BYTES, index))
            // reset scratch space
            mstore(0x00, 0)
            // copy data from pointer
            extcodecopy(
                pointer, 
                _ADDRESS_OFFSET_BYTES, 
                add(start, _DATA_OFFSET), 
                _ADDRESS_SIZE_BYTES
            )
            // copy from memory to return stack
            ret := mload(0x00)
        }
    }

    function readBytes(address pointer, uint256 index) 
        internal 
        view 
        returns (bytes memory ret, uint256 length, uint256 codeSize)
    {
        uint256 format;
        (format, length, codeSize) = readProperty(pointer);

        // Check the consistency of array and the validity of `index`.
        if (format != _FORMAT_BYTES) revert FormatMismatch();
        // Check the validity of `index`.
        if (index + 1 > length) revert IndexOutOfBound();
        // Read last address.
        uint256 lastAddress = readUint256_unchecked(pointer, length - 1, _BYTES_ARRAY_LENGTH_ADDRESS);
        // Check size
        if (lastAddress + _DATA_OFFSET > codeSize) revert InconsistentArray();

        // read bytes data.
        ret = readBytes_unchecked(pointer, index, length);
    }

    function readBytesNext(address pointer, uint256 index, uint256 length) 
        internal 
        view 
        returns (bytes memory ret)
    {
        // Check the validity of `index`.
        if (index + 1 > length) revert IndexOutOfBound();
        // read bytes data.
        ret = readBytes_unchecked(pointer, index, length);
    }

    function readBytes_unchecked(address pointer, uint256 index, uint256 length) 
        internal 
        view 
        returns (bytes memory ret)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Read address list
            // start is the address one before index.
            // Since _HEADER_LENGTH > _BYTES_ARRAY_LENGTH_ADDRESS, 
            // start is not underflow even if index is zero.
            let start := add(
                sub(_HEADER_LENGTH, _BYTES_ARRAY_LENGTH_ADDRESS), 
                mul(index, _BYTES_ARRAY_LENGTH_ADDRESS)
            )
            // Extract list size is 2 addresses
            let size := mul(_BYTES_ARRAY_LENGTH_ADDRESS, 2)

             // reset scratch space
            mstore(0x00, 0)
            // copy address list from pointer to scratch space.
            extcodecopy(
                pointer, 
                sub(32, size), 
                add(start, _DATA_OFFSET), 
                size
            )
            // copy address list from scratch space to stack
            let list := mload(0x00)
            // Switch which index is zero.
            switch gt(index, 0) 
            case 1{
                // start is after address list.
                start := and(shr(mul(_BYTES_ARRAY_LENGTH_ADDRESS, 8), list), 0xFFFF)
            }
            default {
                // start is from lower of address list
                start := add(_HEADER_LENGTH, mul(length, _BYTES_ARRAY_LENGTH_ADDRESS))
            }
            // size = end - start
            size := sub(and(list, 0xFFFF), start)

            // Get the pointer to the free memory and allocate
            // enough 32-byte words for the data and the length of the data,
            // then copy the code to the allocated memory.
            // Masking with 0xffe0 will suffice, since contract size is less than 16 bits.
            ret := mload(0x40)
            mstore(0x40, add(ret, and(add(size, 0x3f), 0xffe0)))
            mstore(ret, size)
            mstore(add(add(ret, 0x20), size), 0) // Zeroize the last slot.
            extcodecopy(pointer, add(ret, 0x20), add(start, _DATA_OFFSET), size)
        }
    }

}

// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.4;

import "../descriptor/IDescriptor.sol";

library TAGStorage {

    struct Layout {
        bool operatorFilteringEnabled;
        IDescriptor descriptor;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('TokyoAlternativeGirls.contracts.storage.facet');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
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
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
            _functionDelegateCall(newImplementation, data);
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
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
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
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
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
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
library StorageSlotUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Optimized and flexible operator filterer to abide to OpenSea's
/// mandatory on-chain royalty enforcement in order for new collections to
/// receive royalties.
/// For more information, see:
/// See: https://github.com/ProjectOpenSea/operator-filter-registry
abstract contract OperatorFilterer {
    /// @dev The default OpenSea operator blocklist subscription.
    address internal constant _DEFAULT_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;

    /// @dev The OpenSea operator filter registry.
    address internal constant _OPERATOR_FILTER_REGISTRY = 0x000000000000AAeB6D7670E522A718067333cd4E;

    /// @dev Registers the current contract to OpenSea's operator filter,
    /// and subscribe to the default OpenSea operator blocklist.
    /// Note: Will not revert nor update existing settings for repeated registration.
    function _registerForOperatorFiltering() internal virtual {
        _registerForOperatorFiltering(_DEFAULT_SUBSCRIPTION, true);
    }

    /// @dev Registers the current contract to OpenSea's operator filter.
    /// Note: Will not revert nor update existing settings for repeated registration.
    function _registerForOperatorFiltering(address subscriptionOrRegistrantToCopy, bool subscribe)
        internal
        virtual
    {
        /// @solidity memory-safe-assembly
        assembly {
            let functionSelector := 0x7d3e3dbe // `registerAndSubscribe(address,address)`.

            // Clean the upper 96 bits of `subscriptionOrRegistrantToCopy` in case they are dirty.
            subscriptionOrRegistrantToCopy := shr(96, shl(96, subscriptionOrRegistrantToCopy))

            for {} iszero(subscribe) {} {
                if iszero(subscriptionOrRegistrantToCopy) {
                    functionSelector := 0x4420e486 // `register(address)`.
                    break
                }
                functionSelector := 0xa0af2903 // `registerAndCopyEntries(address,address)`.
                break
            }
            // Store the function selector.
            mstore(0x00, shl(224, functionSelector))
            // Store the `address(this)`.
            mstore(0x04, address())
            // Store the `subscriptionOrRegistrantToCopy`.
            mstore(0x24, subscriptionOrRegistrantToCopy)
            // Register into the registry.
            if iszero(call(gas(), _OPERATOR_FILTER_REGISTRY, 0, 0x00, 0x44, 0x00, 0x04)) {
                // If the function selector has not been overwritten,
                // it is an out-of-gas error.
                if eq(shr(224, mload(0x00)), functionSelector) {
                    // To prevent gas under-estimation.
                    revert(0, 0)
                }
            }
            // Restore the part of the free memory pointer that was overwritten,
            // which is guaranteed to be zero, because of Solidity's memory size limits.
            mstore(0x24, 0)
        }
    }

    /// @dev Modifier to guard a function and revert if the caller is a blocked operator.
    modifier onlyAllowedOperator(address from) virtual {
        if (from != msg.sender) {
            if (!_isPriorityOperator(msg.sender)) {
                if (_operatorFilteringEnabled()) _revertIfBlocked(msg.sender);
            }
        }
        _;
    }

    /// @dev Modifier to guard a function from approving a blocked operator..
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        if (!_isPriorityOperator(operator)) {
            if (_operatorFilteringEnabled()) _revertIfBlocked(operator);
        }
        _;
    }

    /// @dev Helper function that reverts if the `operator` is blocked by the registry.
    function _revertIfBlocked(address operator) private view {
        /// @solidity memory-safe-assembly
        assembly {
            // Store the function selector of `isOperatorAllowed(address,address)`,
            // shifted left by 6 bytes, which is enough for 8tb of memory.
            // We waste 6-3 = 3 bytes to save on 6 runtime gas (PUSH1 0x224 SHL).
            mstore(0x00, 0xc6171134001122334455)
            // Store the `address(this)`.
            mstore(0x1a, address())
            // Store the `operator`.
            mstore(0x3a, operator)

            // `isOperatorAllowed` always returns true if it does not revert.
            if iszero(staticcall(gas(), _OPERATOR_FILTER_REGISTRY, 0x16, 0x44, 0x00, 0x00)) {
                // Bubble up the revert if the staticcall reverts.
                returndatacopy(0x00, 0x00, returndatasize())
                revert(0x00, returndatasize())
            }

            // We'll skip checking if `from` is inside the blacklist.
            // Even though that can block transferring out of wrapper contracts,
            // we don't want tokens to be stuck.

            // Restore the part of the free memory pointer that was overwritten,
            // which is guaranteed to be zero, if less than 8tb of memory is used.
            mstore(0x3a, 0)
        }
    }

    /// @dev For deriving contracts to override, so that operator filtering
    /// can be turned on / off.
    /// Returns true by default.
    function _operatorFilteringEnabled() internal view virtual returns (bool) {
        return true;
    }

    /// @dev For deriving contracts to override, so that preferred marketplaces can
    /// skip operator filtering, helping users save gas.
    /// Returns false for all inputs by default.
    function _isPriorityOperator(address) internal view virtual returns (bool) {
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title IERC721RestrictApprove
/// @dev Approve抑制機能付きコントラクトのインターフェース
/// @author Lavulite

interface IERC721RestrictApprove {
    /**
     * @dev CALレベルが変更された場合のイベント
     */
    event CalLevelChanged(address indexed operator, uint256 indexed level);
    
    /**
     * @dev LocalContractAllowListnに追加された場合のイベント
     */
    event LocalCalAdded(address indexed operator, address indexed transferer);

    /**
     * @dev LocalContractAllowListnに削除された場合のイベント
     */
    event LocalCalRemoved(address indexed operator, address indexed transferer);

    /**
     * @dev CALを利用する場合のCALのレベルを設定する。レベルが高いほど、許可されるコントラクトの範囲が狭い。
     */
    function setCALLevel(uint256 level) external;

    /**
     * @dev CALのアドレスをセットする。
     */
    function setCAL(address calAddress) external;

    /**
     * @dev CALのリストに無い独自の許可アドレスを追加する場合、こちらにアドレスを記載する。
     */
    function addLocalContractAllowList(address transferer) external;

    /**
     * @dev CALのリストにある独自の許可アドレスを削除する場合、こちらにアドレスを記載する。
     */
    function removeLocalContractAllowList(address transferer) external;

    /**
     * @dev CALのリストにある独自の許可アドレスの一覧を取得する。
     */
    function getLocalContractAllowList() external view returns(address[] memory);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IContractAllowListProxy {
    function isAllowed(address _transferer, uint256 _level)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
/**
   _____       ___     ___ __           ____  _ __      
  / ___/____  / (_)___/ (_) /___  __   / __ )(_) /______
  \__ \/ __ \/ / / __  / / __/ / / /  / __  / / __/ ___/
 ___/ / /_/ / / / /_/ / / /_/ /_/ /  / /_/ / / /_(__  ) 
/____/\____/_/_/\__,_/_/\__/\__, /  /_____/_/\__/____/  
                           /____/                        

- npm: https://www.npmjs.com/package/solidity-bits
- github: https://github.com/estarriolvetch/solidity-bits

 */
pragma solidity ^0.8.0;

import "./BitScan.sol";

/**
 * @dev This Library is a modified version of Openzeppelin's BitMaps library.
 * Functions of finding the index of the closest set bit from a given index are added.
 * The indexing of each bucket is modifed to count from the MSB to the LSB instead of from the LSB to the MSB.
 * The modification of indexing makes finding the closest previous set bit more efficient in gas usage.
*/

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */

library BitMaps {
    using BitScan for uint256;
    uint256 private constant MASK_INDEX_ZERO = (1 << 255);
    uint256 private constant MASK_FULL = type(uint256).max;

    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = MASK_INDEX_ZERO >> (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = MASK_INDEX_ZERO >> (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = MASK_INDEX_ZERO >> (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }


    /**
     * @dev Consecutively sets `amount` of bits starting from the bit at `startIndex`.
     */    
    function setBatch(BitMap storage bitmap, uint256 startIndex, uint256 amount) internal {
        uint256 bucket = startIndex >> 8;

        uint256 bucketStartIndex = (startIndex & 0xff);

        unchecked {
            if(bucketStartIndex + amount < 256) {
                bitmap._data[bucket] |= MASK_FULL << (256 - amount) >> bucketStartIndex;
            } else {
                bitmap._data[bucket] |= MASK_FULL >> bucketStartIndex;
                amount -= (256 - bucketStartIndex);
                bucket++;

                while(amount > 256) {
                    bitmap._data[bucket] = MASK_FULL;
                    amount -= 256;
                    bucket++;
                }

                bitmap._data[bucket] |= MASK_FULL << (256 - amount);
            }
        }
    }


    /**
     * @dev Consecutively unsets `amount` of bits starting from the bit at `startIndex`.
     */    
    function unsetBatch(BitMap storage bitmap, uint256 startIndex, uint256 amount) internal {
        uint256 bucket = startIndex >> 8;

        uint256 bucketStartIndex = (startIndex & 0xff);

        unchecked {
            if(bucketStartIndex + amount < 256) {
                bitmap._data[bucket] &= ~(MASK_FULL << (256 - amount) >> bucketStartIndex);
            } else {
                bitmap._data[bucket] &= ~(MASK_FULL >> bucketStartIndex);
                amount -= (256 - bucketStartIndex);
                bucket++;

                while(amount > 256) {
                    bitmap._data[bucket] = 0;
                    amount -= 256;
                    bucket++;
                }

                bitmap._data[bucket] &= ~(MASK_FULL << (256 - amount));
            }
        }
    }


    /**
     * @dev Find the closest index of the set bit before `index`.
     */
    function scanForward(BitMap storage bitmap, uint256 index) internal view returns (uint256 setBitIndex) {
        uint256 bucket = index >> 8;

        // index within the bucket
        uint256 bucketIndex = (index & 0xff);

        // load a bitboard from the bitmap.
        uint256 bb = bitmap._data[bucket];

        // offset the bitboard to scan from `bucketIndex`.
        bb = bb >> (0xff ^ bucketIndex); // bb >> (255 - bucketIndex)
        
        if(bb > 0) {
            unchecked {
                setBitIndex = (bucket << 8) | (bucketIndex -  bb.bitScanForward256());    
            }
        } else {
            while(true) {
                require(bucket > 0, "BitMaps: The set bit before the index doesn't exist.");
                unchecked {
                    bucket--;
                }
                // No offset. Always scan from the least significiant bit now.
                bb = bitmap._data[bucket];
                
                if(bb > 0) {
                    unchecked {
                        setBitIndex = (bucket << 8) | (255 -  bb.bitScanForward256());
                        break;
                    }
                } 
            }
        }
    }

    function getBucket(BitMap storage bitmap, uint256 bucket) internal view returns (uint256) {
        return bitmap._data[bucket];
    }
}

// SPDX-License-Identifier: MIT
/**
   _____       ___     ___ __           ____  _ __      
  / ___/____  / (_)___/ (_) /___  __   / __ )(_) /______
  \__ \/ __ \/ / / __  / / __/ / / /  / __  / / __/ ___/
 ___/ / /_/ / / / /_/ / / /_/ /_/ /  / /_/ / / /_(__  ) 
/____/\____/_/_/\__,_/_/\__/\__, /  /_____/_/\__/____/  
                           /____/                        

- npm: https://www.npmjs.com/package/solidity-bits
- github: https://github.com/estarriolvetch/solidity-bits

 */

pragma solidity ^0.8.0;


library BitScan {
    uint256 constant private DEBRUIJN_256 = 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff;
    bytes constant private LOOKUP_TABLE_256 = hex"0001020903110a19042112290b311a3905412245134d2a550c5d32651b6d3a7506264262237d468514804e8d2b95569d0d495ea533a966b11c886eb93bc176c9071727374353637324837e9b47af86c7155181ad4fd18ed32c9096db57d59ee30e2e4a6a5f92a6be3498aae067ddb2eb1d5989b56fd7baf33ca0c2ee77e5caf7ff0810182028303840444c545c646c7425617c847f8c949c48a4a8b087b8c0c816365272829aaec650acd0d28fdad4e22d6991bd97dfdcea58b4d6f29fede4f6fe0f1f2f3f4b5b6b607b8b93a3a7b7bf357199c5abcfd9e168bcdee9b3f1ecf5fd1e3e5a7a8aa2b670c4ced8bbe8f0f4fc3d79a1c3cde7effb78cce6facbf9f8";

    /**
        @dev Isolate the least significant set bit.
     */ 
    function isolateLS1B256(uint256 bb) pure internal returns (uint256) {
        require(bb > 0);
        unchecked {
            return bb & (0 - bb);
        }
    } 

    /**
        @dev Isolate the most significant set bit.
     */ 
    function isolateMS1B256(uint256 bb) pure internal returns (uint256) {
        require(bb > 0);
        unchecked {
            bb |= bb >> 128;
            bb |= bb >> 64;
            bb |= bb >> 32;
            bb |= bb >> 16;
            bb |= bb >> 8;
            bb |= bb >> 4;
            bb |= bb >> 2;
            bb |= bb >> 1;
            
            return (bb >> 1) + 1;
        }
    } 

    /**
        @dev Find the index of the lest significant set bit. (trailing zero count)
     */ 
    function bitScanForward256(uint256 bb) pure internal returns (uint8) {
        unchecked {
            return uint8(LOOKUP_TABLE_256[(isolateLS1B256(bb) * DEBRUIJN_256) >> 248]);
        }   
    }

    /**
        @dev Find the index of the most significant set bit.
     */ 
    function bitScanReverse256(uint256 bb) pure internal returns (uint8) {
        unchecked {
            return 255 - uint8(LOOKUP_TABLE_256[((isolateMS1B256(bb) * DEBRUIJN_256) >> 248)]);
        }   
    }

    function log2(uint256 bb) pure internal returns (uint8) {
        unchecked {
            return uint8(LOOKUP_TABLE_256[(isolateMS1B256(bb) * DEBRUIJN_256) >> 248]);
        } 
    }
}