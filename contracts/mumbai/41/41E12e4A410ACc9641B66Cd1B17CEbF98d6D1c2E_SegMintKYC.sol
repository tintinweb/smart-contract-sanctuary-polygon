/**
 *Submitted for verification at polygonscan.com on 2023-06-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
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

    function _revert(bytes memory returndata, string memory errorMessage)
        private
        pure
    {
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

// SegMint KYC Interface
interface SegMintKYCInterface {
    // set owner address
    function setOwnerAddress(address owner_) external;

    // set KYC Manager
    function setKYCManager(address KYCManager_) external;

    // add address to the authorized addresses
    function authorizeAddress(address account_) external;

    // remove address fro mthe authorized addresses
    function unAuthorizeAddress(address account_) external;

    // get contract version
    function getContractVersion() external view returns (uint256);

    // get owner address
    function getOwnerAddress() external view returns (address);

    // get KYC Manager
    function getKYCManager() external view returns (address);

    // is authorized address?
    function isAuthorizedAddress(address account_) external view returns (bool);

    // get authorized addresses
    function getAuthorizedAddresses() external view returns (address[] memory);
}

// SegMint KYC
contract SegMintKYC {
    ///////////////////////
    ////   Libraries   ////
    ///////////////////////

    // Address
    using Address for address;

    //////////////////////
    ////    Fields    ////
    //////////////////////

    // owner
    address private _owner;

    // KYC manager
    address private _KYCManager;

    // contract version
    uint256 private _contractVersion = 1;

    // global authorization
    bool private _globalAuthorization = true;

    // authorized addresses
    address[] private _authorizedAddresses;

    // authorization status: wallet address => bool
    mapping(address => bool) private _isAuthorized;

    // authorized account info
    struct AUTHORIZEDACCOUNTINFO {
        // KYC Manager
        address KYCManager;
        // account address
        address account;
        // is authorized
        bool isAuthorized;
        // authorized time
        uint256 authorizedTimestamp;
        // unauthorized time
        uint256 unauthorizeTimestamp;
    }

    // authorized account info
    mapping(address => AUTHORIZEDACCOUNTINFO) private _authorizedAccountsInfo;

    ///////////////////////
    //    constructor    //
    ///////////////////////

    constructor() {
        // set owner address
        _owner = msg.sender;
    }

    //////////////////////
    ////    Events    ////
    //////////////////////

    // set owner address
    event setOwnerAddressEvent(
        address indexed OwnerAddress,
        address previousOwnerAddress,
        address indexed newOwnerAddress,
        uint256 indexed timestamp
    );

    // set KYC Manager
    event setKYCManagerEvent(
        address indexed Sender,
        address indexed previousKYCManager,
        address newKYCManager,
        uint256 indexed timestamp
    );

    // update global authorization status
    event updateGlobalAuthorizationEvent(
        address indexed KYCManager,
        bool previousStatus,
        bool newStatus,
        uint256 indexed timestamp
    );

    // authorize an account
    event authorizeAddressEvent(
        address indexed Sender,
        address indexed account,
        uint256 indexed timestamp
    );

    // unauthorize an account
    event unAuthorizeAddressEvent(
        address indexed Sender,
        address indexed account,
        uint256 indexed timestamp
    );

    /////////////////////////
    ////    Modifiers    ////
    /////////////////////////

    // only owner
    modifier onlyOwner() {
        // sender should be the owner address
        require(
            msg.sender == address(_owner),
            "SegMint KYC: Sender is not the owner!"
        );
        _;
    }

    // only KYC Manager
    modifier onlyKYCManager() {
        // sender should be the KYC Mangager addresss
        require(
            msg.sender == address(_KYCManager),
            "SegMint KYC: Sender is not the KYC Manager!"
        );
        _;
    }

    // not Null Address
    modifier notNullAddress(address account_) {
        // require account not be the zero address
        require(
            account_ != address(0),
            "SegMint KYC: Address should not be zero address!"
        );
        _;
    }

    // not NUll Addresses
    modifier notNullAddresses(address[] memory accounts_) {
        // require all accounts be not zero address
        for (uint256 i = 0; i < accounts_.length; i++) {
            require(
                accounts_[i] != address(0),
                "SegMint KYC: Address zero is not allowed."
            );
        }
        _;
    }

    //////////////////////////////
    ////   Public Functions   ////
    //////////////////////////////

    // set owner address
    function setOwnerAddress(address owner_)
        public
        onlyOwner
        notNullAddress(owner_)
    {
        // previous owner
        address previousOwnerAddress = _owner;

        // update owner
        _owner = owner_;

        // emit event
        emit setOwnerAddressEvent(
            msg.sender,
            previousOwnerAddress,
            owner_,
            block.timestamp
        );
    }

    // set KYC Manager
    function setKYCManager(address KYCManager_)
        public
        onlyOwner
        notNullAddress(KYCManager_)
    {
        // get current KYC Manager
        address previousKYCManager = _KYCManager;

        // update the KYC Manager
        _KYCManager = KYCManager_;

        // emit event
        emit setKYCManagerEvent(
            msg.sender,
            previousKYCManager,
            KYCManager_,
            block.timestamp
        );
    }

    // update global authorization
    function updateGlobalAuthorization(bool status_) public onlyKYCManager {
        // previous status
        bool previousStatus = _globalAuthorization;

        // update status
        _globalAuthorization = status_;

        // emit event
        emit updateGlobalAuthorizationEvent(
            msg.sender,
            previousStatus,
            status_,
            block.timestamp
        );
    }

    // get global authorization status
    function getGlobalAuthorizationStatus() public view returns (bool) {
        return _globalAuthorization;
    }

    // add address to the authorized addresses
    function authorizeAddress(address account_)
        public
        onlyKYCManager
        notNullAddress(account_)
    {
        // add account to authorized addresses
        _addAccountToAuthorizedAddresses(account_);

        // update authorized account info
        _authorizedAccountsInfo[account_] = AUTHORIZEDACCOUNTINFO({
            KYCManager: msg.sender,
            account: account_,
            isAuthorized: true,
            authorizedTimestamp: block.timestamp,
            unauthorizeTimestamp: 0
        });

        // emit event
        emit authorizeAddressEvent(msg.sender, account_, block.timestamp);
    }

    // remove address fro mthe authorized addresses
    function unAuthorizeAddress(address account_)
        public
        onlyKYCManager
        notNullAddress(account_)
    {
        // remove account from authorized account
        _removeAccountFromAuthorizedAddresses(account_);

        // update authorized account info
        _authorizedAccountsInfo[account_].isAuthorized = false;
        _authorizedAccountsInfo[account_].unauthorizeTimestamp = block
            .timestamp;

        // emit event
        emit unAuthorizeAddressEvent(msg.sender, account_, block.timestamp);
    }

    /* GETTERS */

    // get contract version
    function getContractVersion() public view returns (uint256) {
        // return version
        return _contractVersion;
    }

    // get owner address
    function getOwnerAddress() public view returns (address) {
        return _owner;
    }

    // get KYC Manager
    function getKYCManager() public view returns (address) {
        // return KYC Manager
        return _KYCManager;
    }

    // is authorized
    function isAuthorizedAddress(address account_)
        public
        view
        notNullAddress(account_)
        returns (bool)
    {
        // return true if either global authorization or account is authorized
        // return false if both global authorization and account authorization are false
        // global authorization (True ==> every addresses are authorized, False ==> only authorized addresses are permitted)
        return _globalAuthorization || _isAuthorized[account_];
    }

    // get authorized addresses
    function getAuthorizedAddresses() public view returns (address[] memory) {
        // return authorized addresses
        return _authorizedAddresses;
    }

    // get authorized account info
    function getAuthorizedAccountInfo(address account_)
        public
        view
        notNullAddress(account_)
        returns (AUTHORIZEDACCOUNTINFO memory)
    {
        // return info
        return _authorizedAccountsInfo[account_];
    }

    // get batch authorzed accounts info
    function getBatchAuthorizedAccountInfo(address[] memory accounts_)
        public
        view
        notNullAddresses(accounts_)
        returns (AUTHORIZEDACCOUNTINFO[] memory)
    {
        AUTHORIZEDACCOUNTINFO[] memory infos = new AUTHORIZEDACCOUNTINFO[](
            accounts_.length
        );
        for (uint256 i = 0; i < accounts_.length; i++) {
            infos[i] = getAuthorizedAccountInfo(accounts_[i]);
        }
        return infos;
    }

    /////////////////////////////////
    ////   Internal Functions    ////
    /////////////////////////////////

    // add account to authorized addresses
    function _addAccountToAuthorizedAddresses(address account_) internal {
        if (!_isAuthorized[account_]) {
            // add to the auhorized addresses
            _authorizedAddresses.push(account_);
            // udpate is authorized status
            _isAuthorized[account_] = true;
        }
    }

    // remove account from authorized addresses
    function _removeAccountFromAuthorizedAddresses(address account_) internal {
        if (_isAuthorized[account_]) {
            for (uint256 i = 0; i < _authorizedAddresses.length; i++) {
                if (_authorizedAddresses[i] == account_) {
                    _authorizedAddresses[i] = _authorizedAddresses[
                        _authorizedAddresses.length - 1
                    ];
                    _authorizedAddresses.pop();
                    // update status
                    _isAuthorized[account_] = false;
                    break;
                }
            }
        }
    }

    /////////////////////////////////
    ////   Private  Functions    ////
    /////////////////////////////////
}