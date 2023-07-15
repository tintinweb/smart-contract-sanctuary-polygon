// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

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
    // function sendValue(address payable recipient, uint256 amount) internal {
    //     require(
    //         address(this).balance >= amount,
    //         "Address: insufficient balance"
    //     );

    //     (bool success, ) = recipient.call{value: amount}("");
    //     require(
    //         success,
    //         "Address: unable to send value, recipient may have reverted"
    //     );
    // }

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
    // function functionCall(
    //     address target,
    //     bytes memory data
    // ) internal returns (bytes memory) {
    //     return functionCall(target, data, "Address: low-level call failed");
    // }

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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    // function functionStaticCall(
    //     address target,
    //     bytes memory data
    // ) internal view returns (bytes memory) {
    //     return
    //         functionStaticCall(
    //             target,
    //             data,
    //             "Address: low-level static call failed"
    //         );
    // }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    // function functionStaticCall(
    //     address target,
    //     bytes memory data,
    //     string memory errorMessage
    // ) internal view returns (bytes memory) {
    //     require(isContract(target), "Address: static call to non-contract");

    //     (bool success, bytes memory returndata) = target.staticcall(data);
    //     return verifyCallResult(success, returndata, errorMessage);
    // }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    // function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    //     return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    // }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    // function functionDelegateCall(
    //     address target,
    //     bytes memory data,
    //     string memory errorMessage
    // ) internal returns (bytes memory) {
    //     require(isContract(target), "Address: delegate call to non-contract");

    //     (bool success, bytes memory returndata) = target.delegatecall(data);
    //     return verifyCallResult(success, returndata, errorMessage);
    // }

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

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

    // function _msgData() internal view virtual returns (bytes calldata) {
    //     return msg.data;
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import './Context.sol';

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
pragma solidity 0.8.7;

import './IERC20.sol';
import './Address.sol';
import './SafeERC20.sol';
import './ReentrancyGuard.sol';
import './Context.sol';
import './Ownable.sol';

contract PaydeceEscrow is ReentrancyGuard, Ownable {
    // 0.1 es 100 porque se multiplico por mil => 0.1 X 1000 = 100
    uint256 public feeTaker;
    uint256 public feeMaker;
    uint256 public feesAvailableNativeCoin;
    uint256 public timeProcess; //Tiempo que tienen para completar la transaccion

    using SafeERC20 for IERC20;
    mapping(uint => Escrow) public escrows;
    mapping(address => bool) whitelistedStablesAddresses;
    mapping(IERC20 => uint) public feesAvailable;

    event EscrowDeposit(uint indexed orderId, Escrow escrow);
    event EscrowComplete(uint indexed orderId, Escrow escrow);
    event EscrowDisputeResolved(uint indexed orderId);
    event EscrowCancelMaker(uint indexed orderId, Escrow escrow);
    event EscrowCancelTaker(uint indexed orderId, Escrow escrow);
    event EscrowMarkAsPaid(uint indexed orderId, Escrow escrow);

    // Maker defined as who buys usdt
    modifier onlyMaker(uint _orderId) {
        require(
            msg.sender == escrows[_orderId].maker,
            "Only Maker can call this"
        );
        _;
    }

    modifier onlyTaker(uint _orderId) {
        require(
            msg.sender == escrows[_orderId].taker,
            "Only Taker can call this"
        );
        _;
    }

    modifier onlyTakerOrOwner(uint _orderId) {
        require(
            msg.sender == escrows[_orderId].taker || owner() == _msgSender() ,
            "Only Taker can call this"
        );
        // require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    enum EscrowStatus {
        Unknown, //0
        ACTIVE, // 1,
        CRYPTOS_IN_CUSTODY, // 2,
        FIATCOIN_TRANSFERED, // 3, dev un metodo publico owner y taker
        COMPLETED, // 4,
        DELETED, // 5,
        APPEALED, // 6,
        REFUND, // 7,
        RELEASE, // 8
        CANCEL_MAKER, //9
        CANCEL_TAKER  //10
    }

    struct Escrow {
        address payable maker; //Comprador
        address payable taker; //Vendedor
        uint256 value; //Monto compra
        uint256 takerfee; //Comision vendedor
        uint256 makerfee; //Comision comprador
        IERC20 currency; //Moneda
        EscrowStatus status; //Estado
        uint256 created;
    }

    //uint256 private feesAvailable;  // summation of fees that can be withdrawn

    constructor() {
        feeTaker = 0;
        feeMaker = 0;
    }

    // ================== Begin External functions ==================
    function setFeeTaker(uint256 _feeTaker) external onlyOwner {
        require(
            _feeTaker >= 0 && _feeTaker <= (1 * 1000),
            "The fee can be from 0% to 1%"
        );
        feeTaker = _feeTaker;
    }

    function setFeeMaker(uint256 _feeMaker) external onlyOwner {
        require(
            _feeMaker >= 0 && _feeMaker <= (1 * 1000),
            "The fee can be from 0% to 1%"
        );
        feeMaker = _feeMaker;
    }
    
    function setTimeProcess(uint256 _timeProcess) external onlyOwner {
        require(
            timeProcess >= 0 ,
            "The timeProcess can be >= 0"
        );
        timeProcess = _timeProcess;
    }

    /* This is called by the server / contract owner */
    function createEscrow(
        uint _orderId,
        address payable _taker,
        uint256 _value,
        IERC20 _currency
    ) external virtual {
        require(
            escrows[_orderId].status == EscrowStatus.Unknown,
            "Escrow already exists"
        );

        require(
            whitelistedStablesAddresses[address(_currency)],
            "Address Stable to be whitelisted"
        );

        require(msg.sender != _taker, "taker cannot be the same as maker");

        uint8 _decimals = _currency.decimals();
        //Obtiene el monto a transferir desde el comprador al contrato
        uint256 _amountFeeMaker = ((_value * (feeMaker * 10 ** _decimals)) /
            (100 * 10 ** _decimals)) / 1000;

        //Valida el Allowance
        uint256 _allowance = _currency.allowance(msg.sender, address(this));
        require(
            _allowance >= (_value + _amountFeeMaker),
            "Taker approve to Escrow first"
        );

        //Transfer USDT to contract
        _currency.safeTransferFrom(
            msg.sender,
            address(this),
            (_value + _amountFeeMaker)
        );

        escrows[_orderId] = Escrow(
            payable(msg.sender),
            _taker,
            _value,
            feeTaker,
            feeMaker,
            _currency,
            EscrowStatus.CRYPTOS_IN_CUSTODY,
            block.timestamp
        );

        emit EscrowDeposit(_orderId, escrows[_orderId]);
    }

    function createEscrowNativeCoin(
        uint _orderId,
        address payable _taker,
        uint256 _value
    ) external payable virtual {
        require(
            escrows[_orderId].status == EscrowStatus.Unknown,
            "Escrow already exists"
        );

        require(msg.sender != _taker, "Taker cannot be the same as maker");

        uint8 _decimals = 18;
        //Obtiene el monto a transferir desde el comprador al contrato
        uint256 _amountFeeMaker = ((_value * (feeMaker * 10 ** _decimals)) /
            (100 * 10 ** _decimals)) / 1000;

        require((_value + _amountFeeMaker) <= msg.value, "Incorrect amount");

        escrows[_orderId] = Escrow(
            payable(msg.sender),
            _taker,
            _value,
            feeTaker,
            feeMaker,
            IERC20(address(0)),
            EscrowStatus.CRYPTOS_IN_CUSTODY,
            block.timestamp
        );

        emit EscrowDeposit(_orderId, escrows[_orderId]);
    }

    function releaseEscrowOwner(uint _orderId) external onlyOwner {
        _releaseEscrow(_orderId);
    }

    function releaseEscrowOwnerNativeCoin(uint _orderId) external onlyOwner {
        _releaseEscrowNativeCoin(_orderId);
    }

    /* This is called by the maker wallet */
    function releaseEscrow(uint _orderId) external onlyMaker(_orderId) {
        _releaseEscrow(_orderId);
    }

    function releaseEscrowNativeCoin(
        uint _orderId
    ) external onlyMaker(_orderId) {
        _releaseEscrowNativeCoin(_orderId);
    }

    /// release funds to the maker - cancelled contract
    function refundMaker(uint _orderId) external nonReentrant onlyOwner {
        //require(escrows[_orderId].status == EscrowStatus.Refund,"Refund not approved");

        uint256 _value = escrows[_orderId].value;
        address _maker = escrows[_orderId].maker;
        IERC20 _currency = escrows[_orderId].currency;        

        _currency.safeTransfer(_maker, _value);

        emit EscrowDisputeResolved(_orderId);
    }

    function refundMakerNativeCoin(
        uint _orderId
    ) external nonReentrant onlyOwner {
        //require(escrows[_orderId].status == EscrowStatus.Refund,"Refund not approved");

        uint256 _value = escrows[_orderId].value;
        address _maker = escrows[_orderId].maker;


        //Transfer call
        (bool sent, ) = payable(address(_maker)).call{value: _value}("");
        require(sent, "Transfer failed.");

        emit EscrowDisputeResolved(_orderId);
    }

    function withdrawFees(IERC20 _currency) external onlyOwner {
        uint _amount;

        // This check also prevents underflow
        require(feesAvailable[_currency] > 0, "Amount > feesAvailable");

        _amount = feesAvailable[_currency];

        feesAvailable[_currency] -= _amount;

        _currency.safeTransfer(owner(), _amount);
    }

    function withdrawFeesNativeCoin() external onlyOwner {
        uint256 _amount;

        // This check also prevents underflow
        require(feesAvailableNativeCoin > 0, "Amount > feesAvailable");

        //_amount = feesAvailable[_currency];
        _amount = feesAvailableNativeCoin;

        feesAvailableNativeCoin -= _amount;

        //Transfer
        (bool sent, ) = payable(msg.sender).call{value: _amount}("");
        require(sent, "Transfer failed.");
    }

    // ================== End External functions ==================

    // ================== Begin External functions that are pure ==================
    function version() external pure virtual returns (string memory) {
        return "4.0.0";
    }

    // ================== End External functions that are pure ==================

    /// ================== Begin Public functions ==================
    function addStablesAddresses(
        address _addressStableToWhitelist
    ) public onlyOwner {
        whitelistedStablesAddresses[_addressStableToWhitelist] = true;
    }

    function delStablesAddresses(
        address _addressStableToWhitelist
    ) public onlyOwner {
        whitelistedStablesAddresses[_addressStableToWhitelist] = false;
    }

    function CancelMaker(uint256 _orderId) public nonReentrant onlyMaker(_orderId){
        // Valida el estado de la Escrow
        require( escrows[_orderId].status == EscrowStatus.CRYPTOS_IN_CUSTODY , "El estado tiene que ser CRYPTOS_IN_CUSTODY" );

        uint256 _timeDiff = block.timestamp - escrows[_orderId].created;

        // validacióm de tiempo de proceso
        require(_timeDiff > timeProcess, "El tiempo todavia llego a su termino" );

        // cambio de estado
        escrows[_orderId].status = EscrowStatus.CANCEL_MAKER;

        //Transfer to maker
        escrows[_orderId].currency.safeTransfer(
            escrows[_orderId].maker,
            escrows[_orderId].value
        );

        // emite evento
        emit EscrowCancelMaker(_orderId, escrows[_orderId]);
    }

    function CancelTaker(uint256 _orderId) public nonReentrant onlyTaker(_orderId){
        // Valida el estado de la Escrow
        require( escrows[_orderId].status == EscrowStatus.CRYPTOS_IN_CUSTODY , "El estado tiene que ser CRYPTOS_IN_CUSTODY" );

        // cambio de estado
        escrows[_orderId].status = EscrowStatus.CANCEL_TAKER;

        //Transfer to maker
        escrows[_orderId].currency.safeTransfer(
            escrows[_orderId].maker,
            escrows[_orderId].value
        );

        // emite evento
        emit EscrowCancelTaker(_orderId, escrows[_orderId]);
    }

    function setMarkAsPaid(uint256 _orderId) public onlyTakerOrOwner(_orderId){
        // Valida el estado de la Escrow
        require( escrows[_orderId].status == EscrowStatus.CRYPTOS_IN_CUSTODY , "El estado tiene que ser CRYPTOS_IN_CUSTODY" );

        escrows[_orderId].status = EscrowStatus.FIATCOIN_TRANSFERED;

        // emite evento
        emit EscrowMarkAsPaid(_orderId, escrows[_orderId]);
    }

    /// ================== End Public functions ==================

    // ================== Begin Private functions ==================
    function _releaseEscrow(uint _orderId) private nonReentrant {
        require(
            escrows[_orderId].status == EscrowStatus.FIATCOIN_TRANSFERED,
            "El estado tiene que estar en FIATCOIN_TRANSFERED"
        );

        uint8 _decimals = escrows[_orderId].currency.decimals();

        //Obtiene el monto a transferir desde el comprador al contrato        //takerfee //makerfee
        uint256 _amountFeeMaker = ((escrows[_orderId].value *
            (escrows[_orderId].makerfee * 10 ** _decimals)) /
            (100 * 10 ** _decimals)) / 1000;
        uint256 _amountFeeTaker = ((escrows[_orderId].value *
            (escrows[_orderId].takerfee * 10 ** _decimals)) /
            (100 * 10 ** _decimals)) / 1000;

        //feesAvailable += _amountFeeMaker + _amountFeeTaker;
        feesAvailable[escrows[_orderId].currency] +=
            _amountFeeMaker +
            _amountFeeTaker;

        // write as complete, in case transfer fails
        escrows[_orderId].status = EscrowStatus.COMPLETED;

        //Transfer to taker Price Asset - FeeTaker
        escrows[_orderId].currency.safeTransfer(
            escrows[_orderId].taker,
            escrows[_orderId].value - _amountFeeTaker
        );

        emit EscrowComplete(_orderId, escrows[_orderId]);
        
    }

    function _releaseEscrowNativeCoin(uint _orderId) private nonReentrant {
        require(
            escrows[_orderId].status == EscrowStatus.CRYPTOS_IN_CUSTODY,
            "USDT has not been deposited"
        );

        uint8 _decimals = 18; //Wei

        //Obtiene el monto a transferir desde el comprador al contrato        //takerfee //makerfee
        uint256 _amountFeeMaker = ((escrows[_orderId].value *
            (escrows[_orderId].makerfee * 10 ** _decimals)) /
            (100 * 10 ** _decimals)) / 1000;
        uint256 _amountFeeTaker = ((escrows[_orderId].value *
            (escrows[_orderId].takerfee * 10 ** _decimals)) /
            (100 * 10 ** _decimals)) / 1000;

        //Registra los fees obtenidos para Paydece
        feesAvailableNativeCoin += _amountFeeMaker + _amountFeeTaker;

        // write as complete, in case transfer fails
        escrows[_orderId].status = EscrowStatus.COMPLETED;

        //Transfer to taker Price Asset - FeeTaker
        (bool sent, ) = escrows[_orderId].taker.call{
            value: escrows[_orderId].value - _amountFeeTaker
        }("");
        require(sent, "Transfer failed.");

        emit EscrowComplete(_orderId, escrows[_orderId]);
        
    }
    // ================== End Private functions ==================
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import './Address.sol';
import './IERC20.sol';

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    // function safeApprove(
    //     IERC20 token,
    //     address spender,
    //     uint256 value
    // ) internal {
    //     // safeApprove should only be called when setting an initial allowance,
    //     // or when resetting it to zero. To increase and decrease it, use
    //     // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    //     require(
    //         (value == 0) || (token.allowance(address(this), spender) == 0),
    //         "SafeERC20: approve from non-zero to non-zero allowance"
    //     );
    //     _callOptionalReturn(
    //         token,
    //         abi.encodeWithSelector(token.approve.selector, spender, value)
    //     );
    // }

    // function safeIncreaseAllowance(
    //     IERC20 token,
    //     address spender,
    //     uint256 value
    // ) internal {
    //     uint256 newAllowance = token.allowance(address(this), spender) + value;
    //     _callOptionalReturn(
    //         token,
    //         abi.encodeWithSelector(
    //             token.approve.selector,
    //             spender,
    //             newAllowance
    //         )
    //     );
    // }

    // function safeDecreaseAllowance(
    //     IERC20 token,
    //     address spender,
    //     uint256 value
    // ) internal {
    //     unchecked {
    //         uint256 oldAllowance = token.allowance(address(this), spender);
    //         require(
    //             oldAllowance >= value,
    //             "SafeERC20: decreased allowance below zero"
    //         );
    //         uint256 newAllowance = oldAllowance - value;
    //         _callOptionalReturn(
    //             token,
    //             abi.encodeWithSelector(
    //                 token.approve.selector,
    //                 spender,
    //                 newAllowance
    //             )
    //         );
    //     }
    // }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}