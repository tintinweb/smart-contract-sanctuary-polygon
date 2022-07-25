//  SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0;

import './interfaces/IUserProxyFactory.sol';
import './UserProxy.sol';

contract UserProxyFactory is IUserProxyFactory {
    mapping(address => address) public override getProxy;


    function createProxy(address owner,address lendingPool) external override returns (address proxy) {
        require(owner != address(0), 'ZERO_ADDRESS');
        require(getProxy[owner] == address(0), 'PROXY_EXISTS');
        bytes memory bytecode = proxyCreationCode();
        bytes32 salt = keccak256(abi.encodePacked(address(this), owner));
        assembly {
            proxy := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IUserProxy(proxy).initialize(owner,lendingPool);
        getProxy[owner] = proxy;
        emit ProxyCreated(owner, proxy);
    }

    function proxyRuntimeCode() public pure returns (bytes memory) {
        return type(UserProxy).runtimeCode;
    }

    function proxyCreationCode() public pure returns (bytes memory) {
        return type(UserProxy).creationCode;
    }

    function proxyCreationCodeHash() public pure returns (bytes32) {
        return keccak256(proxyCreationCode());
    }

}

//  SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

import './interfaces/IUserProxy.sol';
import './interfaces/IERC20.sol';
import './libraries/ECDSA.sol';
import './interfaces/ILendingPool.sol';

contract UserProxy is IUserProxy {
    address public override factory;
    address public override owner;
    uint256 public nonce;
    address public lendingPool;

    string public constant name = 'User Proxy V1';
    string public constant VERSION = "1";

    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    // keccak256("ExecTransaction(address to,uint256 value,bytes data,uint8 operation,uint256 nonce)");
    bytes32 public constant EXEC_TX_TYPEHASH = 0xa609e999e2804ed92314c0c662cfdb3c1d8107df2fb6f2e4039093f20d5e6250;
    bytes32 public DOMAIN_SEPARATOR;



    constructor(){
        factory = msg.sender; 
    }

    function initialize(address _owner,address _lendingPool) external override {
        require(msg.sender == factory, 'FORBIDDEN');
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_SEPARATOR_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(VERSION)),
                chainId,
                address(this)
            )
        );
        owner = _owner;
        lendingPool = _lendingPool;
        address[] memory assetList = ILendingPool(_lendingPool).getReservesList();
		for(uint256 i=0; i<assetList.length; i++){
			IERC20(assetList[i]).approve(_lendingPool,type(uint256).max);
		}
    }

    function execTransaction(address to, uint256 value, bytes calldata data, Operation operation, bytes memory signature) external override {
        nonce = nonce +1;
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(EXEC_TX_TYPEHASH, to, value, keccak256(data), operation, nonce))
            )
        );
        address recoveredAddress = ECDSA.recover(digest, signature);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "ECDSA: invalid signature");
        require(execute(to, value, data, operation), "call error");
    }

    function execute(
        address to,
        uint256 value,
        bytes memory data,
        Operation operation
    ) internal returns (bool success) {
        if (operation == Operation.DelegateCall) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := delegatecall(gas(), to, add(data, 0x20), mload(data), 0, 0)
            }
        } else {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := call(gas(), to, value, add(data, 0x20), mload(data), 0, 0)
            }
        }
    }

}

//  SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0;

interface IUserProxyFactory {
    event ProxyCreated(address indexed owner, address proxy);
    function getProxy(address owner) external view returns (address proxy);
    function createProxy(address owner,address lendingPool) external returns (address proxy);
}

//  SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;



interface ILendingPool {

    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);

   
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    function getReservesList() external view returns (address[] memory);

    function getReserveData(address asset) external view returns (uint256,uint128,uint128,uint128,uint128,uint128,uint40,address,address,address,address,uint8);


}

//  SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * NOTE: This call _does not revert_ if the signature is invalid, or
     * if the signer is otherwise unable to be retrieved. In those scenarios,
     * the zero address is returned.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        // If the signature is valid (and not malleable), return the signer address
        return ecrecover(hash, v, r, s);
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

//  SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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

    function mint(address spender, uint256 amount) external;
    function burn(address spender, uint256 amount) external;
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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//  SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0;

interface IUserProxy {
    enum Operation {Call, DelegateCall}
    function factory() external view returns (address);
    function owner() external view returns (address);
    function initialize(address,address) external;
    function execTransaction(address,uint256,bytes calldata,Operation,bytes memory) external;
}