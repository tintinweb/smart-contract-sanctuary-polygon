/**
 *Submitted for verification at polygonscan.com on 2022-02-07
*/

// Sources flattened with hardhat v2.8.2 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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


// File contracts/ILuminaRecords.sol

pragma solidity ^0.8.0;

interface ILuminaRecords {

    function getBalances() external view returns (uint256[] memory balances, uint64[] memory blockNumbers);
    function findBalance(address wallet, uint64 blockNumber) external view returns (uint256 balance);
    function getClaimsCnt(uint64 blockNumber) external view returns (uint16);
    function hasClaimed(uint64 blockNumber, address recipient) external view returns (uint32 rewardUnits);
    function getClaims(uint64[] memory blockNumbers, address recipient) external view returns (uint16[] memory claimsCnt, bool[] memory claimed);
    function setCommision(uint8 commisionPrc) external;
    function getCommision(address wallet) external view returns (uint8 commisionPrc);
    function _registerBalance(address sender, uint256 balance, bool force) external returns (bool registered); // onlyToken
    function _updateBalance(address sender, uint256 balance) external; // onlyToken
    function _addClaim(uint64 blockNumber, address recipient, uint32 rewardUnits) external; // onlyTrustee
    function _updateFirstBlockNumber(uint64 blockNumber) external; // onlyAdmin

}


// File contracts/Parameters.sol

pragma solidity ^0.8.0;

abstract contract Parameters {
    // The DEMO mode limits rewards to 1 per challenge and limits blocks per challenge to 2
    bool public constant DEMO = false;

    // Number of decimals in reward token
    uint8 public constant TOKEN_DECIMALS = 18;
    uint256 public constant TOKEN_UNIT = 10 ** TOKEN_DECIMALS; // 1 LUMI

    // The lucky number determines the premium challenges
    uint8 public constant LUCKY_NUMBER = 2;

    // Challenges
    uint8 public constant CHALLENGE_NULL = 255;
    uint8 public constant MAX_CHALLENGE_CNT = 100;
    uint8 public constant MIN_CHALLENGE_DIFFICULTY = DEMO ? 10 : 20;
    uint8 public constant MAX_CHALLENGE_DIFFICULTY = DEMO ? 208 : 218;
    uint8 public constant CHALLENGE_DIFFICULTY_STEP = 2;

    // Creating new challenges
    uint64 public constant BLOCKS_PER_DAY = 39272; // 3600*24 / 2.2

    uint64 public constant MAX_DONOR_BLOCKS = 200; // number of most recent consecutive blocks that can be used as donors

    // Number of blocks we need to wait for a new challenge
    uint8 public constant BLOCKS_PER_CHALLENGE = DEMO ? 2 : 100;

    // Hard limit on number of claims per challenge
    uint16 public constant REWARDS_CNT_LIMIT = DEMO ? 2 : 500;

    // Ramp-up in Newton Epoch
    uint256 public constant REWARD_UNIT = 10 ** (TOKEN_DECIMALS-3); // 0.001 LUMI
    uint16 public constant REWARD_UNITS_START = 10; // 0.01 LUMI
    uint16 public constant REWARD_UNITS_INC = 10; // 0.01 LUMI
    uint16 public constant REWARD_UNITS_STANDARD = 1000; // 1 LUMI
    uint16 public constant REWARD_INC_INTERVAL = DEMO ? 5 : 2700; // One increase per 2700 regular challenges, ~ add reward unit every week

    // external miners can only make claims on addresses with at least 0.01 LUMI
    uint256 public constant MINERS_CLAIM_MIN_RECIPIENT_BALANCE = 10 * REWARD_UNIT; // 0.01 LUMI

    uint256 public constant MAX_REGISTERED_BALANCE = 1000 * TOKEN_UNIT;

    // Cooldown in Einstein Epoch
    // Increase BLOCKS_PER_CHALLENGE by 2 blocks every week
    uint64 public constant BLOCKS_PER_CHALLENGE_INC = 2;
    uint64 public constant BLOCKS_PER_CHALLENGE_INC_INTERVAL = 1 * 7 * BLOCKS_PER_DAY;

}


// File @openzeppelin/contracts/utils/[email protected]

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


// File contracts/OnlyToken.sol

pragma solidity ^0.8.0;

/**
 * This module is used through inheritance. It will make available the modifier
 * `onlyToken`, which can be applied to your functions to restrict their use to
 * the token contract.
 */
abstract contract OnlyToken is Context {
    address private _creatorAddr;
    address private _tokenAddr;

    constructor() {
        _creatorAddr = _msgSender();
    }

    // OnlyCreator, OnlyOnce
    function attachToken(address tokenAddr_) external {
        require(_creatorAddr == _msgSender(), "OnlyToken: only creator can attach a token contract");
        require(_tokenAddr == address(0), "OnlyToken: the token contract has already been attached");
        _creatorAddr = address(0);
        _tokenAddr = tokenAddr_;
    }

    function tokenAddr() public view returns (address) {
        return _tokenAddr;
    }

    /**
     * @dev Throws if called by any account other than the token.
     */
    modifier onlyToken() {
        require(tokenAddr() == _msgSender(), "OnlyToken: only token can execute this function");
        _;
    }

}


// File contracts/OnlyTrustee.sol

pragma solidity ^0.8.0;

/**
 * This module is used through inheritance. It will make available the modifier
 * `onlyTrustee`, which can be applied to your functions to restrict their use to
 * the trustee contract.
 */
abstract contract OnlyTrustee is Context {
    address private _creatorAddr;
    address private _trusteeAddr;

    constructor() {
        _creatorAddr = _msgSender();
    }

    // OnlyCreator, OnlyOnce
    function attachTrustee(address trusteeAddr_) external {
        require(_creatorAddr == _msgSender(), "OnlyTrustee: only creator can attach a trustee contract");
        require(_trusteeAddr == address(0), "OnlyTrustee: the trustee contract has already been attached");
        _creatorAddr = address(0);
        _trusteeAddr = trusteeAddr_;
    }

    function trusteeAddr() public view returns (address) {
        return _trusteeAddr;
    }

    /**
     * @dev Throws if called by any account other than the trustee.
     */
    modifier onlyTrustee() {
        require(trusteeAddr() == _msgSender(), "OnlyTrustee: only trustee can execute this function");
        _;
    }

}


// File contracts/OnlyAdmin.sol

pragma solidity ^0.8.0;

/**
 * This module is used through inheritance. It will make available the modifier
 * `onlyAdmin`, which can be applied to your functions to restrict their use to
 * the admin contract.
 */
abstract contract OnlyAdmin is Context {
    address private _creatorAddr;
    address private _adminAddr;

    constructor() {
        _creatorAddr = _msgSender();
    }

    // OnlyCreator, OnlyOnce
    function attachAdmin(address adminAddr_) external {
        require(_creatorAddr == _msgSender(), "OnlyAdmin: only creator can attach a admin contract");
        require(_adminAddr == address(0), "OnlyAdmin: the admin contract has already been attached");
        _creatorAddr = address(0);
        _adminAddr = adminAddr_;
    }

    function adminAddr() public view returns (address) {
        return _adminAddr;
    }

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(adminAddr() == _msgSender(), "OnlyAdmin: conly admin can execute this function");
        _;
    }

}


// File contracts/LuminaRecords.sol

pragma solidity ^0.8.0;





contract LuminaRecords is ILuminaRecords, Parameters, OnlyToken, OnlyTrustee, OnlyAdmin {

    uint8 private constant BALANCE_RECORDS_CNT = 5;
    uint8 private constant DEFAULT_COMMISION_PRC = 22;
    uint8 private constant ZERO_COMMISION_PRC = 255;
    uint8 private constant MIN_COMMISION_PRC = 10;
    uint8 private constant MAX_COMMISION_PRC = 90;

    struct AddrBalanceRecord {
        uint256 balance;
        uint64 blockNumber;
    }

    struct AddrBalanceRecords {
        AddrBalanceRecord[BALANCE_RECORDS_CNT] records;
        uint8 recordsCnt;
    }

    // Mapping blockNumber to Balance Records
    uint64 private _firstBlockNumber;
    mapping (address => AddrBalanceRecords) private _balanceRecords;

    // Mapping blockNumber to claimsCnt
    mapping (uint64 => uint16) private _claimsCnt;

    // Mapping blockNumber to address to uint32 (number of reward units)
    mapping (uint64 => mapping (address => uint32)) private _claimed;

    // Mapping wallet address to commision rate
    // Special internal encodings: 0 means default commision, 255 means no commision (0%)
    mapping (address => uint8) private _commisions;

    event Commision(address indexed wallet, uint8 commisionPrc);
    event RegisteredBalance(address indexed wallet, uint64 blockNumber, uint256 balance);

    constructor() {
        _firstBlockNumber = 0;
    }

    function getBalances() external view returns (uint256[] memory balances, uint64[] memory blockNumbers) {
        AddrBalanceRecords memory brs = _balanceRecords[msg.sender];
        uint8 cnt = brs.recordsCnt;
        balances = new uint256[](cnt);
        blockNumbers = new uint64[](cnt);
        for(uint8 i = 0; i < brs.recordsCnt; i++) {
            balances[i] = brs.records[i].balance;
            blockNumbers[i] = brs.records[i].blockNumber;
        }
    }

    function findBalance(address wallet, uint64 blockNumber) external view returns (uint256 balance) {
        balance = 0;

        AddrBalanceRecords memory brs = _balanceRecords[wallet];
        for(uint8 i = 0; i < brs.recordsCnt; i++) {
            if(blockNumber >= brs.records[i].blockNumber) {
                balance = brs.records[i].balance;
                return (balance);
            }
        }

        require(balance == 0, "_balanceFind: corrupt balance");
        return (balance);
    }

    function getClaimsCnt(uint64 blockNumber) public view returns (uint16) {
        return _claimsCnt[blockNumber];
    }

    function hasClaimed(uint64 blockNumber, address recipient) public view returns (uint32 rewardUnits) {
        rewardUnits = _claimed[blockNumber][recipient];
    }

    function getClaims(uint64[] memory blockNumbers, address recipient) external view returns (uint16[] memory claimsCnt, bool[] memory claimed) {
        uint8 cnt = uint8(blockNumbers.length);
        claimsCnt = new uint16[](cnt);
        claimed = new bool[](cnt);

        for(uint8 i = 0; i < cnt; i++) {
            claimsCnt[i] = getClaimsCnt(blockNumbers[i]);
            claimed[i] = hasClaimed(blockNumbers[i], recipient) != 0;
        }
    }

    function setCommision(uint8 commisionPrc) external {
        address wallet = msg.sender;
        require(commisionPrc == 0 || (MIN_COMMISION_PRC <= commisionPrc && commisionPrc <= MAX_COMMISION_PRC), "Commision value is out of allowed range: [10-90] or 0");
        uint8 c = commisionPrc == 0 ? ZERO_COMMISION_PRC : commisionPrc;
        _commisions[wallet] = c;
        emit Commision(wallet, commisionPrc);
    }

    function getCommision(address wallet) external view returns (uint8 commisionPrc) {
        uint8 c = _commisions[wallet];
        bool isContract = Address.isContract(wallet);
        // Contracts default commision is 0%, regular wallets defualt commision is 22%
        commisionPrc = c == 0 ? (isContract ? 0 : DEFAULT_COMMISION_PRC) : c == ZERO_COMMISION_PRC ? 0 : c;
        require(commisionPrc == 0 || (MIN_COMMISION_PRC <= commisionPrc && commisionPrc <= MAX_COMMISION_PRC), "Commision value is out of allowed range: [10-90] or 0");
    }

    function _cleanupBalances(AddrBalanceRecords storage brs) private {
        if(brs.recordsCnt > 1) {
            for(uint8 i = brs.recordsCnt-1; i > 0; i--) {
                AddrBalanceRecord storage br = brs.records[i-1];
                if(br.blockNumber <= _firstBlockNumber) {
                    // We can remove the last record
                    brs.recordsCnt--;
                }
            }
        }
    }

    function _registerBalance(address wallet, uint256 balance, bool force) external onlyToken returns (bool registered) {
        AddrBalanceRecords storage brs = _balanceRecords[wallet];
        _cleanupBalances(brs);
        if(balance < REWARD_UNIT) {
            // There is no sense if recording less than 0.001 LUMI, make it zero
            balance = 0;
            if(brs.recordsCnt == 0) {
                return false;
            }
        } else if(balance > MAX_REGISTERED_BALANCE) {
            balance = MAX_REGISTERED_BALANCE;
        }

        uint64 blockNumber = uint64(block.number);
        if(brs.recordsCnt > 0 && brs.records[0].balance == balance) {
            // Don't register the same amount again
            registered = true;
        } else if(brs.recordsCnt < BALANCE_RECORDS_CNT || force) {
            uint8 n = brs.recordsCnt < BALANCE_RECORDS_CNT ? brs.recordsCnt : BALANCE_RECORDS_CNT - 1;
            for(uint8 i = n; i > 0; i--) {
                brs.records[i] = brs.records[i-1];
            }
            brs.records[0].balance = balance;
            brs.records[0].blockNumber = blockNumber;
            if(brs.recordsCnt < BALANCE_RECORDS_CNT) {
                brs.recordsCnt++;
            }
            registered = true;
            emit RegisteredBalance(wallet, blockNumber, balance);
        } else {
            registered = false;
        }
    }

    function _updateBalance(address wallet, uint256 balance) external onlyToken {
        AddrBalanceRecords storage brs = _balanceRecords[wallet];
        _cleanupBalances(brs);
        if(balance < REWARD_UNIT) {
            // There is no sense if recording less than 0.001 LUMI, make it zero
            balance = 0;
            if(brs.recordsCnt == 0) {
                return;
            }
        } else if(balance > MAX_REGISTERED_BALANCE) {
            balance = MAX_REGISTERED_BALANCE;
        }

        uint64 blockNumber = uint64(block.number);
        if(brs.recordsCnt == 0) {
            brs.records[0].balance = balance;
            brs.records[0].blockNumber = blockNumber;
            brs.recordsCnt++;
            emit RegisteredBalance(wallet, blockNumber, balance);
        } else if(brs.records[0].balance > balance) {
            brs.records[0].balance = balance;
            blockNumber = brs.records[0].blockNumber;
            emit RegisteredBalance(wallet, blockNumber, balance);
        }
    }

    function _addClaim(uint64 blockNumber, address recipient, uint32 rewardUnits) external onlyTrustee {
        _claimsCnt[blockNumber]++;
        _claimed[blockNumber][recipient] = rewardUnits;
    }

    function _updateFirstBlockNumber(uint64 firstBlockNumber_) external onlyAdmin {
        _firstBlockNumber = firstBlockNumber_;
    }

}