// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
        if (_initialized != type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
pragma solidity ^0.8.17;

import {SGomoku} from "interfaces/SGomoku.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Gomoku is Initializable {

    uint256 nonce;
    mapping(uint256 => SGomoku.GomokuData) public dataGomoku;

    event evChangeOpen(bool status);
    event evMakeGame(address owner);
    event evPlayer1(address player1);
    event evPlayer2(address player2);
    event evWin(address winer);
    event evLose(address winer);
    event evHaiti();
    event evHikiwake();

    function initialize()  public initializer {
        dataGomoku[nonce].flgGame = false;
    }

    function makeGomoku() external returns(bool){
        bool bCompletemake = false;
        if(dataGomoku[nonce].flgGame == false)
        {
            for(uint8 i = 0; i < 10; i++)
            {
               for(uint8 j = 0; j < 10; j++)
               {
                   dataGomoku[nonce].Goban[i][j] = 0;
               }
            }
            dataGomoku[nonce].flgGame = true;
            dataGomoku[nonce].OpenStatus = false;
            dataGomoku[nonce].PlayerNum = 0;
            dataGomoku[nonce].OwnerAddr = msg.sender;
            emit evMakeGame(dataGomoku[nonce].OwnerAddr);
            bCompletemake = true;
        }
        else
        {
            revert("Already created");
        }
        return(bCompletemake);
    }

    function ChanegeOpen() external onlyOwner(){
        dataGomoku[nonce].OpenStatus = true;
        emit evChangeOpen(dataGomoku[nonce].OpenStatus);
    }

    function EntryGame() external {
        // 開放状態を確認
        require(dataGomoku[nonce].OpenStatus == true, "Game is CLOSE");
        // 終了状態確認
        require(dataGomoku[nonce].flgEnd == false, "Game is END");

        // 現時点での参加人数０人
        if(dataGomoku[nonce].PlayerNum == 0){
            dataGomoku[nonce].PlayerNum++; // プレイヤー人数をインクリメント
            dataGomoku[nonce].Player1Addr = msg.sender; // プレイヤー1として設定
            emit evPlayer1(dataGomoku[nonce].Player1Addr);
        }
        // 現時点での参加人数1人
        else if(dataGomoku[nonce].PlayerNum == 1){
            require(msg.sender != dataGomoku[nonce].Player1Addr, "Don't Play Same Player");

            dataGomoku[nonce].PlayerNum++; // プレイヤー人数をインクリメント
            dataGomoku[nonce].Player2Addr = msg.sender; // プレイヤー2として設定
            dataGomoku[nonce].OpenStatus = false; // 公開状態をCLOSEに変更
            emit evPlayer2(dataGomoku[nonce].Player2Addr);
            dataGomoku[nonce].turnPlayerAddr = dataGomoku[nonce].Player1Addr; // 手番のアドレスをプレイヤー1に変更
        }
        else{
            revert("Full Player");
        }
    }

    function StoneHaiti(uint8 x, uint8 y) external{
        // ゲームが終了されているか
        require(dataGomoku[nonce].flgEnd == false, "Game is END");
        // 手番じゃなければ無効
        require(dataGomoku[nonce].turnPlayerAddr == msg.sender, "You're not turnPlayer");
        // 値が範囲内かどうかの判定
        require(0 <= x && x < 10 && 0 <= y && y < 10, "Out of range");
        // すでに値が入っている場合は無効
        require(dataGomoku[nonce].Goban[x][y] == 0, "This place not vacant");
        uint8 Player = 0;
        // アドレスに応じて配列内の値を変更
        if(dataGomoku[nonce].turnPlayerAddr == dataGomoku[nonce].Player1Addr)
        {
            Player = 1;
        }
        else if(dataGomoku[nonce].turnPlayerAddr == dataGomoku[nonce].Player2Addr)
        {
            Player = 2;
        }
        dataGomoku[nonce].Goban[x][y] = Player;
        emit evHaiti();

        // 配置後に勝敗判定
        uint8 hanteiCount = Judge(x,y);
        // 打った石の隣り合わせで石が4つある場合
        if(hanteiCount == 4){
            dataGomoku[nonce].winPlayerAddr = msg.sender;
            dataGomoku[nonce].flgEnd = true;
            emit evWin(dataGomoku[nonce].winPlayerAddr);
        }
        // 盤面に空きがある場合
        else if(hanteiCount == 8)
        {
            if(Player == 1){
                dataGomoku[nonce].turnPlayerAddr = dataGomoku[nonce].Player2Addr;
            }
            else if(Player == 2){
                dataGomoku[nonce].turnPlayerAddr = dataGomoku[nonce].Player1Addr;
            }
        }
        // その他(５個並んでいないかつ盤面に空きがない)
        else
        {
            emit evHikiwake();
            dataGomoku[nonce].flgEnd = true;
        }
    }

    function Judge(uint8 x, uint8 y) internal view returns(uint8){
        uint8 countishi_side = 0;
        uint8 countishi_ver = 0;
        uint8 countishi_diag = 0;
        uint8 countishi_gyakudiag = 0;
        uint8 returnCount;
        // 横正方向に複数同じ石が並んでいるか
        for(uint8 i = 1; i < 5; i++){
            if(x+i > 9){
                break;
            }
            if(dataGomoku[nonce].Goban[x][y] == dataGomoku[nonce].Goban[x+i][y]){
                countishi_side++;
            }
            else{
                break;
            }
        }
        // 縦正方向に複数同じ石が並んでいるか
        for(uint8 j = 1; j < 5; j++){
            if(y+j > 9){
                break;
            }
            if(dataGomoku[nonce].Goban[x][y] == dataGomoku[nonce].Goban[x][y+j]){
                countishi_ver++;
            }
            else{
                break;
            }
        }
        // 斜め正方向に複数同じ石が並んでいるか
        for(uint8 k = 1; k < 5; k++){
            if(x+k > 9 || y+k > 9){
                break;
            }
            if(dataGomoku[nonce].Goban[x][y] == dataGomoku[nonce].Goban[x+k][y+k]){
                countishi_diag++;
            }
            else{
                break;
            }
        }
        // 逆斜め正方向に複数同じ石が並んでいるか
        for(uint8 k = 1; k < 5; k++){
            if(x+k > 9 || y+k > 9){
                break;
            }
            if(dataGomoku[nonce].Goban[x][y] == dataGomoku[nonce].Goban[x+k][y+k]){
                countishi_gyakudiag++;
            }
            else{
                break;
            }
        }
        // 横負方向に複数同じ石が並んでいるか
        for(uint8 l = 1; l < 5; l++){
            if(l > x){
                break;
            }
            if(dataGomoku[nonce].Goban[x][y] == dataGomoku[nonce].Goban[x-l][y]){
                countishi_side++;
            }
            else{
                break;
            }
        }
        // 縦負方向に複数同じ石が並んでいるか
        for(uint8 m = 1; m < 5; m++){
            if(m > y){
                break;
            }
            if(dataGomoku[nonce].Goban[x][y] == dataGomoku[nonce].Goban[x][y-m]){
                countishi_ver++;
            }
            else{
                break;
            }
        }
        // 斜め負方向に複数同じ石が並んでいるか
        for(uint8 n = 1; n < 5; n++){
            if(n > x || n > y){
                break;
            }
            if(dataGomoku[nonce].Goban[x][y] == dataGomoku[nonce].Goban[x-n][y-n]){
                countishi_diag++;
            }
            else{
                break;
            }
        }
        // 逆斜め負方向に複数同じ石が並んでいるか
        for(uint8 n = 1; n < 5; n++){
            if(n > x || n > y){
                break;
            }
            if(dataGomoku[nonce].Goban[x][y] == dataGomoku[nonce].Goban[x-n][y-n]){
                countishi_gyakudiag++;
            }
            else{
                break;
            }
        }

        // 打った石の周りで4つ以上が直線で並んでいる場合
        if(countishi_side >= 4 || countishi_ver >= 4 || countishi_diag >= 4)
        {
            returnCount = 4;
        }
        else{
            for(uint8 o = 0; o < 10; o++)
            {
                for(uint8 p = 0; p < 10; p++)
                {
                    // 盤面に空いているマスがあれば継続
                    if(dataGomoku[nonce].Goban[o][p] == 0)
                    {
                        returnCount = 8;
                    }
                }
            }
        }
        return returnCount;
    }

    modifier onlyOwner() {
        require(msg.sender == dataGomoku[nonce].OwnerAddr, "Caller is not GameOwner");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface SGomoku{
    struct GomokuData{
        bool flgGame; // 作成済みフラグ
        bool OpenStatus; //公開状態
        bool flgEnd; //ゲーム終了フラグ
        uint8 PlayerNum; //参加人数
        address OwnerAddr; //オーナーアドレス
        address Player1Addr; //プレイヤー1アドレス
        address Player2Addr; //プレイヤー2アドレス
        address turnPlayerAddr; //手番プレイヤーアドレス
        address winPlayerAddr; //勝利プレイヤーアドレス
        uint8 [10][10] Goban;
        uint8 Version;
    }
}