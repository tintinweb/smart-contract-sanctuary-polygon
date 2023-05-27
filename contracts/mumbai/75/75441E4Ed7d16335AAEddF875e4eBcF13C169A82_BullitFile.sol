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
pragma solidity ^0.8.0;

import "./interfaces/ISubscription.sol";
import "./interfaces/IBullitFile.sol";
import "./MultiSig.sol";
import "./interfaces/IMultiSig.sol";
import "./BullitFileAdmin.sol";

contract BullitFile is BullitFileAdmin {

    uint256 public filesCount;

    mapping(address => User) private users;
    mapping(string => File) private files;

    mapping(address => string[]) private userOwnedFiles;
    mapping(address => string[]) public fileSharedWithUser;

    modifier filExists(string memory _uuid) {
        require(files[_uuid].ownerAddress == msg.sender, "File not found");
        _;
    }

    /////////////////////// Constructor ///////////////////////
    // constructor(address[] memory _owners, uint256 _numConfirmationsRequired) MultiSig (_owners, _numConfirmationsRequired){
    //     subscriptionContract = 0x083b986BeB75C6C7f52225d4de4689bE41fd7549;
    //     masterWallet = 0x216eF370452281f02c69F64F33f9Ad135F2892C1;
    //     profitRatio = 5;
    //     timeLimitForDeletingFilesAfterEndSubscription = 5 minutes;
    // }

    function initialize(address[] memory _owners, uint256 _numConfirmationsRequired)  public override initializer {
        MultiSig.initialize(_owners, _numConfirmationsRequired);
        subscriptionContract = 0x083b986BeB75C6C7f52225d4de4689bE41fd7549;
        masterWallet = 0x216eF370452281f02c69F64F33f9Ad135F2892C1;
        profitRatio = 5;
        timeLimitForDeletingFilesAfterEndSubscription = 5 minutes;
    }

    function executeFunction (uint256 _transactionId) internal override{

         if ((keccak256(abi.encodePacked(transactionMap[_transactionId].functionName)) == keccak256(abi.encodePacked(("_setProfitRatio"))))) {
            (uint256 _profitRatio) = abi.decode(transactionMap[_transactionId].data,( uint256 ));
            _setProfitRatio(_profitRatio);
        } else if ((keccak256(abi.encodePacked(transactionMap[_transactionId].functionName)) == keccak256(abi.encodePacked(("_setSubscriptionContract"))))) {
            (address _subscriptionContract ) = abi.decode(transactionMap[_transactionId].data, (address  ));
            _setSubscriptionContract( _subscriptionContract);
        } else if ((keccak256(abi.encodePacked(transactionMap[_transactionId].functionName)) == keccak256(abi.encodePacked(("_setMasterWalletAddress"))))) {
            (address _masterWallet) = abi.decode(transactionMap[_transactionId].data, (address));
            _setMasterWalletAddress(_masterWallet);
        } else if ((keccak256(abi.encodePacked(transactionMap[_transactionId].functionName)) == keccak256(abi.encodePacked(("_setTimeLimitForDeletingFilesAfterEndSubscription"))))) {
            (uint256 _val) = abi.decode(transactionMap[_transactionId].data, (uint256 ));
            _setTimeLimitForDeletingFilesAfterEndSubscription(_val);
        } else if ((keccak256(abi.encodePacked(transactionMap[_transactionId].functionName)) == keccak256(abi.encodePacked(("_deleteStorageForUser"))))) {
            (address _userAddress) = abi.decode(transactionMap[_transactionId].data, (address));
            _deleteStorageForUser( _userAddress);
        } 
    }


    /////////////////////// User Function ///////////////////////

    function encrypt(string[] memory _uuid, uint256[] memory _fileId, string[] memory _hashFile, uint256[] memory _fileSize, string calldata _storageName, uint256 _amountToDecrypt, bool isFolder) external senderNonZeroAddress{
        
        require(_uuid.length > 0, "UUID is Array");
        require(_hashFile.length > 0, "Hash file is Array");

        require(_fileId.length == _hashFile.length, "The file id must be same length hash files");
        require(_fileSize.length == _hashFile.length, "The file size must same length hash files");

        require(bytes(_storageName).length > 0, "The storage name is Required");

        (bool isSubscription, uint256 space, uint256 lastSubscriptionEndDate) = ISubscription(subscriptionContract).isThereSubscription(msg.sender);

        if (users[msg.sender].userAddress == address(0x0)) {
            users[msg.sender].userAddress = msg.sender;        
        }

        if (!isSubscription){
            if (users[msg.sender].storageSpace > space) {
                if (block.timestamp > lastSubscriptionEndDate + timeLimitForDeletingFilesAfterEndSubscription) {
                    users[msg.sender].storageSpace = space;
                    users[msg.sender].storageSpaceUsed = 0;
                    _deleteStorageForUser(msg.sender);
                } else {
                    require(false, "You cannot encrypt because the subscription has expired");
                }
            }
        } 
        
        if(users[msg.sender].storageSpace != space) {
            users[msg.sender].storageSpace = space;
        }
        
        uint256 fileSize = 0;
        for(uint256 i = 0 ; i < _hashFile.length ; i++) {
            require(bytes(_hashFile[i]).length > 0 , "The hash file is required");
            require(_fileSize[i] > 0 , "The file size must be greater than zero");
            fileSize += _fileSize[i];
        }

        require ((users[msg.sender].storageSpaceUsed + fileSize) <= space, "The available space is less than the file size");
        users[msg.sender].storageSpaceUsed  += fileSize;

        for(uint256 i = 0 ; i < _uuid.length ; i++) {
            string memory uuid = _uuid[i];
            require(bytes(uuid).length > 0 , "The uuid is required");
            require(files[uuid].ownerAddress == address(0x0), "The file exists");

            files[uuid].uuid = _uuid[i];
            files[uuid].ownerAddress = msg.sender;
            files[uuid].fileSize = isFolder ? fileSize : _fileSize[i];
            files[uuid].storageName = _storageName;
            files[uuid].amountToDecrypt = _amountToDecrypt;
            files[uuid].createAt = block.timestamp;

            if (isFolder) {
                files[uuid].hashFile = _hashFile;
                files[uuid].fileId = _fileId;
                users[msg.sender].numberOfFilesOwend += _hashFile.length;
            } else {
                files[uuid].hashFile.push(_hashFile[i]);
                files[uuid].fileId.push(_fileId[i]);
                users[msg.sender].numberOfFilesOwend += 1;
            }

            userOwnedFiles[msg.sender].push(uuid);
            filesCount++;

            emit encryptEvent(uuid, files[uuid].fileId, files[uuid].hashFile, msg.sender, _storageName, files[uuid].fileSize, _amountToDecrypt, files[uuid].createAt);
        }

        emit userStorageUpdateEvent(msg.sender, users[msg.sender].storageSpace, users[msg.sender].storageSpaceUsed);
    }

    function userData() external view returns (User memory user_) {
        (bool isSubscription, uint256 space, uint256 lastSubscriptionEndDate) = ISubscription(subscriptionContract).isThereSubscription(msg.sender);
        user_ = users[msg.sender];
        if (!isSubscription) {
            if (users[msg.sender].storageSpace > space) {
                if (block.timestamp > lastSubscriptionEndDate + timeLimitForDeletingFilesAfterEndSubscription) {
                    user_.storageSpace = space;
                    user_.storageSpaceUsed = 0;
                    return (user_);
                } 
            }
        } 
        user_.storageSpace = users[msg.sender].storageSpace == 0 ? space : users[msg.sender].storageSpace;
        return (user_);
    }

    function updateAuthorizers(string memory _uuid, address[] memory _newAuthorizers) external senderNonZeroAddress filExists(_uuid){
        require(files[_uuid].authorizers.length > _newAuthorizers.length , "The Authorizers are required");

        Authorizer[] memory authTemp = files[_uuid].authorizers;
        uint256 numberOfHashes = files[_uuid].hashFile.length;
        delete files[_uuid].authorizers;

        for (uint256 i = 0; i < authTemp.length; i++) {
            if(!authTemp[i].isPaid){
                removeItemFromArray(fileSharedWithUser[authTemp[i].userAddress], _uuid);
                users[authTemp[i].userAddress].numberOfFilesSharedWithYou -= numberOfHashes;
            }
        }

        uint256 count = 0;
        for (uint256 i = 0; i < authTemp.length; i++) {
            for (uint256 j = 0; j < _newAuthorizers.length; j++) {
                if (authTemp[i].isPaid) {
                    files[_uuid].authorizers.push(authTemp[i]);
                    j = _newAuthorizers.length;
                    count++;
                } else if (authTemp[i].userAddress == _newAuthorizers[j]) {
                    createUserAndPushUUId(_newAuthorizers[i] , _uuid, numberOfHashes);
                    j = _newAuthorizers.length;
                    count++;
                }
            }
        }

        for (uint256 i = 0; i < _newAuthorizers.length; i++) {
            require(_newAuthorizers[i] != msg.sender , "The owner cannot be authorizer");
            if (checkIsAuthorizersFound(files[_uuid].authorizers, _newAuthorizers[i]) == -1) {
                createUserAndPushUUId(_newAuthorizers[i], _uuid, numberOfHashes);
                count++;
            }
        }

        emit updateAuthorizersEvent(_uuid, files[_uuid].authorizers);
    }

    

    function getFile(string calldata _uuid) external view returns (File memory file_) {
        return files[_uuid];
    }

    function getAllHashForUser() external senderNonZeroAddress view returns (string[] memory files_, string[] memory uuid_) {
        return(getHashFiles(fileSharedWithUser[msg.sender], users[msg.sender].numberOfFilesSharedWithYou));
    }

    function getFilesOwned() external senderNonZeroAddress view returns (string[] memory files_, string[] memory uuid_) {
        return(getHashFiles(checkIfTheUserGivenPeriodSubscriptionHasExpired() ? new string[](0) : userOwnedFiles[msg.sender], users[msg.sender].numberOfFilesOwend));
    }

    function getHashFiles (string[] memory _files, uint256 _arrLength) internal view returns (string[] memory files_, string[] memory uuid_) {
        files_ = new string[](_arrLength);
        
        uint256 count = 0;
        for(uint256 i = 0; i < _files.length ; i++) {
            for (uint256 j = 0; j < files[_files[i]].hashFile.length ; j++) {
                files_[count] = files[_files[i]].hashFile[j];
                count++;
            }
        }

        return (files_, _files);
    }

    function decryption(string memory _uuid) external payable senderNonZeroAddress {
        require(files[_uuid].ownerAddress != address(0), "File not found");
        require(files[_uuid].amountToDecrypt > 0, "The file is free");

        int256 index = checkIsAuthorizersFound(files[_uuid].authorizers, msg.sender);
        require(index > -1, "Not Authorizer");
        require(!files[_uuid].authorizers[uint256(index)].isPaid, "Decryption amount has been paid");
        require(msg.value >= files[_uuid].amountToDecrypt, "The amount paid is less than the amount to decrypt");
        
        uint256 profitForMasterWallet = (((profitRatio * 10**18) / 100) * (files[_uuid].amountToDecrypt)) / 10**18;
        
        payable(masterWallet).transfer(profitForMasterWallet);
        payable(files[_uuid].ownerAddress).transfer(files[_uuid].amountToDecrypt - profitForMasterWallet);

        users[msg.sender].amountPaidForDecryption += files[_uuid].amountToDecrypt;
        users[files[_uuid].ownerAddress].profit += files[_uuid].amountToDecrypt - profitForMasterWallet;

        files[_uuid].authorizers[uint256(index)].isPaid = true;

        masterWalletAmount += profitForMasterWallet;

        emit decryptEvent (_uuid, msg.sender, files[_uuid].amountToDecrypt - profitForMasterWallet, masterWallet, profitForMasterWallet);
    }

    function deleteFile(string memory _uuid) external senderNonZeroAddress filExists(_uuid) {
        

        removeItemFromArray(userOwnedFiles[msg.sender] , _uuid);
        removeNumberOfFileOwnendAndSize(msg.sender, files[_uuid].hashFile.length, files[_uuid].fileSize);

        for(uint256 i = 0 ; i < files[_uuid].authorizers.length ; i++) {
            removeItemFromArray(fileSharedWithUser[files[_uuid].authorizers[i].userAddress] , _uuid);
            users[files[_uuid].authorizers[i].userAddress].numberOfFilesSharedWithYou -= files[_uuid].hashFile.length;
        }

        delete files[_uuid];
        emit deleteFileEvent(_uuid);
    }

    function deleteStorageForUser(address _userAddress) external onlyOwner returns (uint256 _transactionId) {
        return submitTransaction(msg.sender, "_deleteStorageForUser" , abi.encode(_userAddress));
    }

    function _deleteStorageForUser(address _userAddress) internal {
        for (uint256 i = 0; i < userOwnedFiles[_userAddress].length; i++) {
            for(uint256 j = 0 ; j < files[userOwnedFiles[_userAddress][i]].authorizers.length ; j++) {
                removeItemFromArray(fileSharedWithUser[files[userOwnedFiles[_userAddress][i]].authorizers[j].userAddress] , userOwnedFiles[_userAddress][i]);
                users[files[userOwnedFiles[_userAddress][i]].authorizers[j].userAddress].numberOfFilesSharedWithYou -= files[userOwnedFiles[_userAddress][i]].hashFile.length;
            }
            removeNumberOfFileOwnendAndSize(_userAddress, files[userOwnedFiles[_userAddress][i]].hashFile.length, files[userOwnedFiles[_userAddress][i]].fileSize);
        }

        delete userOwnedFiles[_userAddress]; 
        emit deleteAllFilesForOwnerEvent (_userAddress);
    }

    function createUserAndPushUUId(address _userAddress, string memory _uuid, uint256 _numberOfHashes) internal {
        if (users[_userAddress].userAddress == address(0)) {
            users[_userAddress].userAddress = _userAddress;
        }

        fileSharedWithUser[_userAddress].push(_uuid);
        files[_uuid].authorizers.push(Authorizer(_userAddress, false));
        users[_userAddress].numberOfFilesSharedWithYou += _numberOfHashes;
    }

    function removeNumberOfFileOwnendAndSize (address _userAddress, uint256 _hashFileLength, uint256 _fileSize) internal {
        users[_userAddress].numberOfFilesOwend -= _hashFileLength;
        users[_userAddress].storageSpaceUsed -= _fileSize;
    }

    function removeItemFromArray (string[] storage _files, string memory _hash) internal returns (bool) {
        for (uint256 i = 0; i < _files.length; i++) {
            if (keccak256(bytes(_files[i])) == keccak256(bytes(_hash))) {
                if (i != _files.length - 1) {
                    _files[i] = _files[_files.length - 1];
                }
                _files.pop();
                return true;
            }
        }
        return false;
    }

    function checkIsAuthorizersFound(Authorizer[] memory auth, address _val) internal pure returns (int256) {
        for (uint256 i = 0; i < auth.length; i++) {
            if (auth[i].userAddress == _val) {
                return int256(i);
            }
        }
        return -1;
    }

    function checkIfTheUserGivenPeriodSubscriptionHasExpired() internal view returns (bool) {
        (bool isSubscription, uint256 space, uint256 lastSubscriptionEndDate) = ISubscription(subscriptionContract).isThereSubscription(msg.sender);
        if (!isSubscription) {
            if (users[msg.sender].storageSpace > space) {
                if (block.timestamp > lastSubscriptionEndDate + timeLimitForDeletingFilesAfterEndSubscription) {
                    return true;
                } 
            }
        }

        return false;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ISubscription.sol";
import "./interfaces/IBullitFile.sol";
import "./MultiSig.sol";

abstract contract BullitFileAdmin is MultiSig, IBullitFile {

    address subscriptionContract;
    uint256 profitRatio;
    address masterWallet;
    uint256 masterWalletAmount;
    uint256 timeLimitForDeletingFilesAfterEndSubscription;

    /////////////////////// Modifier ///////////////////////
    modifier senderNonZeroAddress() {
        require(msg.sender != address(0x0), "Zero address not Allowed");
        _;
    }

    modifier nonZeroAddress(address _val, string memory _msg) {
        require(_val != address(0x0), _msg);
        _;
    }

    modifier valueIsGreaterThan(uint256 _val, uint256 _conditionVal, string memory _msg) {
        require(_val > _conditionVal, _msg);
        _;
    }

    /////////////////////// Owner Function ///////////////////////

    function setProfitRatio(uint256 _profitRatio) external senderNonZeroAddress onlyOwner valueIsGreaterThan(_profitRatio, 0, "The profit ratio must be greater than zero") returns (uint256 _transactionId) {
        return submitTransaction(msg.sender, "_setProfitRatio" , abi.encode(_profitRatio));
    }

    function _setProfitRatio(uint256 _profitRatio) internal {
        profitRatio = _profitRatio;
    }

    function setSubscriptionContract(address _subscriptionContract) external senderNonZeroAddress onlyOwner nonZeroAddress(_subscriptionContract, "Subscription address does not allow zero address") returns (uint256 _transactionId) {
        return submitTransaction(msg.sender, "_setSubscriptionContract" , abi.encode(_subscriptionContract));
    }

    function _setSubscriptionContract(address _subscriptionContract) internal  {
        subscriptionContract = _subscriptionContract;
    }

    function setMasterWalletAddress(address _masterWallet) external senderNonZeroAddress onlyOwner nonZeroAddress(_masterWallet, "Master Wallet address does not allow zero address") returns (uint256 _transactionId) {
        return submitTransaction(msg.sender, "_setMasterWalletAddress" , abi.encode(_masterWallet));
    }

    function _setMasterWalletAddress(address _masterWallet) internal {
        masterWallet = _masterWallet;
    }

    function setTimeLimitForDeletingFilesAfterEndSubscription(uint256 _val) external senderNonZeroAddress onlyOwner valueIsGreaterThan(_val, 0, "The Value must be greater than zero") returns (uint256 _transactionId) {
        return submitTransaction(msg.sender, "_setTimeLimitForDeletingFilesAfterEndSubscription" , abi.encode(_val));
    }

    function _setTimeLimitForDeletingFilesAfterEndSubscription(uint256 _val) internal {
        timeLimitForDeletingFilesAfterEndSubscription = _val;
    }

    function getSubscriptionContract() external onlyOwner view returns (address) {
        return subscriptionContract;
    }

    function getMasterWalletAddress() external onlyOwner view returns (address) {
        return masterWallet;
    }

    function getTimeLimitForDeletingFilesAfterEndSubscription() external onlyOwner view returns (uint256) {
        return timeLimitForDeletingFilesAfterEndSubscription;
    }

    function getMasterWalletAmount() external onlyOwner view returns (uint256) {
        return masterWalletAmount;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBullitFile {

    /////////////////////// Event ///////////////////////

    event userStorageUpdateEvent (address userAddress, uint256 storageSpace, uint256 storageSpaceUsed);
    event encryptEvent (string uuid, uint256[] fileId,  string[] hashFile, address ownerAddress, string storageName, uint256 fileSize, uint256 amountToDecrypt, uint256 createAt);
    event updateAuthorizersEvent (string uuid, Authorizer[] authorizers);
    event decryptEvent (string uuid, address userDecrypted, uint256 amountPaidForOwnerFile, address masterWallet, uint256 amountPaidForMasterWallet);
    event deleteFileEvent (string uuid);
    event deleteAllFilesForOwnerEvent (address userAddress);

    /////////////////////// Struct ///////////////////////

    struct User {
        address userAddress;
        uint256 amountPaidForDecryption;
        uint256 numberOfFilesOwend;
        uint256 numberOfFilesSharedWithYou;
        uint256 profit;
        uint256 storageSpace; // in byte
        uint256 storageSpaceUsed; // in byte
    }

    struct File {
        string uuid;
        uint256[] fileId;
        string[] hashFile;
        address ownerAddress;
        Authorizer[] authorizers;
        uint256 fileSize;
        string storageName;
        uint256 amountToDecrypt;
        uint256 createAt;
    }

    struct Authorizer {
        address userAddress;
        bool isPaid;
    }

    /////////////////////// User Functions ///////////////////////

    function userData() external view returns (User calldata user_);

    function encrypt(string[] memory _uuid, uint256[] memory _fileId, string[] memory _hashFile, uint256[] memory _fileSize, string memory _storageName, uint256 _amountToDecrypt, bool isFolder) external;

    function updateAuthorizers(string memory _uuid, address[] memory _newAuthorizers) external;

    function getFile(string memory _uuid) external view returns (File memory file_);

    function getAllHashForUser() external view returns(string[] memory files_, string[] memory uuid_);

    function getFilesOwned() external view returns (string[] memory files_, string[] memory uuid_);

    function decryption(string memory _uuid) external payable;

    function deleteFile(string memory _uuid) external;

    /////////////////////// Onwer Function ///////////////////////

    function setProfitRatio(uint256 newProfitRatio) external returns (uint256 _transactionId);
    
    function setTimeLimitForDeletingFilesAfterEndSubscription(uint256 _val) external returns (uint256 _transactionId);

    function getTimeLimitForDeletingFilesAfterEndSubscription() external view returns (uint256);

    function setMasterWalletAddress(address _masterWallet) external returns (uint256 _transactionId);
    
    function getMasterWalletAddress() external view returns (address);

    function setSubscriptionContract(address _subscriptionContract) external returns (uint256 _transactionId);

    function getSubscriptionContract() external view returns (address);

    function getMasterWalletAmount() external view returns (uint256);

    function deleteStorageForUser(address _userAddress) external returns (uint256 _transactionId);

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.14;

interface IMultiSig {

    // Defining the Transaction struct
    struct Transaction {
        address from;               // Address that submitted the transaction
        address executed;           // Address that executed the transaction
        uint256 numConfirmations;   // Number of confirmations for the transaction
        string functionName;        // Name of the function to be executed in the transaction
        bytes data;                 // Data to be passed to the function
        address[] confirmed;        // Array of addresses that confirmed the transaction
        uint256 createdAt;          // Timestamp when the transaction was created
        uint256 updatedAt;          // Timestamp when the transaction was last updated
    }

    // Defining events for submitting, confirming, and executing transactions
    event SubmitTransaction(address indexed from, uint256 indexed transactionId); 
    event ConfirmTransaction(address indexed from, uint256 indexed transactionId);
    event ExecuteTransaction(address indexed from, uint256 indexed transactionId);

    // Function to get the list of owners
    function getOwners() external view returns (address[] memory);

    // Function to confirm a transaction
    function confirmTransaction(uint256 _transactionId) external;
    
    // Function to execute a transaction
    function executeTransaction(uint256 _transactionId) external  ;

    // Function to get the details of a transaction
    function getTransaction (uint256 _transactionId) external view returns (Transaction memory transactions_);

    // Function to get all transactions with pagination
    function getAllTransactions (uint256 _pageNo, uint256 _perPage) external view returns (Transaction [] memory transactions_, uint256 totalList_);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface ISubscription {

    /////////////////////// Enum ///////////////////////

    enum PlanType {
        MONTHLY,
        YEARLY
    }

    /////////////////////// Struct ///////////////////////

    struct Plan {
        uint256 id;
        string name;
        uint256 price;
        PlanType planType;
        uint256 spaceSize; // in byte
        bool isActive;
    }

    struct Subscription {
        uint256 id;
        uint256 planId;
        address walletAddress;
        uint256 fromDate;
        uint256 toDate;
    }

    struct Storage {
        address walletAddress;
        uint256 available; // in byte
        uint256 used; // in byte
    }

    /////////////////////// General functions ///////////////////////

    function setFreeSpace(uint256 _freeSpace) external returns (uint256 _transactionId);
    function getFreeSpace() external view returns (uint256 _freeSpace);

    function isThereSubscription (address _user) external view returns (bool isSubscription_, uint256 space_, uint256 lastSubscriptionEndDate_);
    
    /////////////////////// Plan management functions and events ///////////////////////

    /********************** Event **********************/
    event createNewPlanEvent (uint256 id, string name, uint256 price, PlanType planType, uint256 spaceSize, bool isActive);
    event setActivateDeactivatePlanEvent (uint256 id, bool isActive);

    /********************** Functions **********************/
    function createNewPlan (string memory _name, uint256 _price, bool _isMonthly, uint256 _spaceSize, bool _isActive) external returns (uint256 _transactionId);
    function setActivateDeactivatePlan (uint256 _id, bool isActive) external returns (uint256 _transactionId);
    function getAllPlans (uint256 _pageNo, uint256 _perPage) external view returns (Plan[] memory plans_, uint total_);

    /////////////////////// Subscription management functions ///////////////////////
    
    event subscriptionEvent (uint256 id, uint256 planId, address walletAddress, uint256 fromDate, uint256 toDate);
    function subscription (uint256 _planId) external payable;
    function getListOfSubscriptionsForUser () external view returns (Subscription[] memory subscriptions_, uint256 total_);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "a must be greater than or equals b");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "must be greater than zero");
        return a / b;
    }

 
  
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IMultiSig.sol";
import "./lib/SafeMath.sol";

abstract contract MultiSig is IMultiSig, Initializable {

    using SafeMath for uint256;

    address [] private ownerList;
    mapping(address => bool) private ownerMap;

    uint256 private transactionIncrement;
    mapping(uint256 => Transaction) internal transactionMap;

    mapping(uint256 => mapping(address => bool)) private transactionAddressConfirmedMap;

    uint256 private numConfirmationsRequired;

    /////////////////////////////// Start Modifiers ///////////////////////////////
    
    // Modifier to check if the sender is an owner
    modifier onlyOwner() {
        require(ownerMap[msg.sender], "not owner");
        _;
    }

    // Modifier to check if the transaction exists
    modifier transactionExists(uint256 _transactionId) {
        require(_transactionId > 0 && _transactionId <= transactionIncrement, "Transaction does not exist");
        _;
    }

    // Modifier to check if the transaction has not been executed
    modifier notExecuted(uint256 _transactionId) {
        require(transactionMap[_transactionId].executed == address(0), "Transaction already executed");
        _;
    }

    // Modifier to check if the transaction has not been confirmed by the sender
    modifier notConfirmed(uint256 _transactionId) {
        require(!transactionAddressConfirmedMap[_transactionId][msg.sender], "Transaction already confirmed");
        _;
    }

    /////////////////////////////// End Modifiers ///////////////////////////////

    // Constructor to initialize the contract with owners and the required number of confirmations
    // constructor(address [] memory _owners, uint256 _numConfirmationsRequired) {

    //     require (_numConfirmationsRequired > 1 , "The Number of confirmations required must be greater than one");
    //     require (_owners.length >= _numConfirmationsRequired , "The number of owners must be greater than or equal to the number of confirmations required");

    //     transactionIncrement = 0;
    //     numConfirmationsRequired = _numConfirmationsRequired;
    //     addOwners(_owners);
    // }

    function initialize(address [] memory _owners, uint256 _numConfirmationsRequired) public virtual onlyInitializing {

        require (_numConfirmationsRequired > 1 , "The Number of confirmations required must be greater than one");
        require (_owners.length >= _numConfirmationsRequired , "The number of owners must be greater than or equal to the number of confirmations required");

        transactionIncrement = 0;
        numConfirmationsRequired = _numConfirmationsRequired;
        addOwners(_owners);
    }

    // Internal function to add owners to the contract
    function addOwners(address[] memory _owners) internal {
        
        for (uint256 i = 0 ; i < _owners.length ; i = i.add(1)) {

            require (_owners[i] != address(0) , "Zero address not Allowed");
            require (!ownerMap[_owners[i]] , "The Owner not unique");

            ownerMap[_owners[i]] = true;
            ownerList.push(_owners[i]);
        }

    }
    // Function to get the list of owners
    function getOwners() external onlyOwner view returns (address[] memory) {
        return ownerList;
    }

    // Internal function to submit a transaction
    function submitTransaction(address _sender, string memory _functionName, bytes memory _data) internal returns (uint256 _transactionId) {
    
        require (_sender != address(0) , "Zero address not Allowed");
	    require(bytes(_functionName).length > 0, "The Function name is required");
	    require(_data.length > 0, "The Data is required");

        transactionIncrement = transactionIncrement.add(1);
    
        transactionMap[transactionIncrement].from           = _sender;
        transactionMap[transactionIncrement].executed       = address(0);
        transactionMap[transactionIncrement].functionName   = _functionName;
        transactionMap[transactionIncrement].data           = _data;
        transactionMap[transactionIncrement].createdAt      =  block.timestamp;
        transactionMap[transactionIncrement].updatedAt      =  block.timestamp;

        emit SubmitTransaction (_sender, transactionIncrement);

        return transactionIncrement;
    }

    // Function to confirm a transaction
    function confirmTransaction(uint256 _transactionId) external onlyOwner 
        transactionExists(_transactionId) 
        notExecuted(_transactionId) 
        notConfirmed(_transactionId) {

        transactionMap[_transactionId].confirmed.push(msg.sender);
        transactionMap[_transactionId].numConfirmations = transactionMap[_transactionId].numConfirmations.add(1);
        transactionAddressConfirmedMap[_transactionId][msg.sender] = true;
        transactionMap[_transactionId].updatedAt = block.timestamp;

        emit ConfirmTransaction(msg.sender, _transactionId);
    }

    // Function to execute a transaction
    function executeTransaction(uint256 _transactionId) external  onlyOwner transactionExists(_transactionId) 
        notExecuted(_transactionId) {

        require(transactionMap[_transactionId].numConfirmations >= numConfirmationsRequired, "cannot execute tx");

        transactionMap[_transactionId].executed = msg.sender;
        transactionMap[_transactionId].updatedAt = block.timestamp;

        executeFunction(_transactionId);
        
        emit ExecuteTransaction(msg.sender, _transactionId);
    }

    // Function to get the details of a transaction
    function getTransaction (uint256 _transactionId) external onlyOwner view returns (Transaction memory transactions_) {
        return transactionMap[_transactionId];
    }

    // Function to get all transactions with pagination
    function getAllTransactions (uint256 _pageNo, uint256 _perPage) external onlyOwner view returns (Transaction [] memory transactions_, uint256 totalList_) {
        require((_pageNo.mul(_perPage)) <= transactionIncrement, "Page is Out of Range");
        uint256 no_transaction = (transactionIncrement.sub(_pageNo.mul(_perPage))) < _perPage ?
        (transactionIncrement.sub(_pageNo.mul(_perPage))) : _perPage;
        Transaction[] memory transactions = new Transaction[](no_transaction);
        for (uint256 i = 0; i < transactions.length; i= i.add(1)) {
            transactions[i] = transactionMap[(_pageNo.mul(_perPage)) + (i.add(1))];
        }
        return (transactions, transactionIncrement);
    }

    // Internal function to execute the function specified in the transaction
    function executeFunction (uint256 _transactionId) internal virtual;
}