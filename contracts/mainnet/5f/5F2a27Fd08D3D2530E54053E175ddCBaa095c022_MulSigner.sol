// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.9;

import "../utils/ContextUpgradeable.sol";
import "../upgrade/utils/Initializable.sol";

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * @title Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


import "./IERC20.sol";
import "../utils/SafeMath.sol";
import "../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.9;

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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.9;

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
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC1967.sol)

pragma solidity ^0.8.9;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.8.3._
 */
interface IERC1967Upgradeable {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.9;

import "../utils/MulSigners.sol";
import "../utils/MulTx.sol";

interface IERCMulSigner {
    event CreateMulSigner(address sender, uint txHash, string  txId);

    event ForceOverMulSigner(address sender, uint txHash);

    event ApproveMulSigner(address sender, uint txHash, string txId);

    event StartMulSigner(address sender, uint txHash, string txId);

    event RejectMulSigner(uint txHash, string txId);

    event ExecuteMulSigner(uint txHash, string txId);

    enum SignerOp {
        Approve,
        Reject
    }

    //创建多签
    function createMulSignerTx(
        uint amount,
        uint when,
        address to,
        string memory blank,
        MulTx.TxType txType,
        string calldata txId
    ) external payable;

    function createMulSignerTxWithSiger(
        uint amount,
        uint when,
        address to,
        string memory blank,
        MulTx.TxType txType,
        string calldata txId,
        address owner
    ) external payable;

    //结束多签
    function forceOverMulSigner(uint txHash) external;

    // 提交签名
    function submitMulSigner(uint txHash, IERCMulSigner.SignerOp op) external;

     //审核多签
    function startMulSigner(uint txHash) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)
import "../utils/MulTx.sol";

pragma solidity ^0.8.9;


interface IERCReceiveMulSigner {
    function receiveMulSigner(MulTx.Mtx memory mtx) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.9;

interface IERCSignerManage {
    struct Signer {
        address[] Signers;
        uint threshold;

    }

    event CreateSigner(address[] Signer, uint threshold,address sender, uint256 indexed userId,string[] names);
    event CreateOwnSigner(address[] Signer, uint threshold,address sender, uint256 indexed userId,string[] names);

    event AddSigner(address Signer,address sender,uint txHash);

    event RemoveSigner(address Signer,address sender,uint txHash);

    //设置多签账号
     function setSigners(address[] memory Signer,string[] memory names, uint threshold,uint256 userId) external;
     function setSignersWithOwner(address[] memory Signer,string[] memory names, address owner, uint threshold,uint256 userId) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./upgrade/utils/UUPSUpgradeable.sol";
import "./access/OwnableUpgradeable.sol";
import "./utils/MulSigners.sol";
import "./utils/MulTx.sol";
import "./interfaces/IERCMulSigner.sol";
import "./utils/CountersUpgradeable.sol";
import "./interfaces/IERCSignerManage.sol";
import "./ERC20/SafeERC20.sol";
import "./utils/Address.sol";
import "./ERC20/IERC20.sol";
import "./interfaces/IERC165Upgradeable.sol";
import "./interfaces/IERCReceiveMulSigner.sol";

/// @title MulSigner
///@author li
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details 
contract MulSigner is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    IERCMulSigner,
    IERCSignerManage
{
    using MulSigners for MulSigners.Signer;
    using MulTx for MulTx.Mtx;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeERC20 for IERC20;

    bytes4 private constant RECEVER_SIGER =
        bytes4(keccak256("registerMulSigner(IERCReceiveMulSigner receiver)"));
    CountersUpgradeable.Counter private counter;

    address public admin;
    uint256 fee;
    address payToken;

    // xthash==>Signer
    mapping(uint => MulSigners.Signer) public mulSigners;

    //xthash=>tx
    mapping(uint => MulTx.Mtx) public mulTx;

    //address =>Signer
    mapping(address => IERCSignerManage.Signer) public Signers;

    //address=>xthash  address own txhash
    mapping(address => uint[]) public SignerTxHash;
    // txid =>txhash
    mapping(string => uint) public txhashs;
    // address =>txhash  address push txhash
    mapping(address => uint[]) public SignerSendTxHash;

    function initialize(
        address txAdmin,
        uint256 _fee,
        address _payToken
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        require(
            Address.isContract(_payToken) || _payToken == address(0),
            "token address is wrong"
        );
        admin = txAdmin;
        fee = _fee * (0.1 * 1 ether);
        payToken = _payToken;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin || msg.sender == owner(), "Only admin");
        _;
    }

    modifier txUnOver(uint txHash) {
        MulSigners.Signer storage Signer = mulSigners[txHash];
        require(
            Signer.status == MulSigners.SignerStatus.Created ||
                Signer.status == MulSigners.SignerStatus.Pending,
            "Signer is finished"
        );
        _;
    }

    function checkImplReceiverContract(
        address receiver
    ) internal view returns (bool) {
        IERC165Upgradeable erc165 = IERC165Upgradeable(receiver);
        return erc165.supportsInterface(RECEVER_SIGER);
    }

    function SignerValid(
        address Signer,
        MulTx.TxType txType
    ) private view returns (bool ret) {
        if (txType == MulTx.TxType.AddSigner) {
            if (Signers[msg.sender].Signers.length >= 10) {
                revert("Signer is too big");
            }
            // judge Signers[msg.sender] is not contain Signer
            for (uint i = 0; i < Signers[msg.sender].Signers.length; i++) {
                if (Signers[msg.sender].Signers[i] == Signer) {
                    revert("Signer is exist");
                }
            }
        }
        if (txType == MulTx.TxType.RemoveSigner) {
            if (Signers[msg.sender].Signers.length <= 1) {
                revert("Signer is too small");
            }
            bool isContain = false;
            // judge Signers[msg.sender] is  no contain Signer
            for (uint i = 0; i < Signers[msg.sender].Signers.length; i++) {
                if (Signers[msg.sender].Signers[i] == Signer) {
                    isContain = true;
                }
            }
            if (!isContain) {
                revert("Signer is no exist");
            }
        }
        return true;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    //writer a createMulSigner function  param with Signers address arrary and txParams withb MulTx.Mtx struct的filed to create MulTx.Mtx and  MulSigner
    function createMulSignerTx(
        uint amount,
        uint when,
        address to,
        string memory blank,
        MulTx.TxType txType,
        string calldata txId
    ) external payable override {
        address owner = msg.sender;
        require(txhashs[txId] == 0, "txId is exist");
        string memory _txId= txId;
        require(SignerValid(to, txType), "Signer is invalid");
        if (payToken == address(0)) {
            require(msg.value >= fee, "insufficient funds");
        } else {
            IERC20(payToken).safeTransferFrom(msg.sender, address(this), fee);
        }
     uint256 txHash=_createMulSigerTx(amount, when, to, blank, txType, _txId, owner);
            txhashs[txId] = txHash;
               emit CreateMulSigner(owner,txHash, txId);
    }


    function createMulSignerTxWithSiger(
              uint amount,
        uint when,
        address to,
        string memory blank,
        MulTx.TxType txType,
        string calldata txId,
        address owner
    )external payable override{
         require(txhashs[txId] == 0, "txId is exist");
                 string memory _txId= txId;
        require(SignerValid(to, txType), "Signer is invalid");
        if (payToken == address(0)) {
            require(msg.value >= fee, "insufficient funds");
        } else {
            IERC20(payToken).safeTransferFrom(msg.sender, address(this), fee);
        }
       uint256 txHash=_createMulSigerTx(amount, when, to, blank, txType, _txId, owner);
            txhashs[txId] = txHash;
               emit CreateMulSigner(owner,txHash,_txId);

    }
    function _createMulSigerTx(
         uint amount,
        uint when,
        address to,
        string memory blank,
        MulTx.TxType txType,
         string memory txId,
        address owner
    ) internal returns(uint256 txHash ){
         IERCSignerManage.Signer storage Signer = Signers[owner];
        if (Signer.Signers.length == 0) {
            revert("Signer is empty");
        }
        counter.increment();
        MulTx.Mtx memory mtx = MulTx.initialize(
            msg.sender,
            to,
            txType,
            counter.current(),
            txId,
            amount,
            when,
            blank
        );
        mulTx[mtx.txHash] = mtx;
        //judge SignerSendTxHash[msg.sender] do not contain mtx.txhash
        for (uint i = 0; i < SignerSendTxHash[owner].length; i++) {
            if (SignerSendTxHash[owner][i] == mtx.txHash) {
                revert("txhash is exist");
            }
        }

        MulSigners.Signer storage SignerTx = mulSigners[mtx.txHash];
        SignerTx.initialize(
            Signer.Signers,
            mtx.txHash,
            Signer.threshold,
            mtx.when
        );
        txHash=    mtx.txHash;

        SignerSendTxHash[owner].push(mtx.txHash);
        if (txType != MulTx.TxType.FiatWithDraw &&  txType!=MulTx.TxType.CryptoWithDraw) {
            _startMulSigner(SignerTx, txHash);
        }

    }

    //add address  and txhash  to SignerTxHash map's txhash array,but txhash array has a unique value
    function addSignerTxHash(address Signer, uint txHash) internal {
        uint[] storage txHashs = SignerTxHash[Signer];
        for (uint i = 0; i < txHashs.length; i++) {
            if (txHashs[i] == txHash) {
                return;
            }
        }
        txHashs.push(txHash);
    }

    //force to over mul Signer by TxHash
    //wirte  the forceOverMulSigner  method comment
    ///@param TxHash @type uint @description tx hash
    function forceOverMulSigner(
        uint TxHash
    ) external override onlyAdmin txUnOver(TxHash) {
        MulSigners.Signer storage Signer = mulSigners[TxHash];
        Signer.overSigner();
        emit ForceOverMulSigner(msg.sender, TxHash);
    }

    //query current Signer unsing mtx list  return  MulTx.Mtxa
    function getSignerMtxs(
        address Signer
    ) external view returns (MulTx.Mtx[] memory) {
        uint[] storage txHashs = SignerTxHash[Signer];
        MulTx.Mtx[] memory mtxs = new MulTx.Mtx[](txHashs.length);
        for (uint i = 0; i < txHashs.length; i++) {
            mtxs[i] = mulTx[txHashs[i]];
        }
        return mtxs;
    }

    // Signer to approve mul Signer by TxHash
    function submitMulSigner(
        uint txHash,
        IERCMulSigner.SignerOp op
    ) external override {
        MulSigners.Signer storage Signer = mulSigners[txHash];
        require(!Signer.isSignerFinished(), "Signer is finished");
        require(
            Signer.getSignerStatusBySigner(msg.sender) ==
                MulSigners.SignerStatus.Created,
            "Signer is not Created"
        );
        require(Signer.hasSigner(msg.sender), "Signer is not in Signer list");
        if (op == IERCMulSigner.SignerOp.Approve) {
            Signer.setSignerResult(
                msg.sender,
                MulSigners.SignerStatus.Approved
            );
        } else {
            Signer.setSignerResult(
                msg.sender,
                MulSigners.SignerStatus.Rejected
            );
        }
        MulTx.Mtx memory mtx = mulTx[txHash];
        if (Signer.isSignerFinished()) {
            Signer.setSignerStatus();
            if (Signer.getSignerStatus() == MulSigners.SignerStatus.Approved) {
                IERCSignerManage.Signer storage SignerManage = Signers[
                    mtx.from
                ];
                if (mtx.txType == MulTx.TxType.AddSigner) {
                    if (Signer.hasSigner(mtx.to)) {
                        revert("Signer is exist");
                    }
                    //add mtx.to to Signers
                    SignerManage.Signers.push(mtx.to);
                    SignerManage.threshold = SignerManage.threshold + 1;
                    emit AddSigner(mtx.to, mtx.from,txHash);
                } else if (mtx.txType == MulTx.TxType.RemoveSigner) {
                    if (!Signer.hasSigner(mtx.to)) {
                        revert("Signer is  no exist");
                    }
                    for (uint i = 0; i < SignerManage.Signers.length; i++) {
                        if (SignerManage.Signers[i] == mtx.to) {
                            SignerManage.Signers[i] = SignerManage.Signers[
                                SignerManage.Signers.length - 1
                            ];
                            SignerManage.Signers.pop();
                            break;
                        }
                    }
                    SignerManage.threshold = SignerManage.threshold - 1;
                    emit RemoveSigner(mtx.to, mtx.from,txHash);
                } else {
                    if (
                        Address.isContract(mtx.from) &&
                        checkImplReceiverContract(mtx.from) &&
                        mtx.txType == MulTx.TxType.CryptoWithDraw
                    ) {
                        IERCReceiveMulSigner(mtx.from).receiveMulSigner(mtx);
                    }
                    emit ExecuteMulSigner(txHash, mtx.txId);
                }
            } else if (
                Signer.getSignerStatus() == MulSigners.SignerStatus.Rejected
            ) {
                emit RejectMulSigner(txHash, mtx.txId);
            }
        }
        completeExpireTx(msg.sender);
        emit ApproveMulSigner(msg.sender, txHash, mtx.txId);
    }

    function completeExpireTx(address sender) private {
        uint[] storage txHashs = SignerSendTxHash[sender];
        uint length = txHashs.length > 10 ? 10 : txHashs.length;
        for (uint i = 0; i < length; i++) {
            MulSigners.Signer storage Signer = mulSigners[txHashs[i]];
            if (
                Signer.status == MulSigners.SignerStatus.Created ||
                Signer.status == MulSigners.SignerStatus.Pending
            ) {
                if (Signer.getSignerExpire() < block.timestamp) {
                    Signer.overSigner();
                }
            }
        }
    }

    function startMulSigner(uint txHash) external override onlyAdmin {
        require(txHash != 0, "txHash is zero");
        MulSigners.Signer storage Signer = mulSigners[txHash];

        require(
            Signer.status == MulSigners.SignerStatus.Created,
            "Signer is had start"
        );
        require(
            Signer.getSignerExpire() > block.timestamp,
            "Signer is expired"
        );
        _startMulSigner(Signer,txHash);
        
    }
    function _startMulSigner(MulSigners.Signer storage Signer,uint txHash) internal {
         MulTx.Mtx storage mtx = mulTx[txHash];
        require(mtx.txHash == txHash, "txHash is not exist");
        Signer.StartSigner();
        for (uint i = 0; i < Signer.Signers.length; i++) {
            addSignerTxHash(Signer.Signers[i], txHash);
        }
        emit StartMulSigner(msg.sender, txHash, mtx.txId);

    }

    function _setSinger(
        address[] memory Signer,
        string[] memory  Names,
        address owner,
        uint threshold,
        uint256 userId
) internal {
        require(Signer.length > 1, "Signer is empty");
        require(threshold > 0, "Threshold is zero");
        require(Signer.length >= threshold, "Threshold is bigger than Signer");
        require(Signer.length <= 10, "Signer is bigger than 10");
        require(Signers[owner].Signers.length == 0, "Signer is not empty");
        require(Signer.length == Names.length, "Signer is not equal names");
        require(userId > 0, "user id is no");
        //require Signer items is unique
        for (uint i = 0; i < Signer.length; i++) {
            for (uint j = i + 1; j < Signer.length; j++) {
                if (Signer[i] == Signer[j]) {
                    revert("Signer is not unique");
                }
            }
        }
        IERCSignerManage.Signer storage SignerManage = Signers[owner];
        SignerManage.Signers = Signer;
        SignerManage.threshold = threshold;

    }

    function setSigners(
        address[] memory Signer,
        string[] memory  names,
        uint threshold,
        uint256 userId
    ) external override {
        address owner = msg.sender;
        _setSinger(Signer, names,owner, threshold, userId);
        emit CreateSigner(Signer, threshold, owner, userId,names);
    }

    function setSignersWithOwner(
        address[] memory Signer,
        string[] memory  names,
        address owner,
        uint threshold,
        uint256 userId
    ) external {
        _setSinger(Signer, names,owner, threshold, userId);
        emit CreateOwnSigner(Signer, threshold, owner, userId,names);
    }

    function getSigner(
        address Signer
    ) external view returns (address[] memory) {
        return Signers[Signer].Signers;
    }

    ///todo: only test
    function getExpireTime(uint txHash) external view returns (uint) {
        MulSigners.Signer storage Signer = mulSigners[txHash];
        return Signer.getSignerExpire();
    }

    function getMulTxSigner(
        uint txhash
    ) external view returns (address[] memory) {
        address[] memory s = mulSigners[txhash].Signers;
        return s;
    }

    function getMux(uint txhash) external view returns (MulTx.Mtx memory) {
        return mulTx[txhash];
    }

    function getSenderTxHash(
        address sender
    ) external view returns (uint[] memory) {
        //返回未签名状态未完成的交易
        uint[] memory txHashs = SignerSendTxHash[sender];
        uint[] memory txHashs1 = new uint[](txHashs.length);
        uint j = 0;
        for (uint i = 0; i < txHashs.length; i++) {
            MulSigners.Signer storage Signer = mulSigners[txHashs[i]];
            if (
                Signer.status == MulSigners.SignerStatus.Created ||
                Signer.status == MulSigners.SignerStatus.Pending
            ) {
                txHashs1[j] = txHashs[i];
                j++;
            }
        }
        return txHashs1;
    }

    function getSenderTxCompleteHash(
        address sender
    ) external view returns (uint[] memory) {
        //返回签名状态完成的交易
        uint[] storage txHashs = SignerSendTxHash[sender];
        uint length = txHashs.length > 5 ? 5 : txHashs.length;
        uint[] memory txHashs1 = new uint[](length);
        uint j = 0;
        for (uint i = 1; i < length + 1; i++) {
            MulSigners.Signer storage Signer = mulSigners[
                txHashs[txHashs.length - i]
            ];
            if (
                Signer.status == MulSigners.SignerStatus.Approved ||
                Signer.status == MulSigners.SignerStatus.Rejected ||
                Signer.status == MulSigners.SignerStatus.Executed
            ) {
                txHashs1[j] = txHashs[txHashs.length - i];
                j++;
            }
        }
        return txHashs1;
    }

    function getSignerStatus(
        uint txHash
    ) external view returns (MulSigners.SignerStatus) {
        MulSigners.Signer storage Signer = mulSigners[txHash];
        return Signer.getSignerStatus();
    }

    function getSignerNum(uint txHash) external view returns (uint) {
        MulSigners.Signer storage Signer = mulSigners[txHash];
        return Signer.getSingedNum();
    }

    function getSignerThreshold(address owner) external view returns (uint) {
        IERCSignerManage.Signer storage Signer = Signers[owner];
        return Signer.threshold;
    }

    function WithDrawFee(uint amount) external onlyOwner {
        if (payToken == address(0)) {
            require(address(this).balance >= amount, "Insufficient balance");
            payable(msg.sender).transfer(amount);
        } else {
            require(
                IERC20(payToken).balanceOf(address(this)) >= amount,
                "Insufficient balance"
            );
            IERC20(payToken).safeTransfer(msg.sender, amount);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.9;

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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.9;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/IERC1967Upgradeable.sol";
import "../../interfaces/IERC1822ProxiableUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable, IERC1967Upgradeable {
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
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
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
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.9;

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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.9;

import "../../interfaces/IERC1822ProxiableUpgradeable.sol";
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
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeTo(address newImplementation) public virtual onlyProxy {
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
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.9;

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.9;
import "../upgrade/utils/Initializable.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.9;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (MulSigners.sol)

pragma solidity ^0.8.9;


library MulSigners {
    enum SignerStatus {Created,Pending,Approved,Rejected,Executed}


    struct Signer {
        address[] Signers;
        uint txHash;
        uint threshold;
        uint   expire;
        SignerStatus status;
       mapping(address=>SignerStatus) SignerResult;
    }

    function addSigner(Signer storage self,address signer) internal {
        self.Signers.push(signer);
    }
    function getSigner(Signer storage self,uint256 index) internal view returns(address){
        return self.Signers[index];
    }
    function getSignerLength(Signer storage self) internal view returns(uint256){
        return self.Signers.length;
    }
    function setTxHash(Signer storage self,uint256 TxHash) internal {
        self.txHash=TxHash;
    }
    function getTxHash(Signer storage self) internal view returns(uint256){
        return self.txHash;
    }
    function setThreshold(Signer storage self,uint256 Threshold) internal {
        self.threshold=Threshold;
    }
    function getThreshold(Signer storage self) internal view returns(uint256){
        return self.threshold;
    }

    function initialize(Signer storage self,address[] memory Signers,uint TxHash,uint Threshold,uint expire) internal {
        for(uint256 i=0;i<Signers.length;i++){
            self.Signers.push(Signers[i]);
        }
        self.txHash=TxHash;
        self.threshold=Threshold;
        self.expire=expire;
        self.status=SignerStatus.Created;
    }

    function setSignerResult(Signer storage self,address signer,SignerStatus status) internal {
         if(self.status != SignerStatus.Pending){
            revert("Signer is not pending");
         }
        self.SignerResult[signer]=status;
    }
    function getSignerApprovedNum(Signer storage self) internal view returns(uint256){
        uint256 num=0;
        for(uint256 i=0;i<self.Signers.length;i++){
            if(self.SignerResult[self.Signers[i]]==SignerStatus.Approved){
                num++;
            }
        }
        return num;
    }

//Get the number of people who have signed
    function getSingedNum(Signer storage self) internal view returns(uint256){
        uint256 num=0;
        for(uint256 i=0;i<self.Signers.length;i++){
            if(self.SignerResult[self.Signers[i]]!=SignerStatus.Created){
                num++;
            }
        }
        return num;
    }
    //Judging whether the signature has ended according to whether it has expired or whether the number of signers is greater than the threshold
    function isSignerFinished(Signer storage self) internal view returns(bool){
         if(self.status != SignerStatus.Pending){
            return true;
         }
        if(block.timestamp>self.expire){
            return true;
        }
        if(getSingedNum(self)>=self.threshold && (isSignerApproved(self)||isSignerReject(self))){
            return true;
        }
        return false;
    }
    function isSignerReject(Signer storage self) internal view returns(bool){
           if(getSignerRejectNum(self)>=self.threshold){
            return true;
        }
        return false;
    }
    function getSignerRejectNum(Signer storage self) internal view returns(uint256){
        uint256 num=0;
        for(uint256 i=0;i<self.Signers.length;i++){
            if(self.SignerResult[self.Signers[i]]==SignerStatus.Rejected){
                num++;
            }
        }
        return num;
    }
    // Judging whether the signature is agreed or rejected according to whether the number of signed Approved is greater than the threshold
    function isSignerApproved(Signer storage self) internal view returns(bool){
        if(getSignerApprovedNum(self)>=self.threshold){
            return true;
        }
        return false;
    }
    function StartSigner(Signer storage self) internal {
        self.status=SignerStatus.Pending;
    }

    function getUnSigner(Signer storage self) internal view returns(address[] memory){
        address[] memory unSigners=new address[](self.Signers.length);
        uint256 index=0;
        for(uint256 i=0;i<self.Signers.length;i++){
            if(self.SignerResult[self.Signers[i]]==SignerStatus.Created){
                unSigners[index]=self.Signers[i];
                index++;
            }
        }
        return unSigners;
    }

    function getAllSigner(Signer storage self) internal view returns(address[] memory){
        address[] memory allSigners=new address[](self.Signers.length);
        for(uint256 i=0;i<self.Signers.length;i++){
            allSigners[i]=self.Signers[i];
        }
        return allSigners;
    }

    // force to over Signer with rejiect
    function overSigner(Signer storage self) internal {
          if(self.status==SignerStatus.Executed || self.status==SignerStatus.Rejected|| self.status==SignerStatus.Approved){
           revert("Signer is executed");
        }
        self.status=SignerStatus.Rejected;
    }
  //judge current Signer lastest status and set status
    function setSignerStatus(Signer storage self) internal {
        if(self.status==SignerStatus.Executed){
           revert("Signer is executed");
        }
        if(self.status==SignerStatus.Pending){
                if(isSignerApproved(self)){
                    self.status=SignerStatus.Approved;
                }else{
                    self.status=SignerStatus.Rejected;
                }
            
        }
    }
    function getSignerStatus(Signer storage self) internal view returns(SignerStatus){
        return self.status;
    }
    function getSignerStatusBySigner(Signer storage self,address signer) internal view returns(SignerStatus){
        return self.SignerResult[signer];
    }
    function getSignerExpire(Signer storage self) internal view returns(uint256){
        return self.expire;
    }
    function setSignerExpire(Signer storage self,uint256 expire) internal {
        self.expire=expire;
    }

    function hasSigner(Signer storage self,address signer) internal view returns(bool){
        for(uint256 i=0;i<self.Signers.length;i++){
            if(self.Signers[i]==signer){
                return true;
            }
        }
        return false;
    }




}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (MulTx.sol)

pragma solidity ^0.8.9;

library MulTx {

    enum TxType{
        FiatWithDraw,
        CryptoWithDraw,
        AddSigner,
        RemoveSigner,
        LimitQuota,
        BizConfigChange
    }
    /**
     *@dev 交易结构体
     * 根据TxType的不同，交易结构体的字段不同
     * 1.法币提现交易， blank字段为银行卡号，amount为提现金额，to 暂时没用，from为发起地址
     * 2.数字货币提现交易， blank字段是提取代币名称例如"MATIC","USDT"，amount为提现金额，to 提取账户地址，from为发起地址 blank字段为银行卡号
     * 3.添加签名人交易， blank字段没用，amount为0，to 新增的签名人地址，from为发起地址 
     * 4. 删除签名人交易， blank字段没用，amount为0，to 被删除的签名人地址，from为发起地址
     * 5. 限额交易， blank字段没用，amount为限额，to 暂时没用，from为发起地址
     * 6. 业务配置交易变更， blank字段没用，amount为业务配置的value，to 暂时没用，from为发起地址: value的编码，为 按位进行 如果是两项就表示,每一位代表一个业务 10/00/11/01  1表示开启 0表示关闭
      * 另外 业务配置 目前 有两个配置项 1.法币提现 2.加密提现
     */
    struct Mtx{
      string  blank;
      string  txId;
      uint amount;
      uint when;
      address to;
      address from;
      uint index;
      TxType txType;
      uint txHash;
   }

   function initialize(address from,address to,TxType txType,uint index, string memory txId,uint amount,uint when,string memory blank) internal  view returns ( Mtx memory){
         if((txType==TxType.FiatWithDraw || txType==TxType.CryptoWithDraw) && amount==0){
             revert("amount is zero");
         }
         if((txType==TxType.CryptoWithDraw|| txType==TxType.AddSigner|| txType==TxType.RemoveSigner) && to==address(0)){
             revert("to is zero");
         }
        if(txType==TxType.FiatWithDraw && bytes(blank).length==0){
            revert("blank is empty");
        }
        if(txType==TxType.FiatWithDraw && bytes(blank).length>0){
            if(bytes(blank).length>50){
                revert("blank is too long");
            }
        }
        require(when > block.timestamp && when < block.timestamp + 7 days, "when is before current time");

       Mtx memory self;
       self.amount=amount;
       self.when=when;
       self.to=to;
       self.txType=txType;
       self.index=index;
       self.txId=txId;
       self.from=from;
       self.blank=blank;
       self.txHash=uint(getTxkeccak256Hash(self));
       return self;
   }
   function getTxkeccak256Hash(Mtx memory self) internal pure returns(bytes32){
       return keccak256(abi.encode(self.amount,self.when,self.to,self.txType, self.index, self.txId,keccak256(abi.encode(self.blank))));
   }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.9;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
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
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
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

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
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

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}