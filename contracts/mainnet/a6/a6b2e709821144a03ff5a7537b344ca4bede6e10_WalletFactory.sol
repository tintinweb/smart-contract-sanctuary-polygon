// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/proxy/Clones.sol";
import "./Proxy.sol";
import "./interfaces/ISmartWallet.sol"; 
//@review
//@todo IWallet should have execTransaction
//possibly IWallet.sol

contract WalletFactory {
    address internal _defaultImpl; 

    // EOA + Version tracking
    string public constant VERSION = "1.0.1"; // Forward enabled refund enhancements

    //states : registry
    mapping (address => bool) public isWalletExist;

    constructor(address _baseImpl) {
        require(_baseImpl != address(0), "base wallet address can not be zero");
        _defaultImpl = _baseImpl;
    }

    // event WalletCreated(address indexed _proxy, address indexed _implementation, address indexed _owner);
    // EOA + Version tracking
    event WalletCreated(address indexed _proxy, address indexed _implementation, address indexed _owner, string version, uint256 _index);

    /**
     * @notice Deploys wallet using create2 and points it to _defaultImpl
     * @param _owner EOA signatory of the wallet
     * @param _entryPoint AA 4337 entry point address
     * @param _handler fallback handler address
     * @param _index extra salt that allows to deploy more wallets if needed for same EOA (default 0)
     */
    function deployCounterFactualWallet(address _owner, address _entryPoint, address _handler, uint _index) public returns(address proxy){
        bytes32 salt = keccak256(abi.encodePacked(_owner, address(uint160(_index))));
        bytes memory deploymentData = abi.encodePacked(type(Proxy).creationCode, uint(uint160(_defaultImpl)));
        // solhint-disable-next-line no-inline-assembly
        assembly {
            proxy := create2(0x0, add(0x20, deploymentData), mload(deploymentData), salt)
        }
        require(address(proxy) != address(0), "Create2 call failed");
        // EOA + Version tracking
        emit WalletCreated(proxy,_defaultImpl,_owner, VERSION, _index);
        ISmartWallet(proxy).init(_owner, _entryPoint, _handler);
        isWalletExist[proxy] = true;
    }

    /**
     * @notice Deploys wallet using create and points it to _defaultImpl
     * @param _owner EOA signatory of the wallet
     * @param _entryPoint AA 4337 entry point address
     * @param _handler fallback handler address
    */ 
    function deployWallet(address _owner, address _entryPoint, address _handler) public returns(address proxy){ 
        bytes memory deploymentData = abi.encodePacked(type(Proxy).creationCode, uint(uint160(_defaultImpl)));
        // solhint-disable-next-line no-inline-assembly
        assembly {
            proxy := create(0x0, add(0x20, deploymentData), mload(deploymentData))
        }
        ISmartWallet(proxy).init(_owner, _entryPoint, _handler);
        isWalletExist[proxy] = true;
    }

    /**
     * @notice Allows to find out wallet address prior to deployment
     * @param _owner EOA signatory of the wallet
     * @param _index extra salt that allows to deploy more wallets if needed for same EOA (default 0)
    */
    function getAddressForCounterfactualWallet(address _owner, uint _index) external view returns (address _wallet) {
       bytes memory code = abi.encodePacked(type(Proxy).creationCode, uint(uint160(_defaultImpl)));
       bytes32 salt = keccak256(abi.encodePacked(_owner, address(uint160(_index))));
       bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(code)));
        _wallet = address(uint160(uint(hash)));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Proxy // This is the user's wallet
 * @notice Basic proxy that delegates all calls to a fixed implementing contract.
 */
contract Proxy {

    /* This is the keccak-256 hash of "biconomy.scw.proxy.implementation" subtracted by 1, and is validated in the constructor */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x37722d148fb373b961a84120b6c8d209709b45377878a466db32bbc40d95af26;

    event Received(uint indexed value, address indexed sender, bytes data);

    constructor(address _implementation) {
         assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("biconomy.scw.proxy.implementation")) - 1));
         assembly {
             sstore(_IMPLEMENTATION_SLOT,_implementation) 
         }
    }

    fallback() external payable {
        address target;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            target := sload(_IMPLEMENTATION_SLOT)
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), target, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {revert(0, returndatasize())}
            default {return (0, returndatasize())}
        }
    }

    receive() external payable {
        emit Received(msg.value, msg.sender, "");
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../aa-4337/interfaces/IWallet.sol";

interface ISmartWallet is IWallet {
    function init(address _owner, address _entryPoint, address _handler) external;
    
    //@review
    // function execTransaction() external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./UserOperation.sol";

interface IWallet {

    /**
     * Validate user's signature and nonce
     * the entryPoint will make the call to the recipient only if this validation call returns successfully.
     *
     * @dev Must validate caller is the entryPoint.
     *      Must validate the signature and nonce
     * @param userOp the operation that is about to be executed.
     * @param requestId hash of the user's request data. can be used as the basis for signature.
     * @param aggregator the aggregator used to validate the signature. NULL for non-aggregated signature wallets.
     * @param missingWalletFunds missing funds on the wallet's deposit in the entrypoint.
     *      This is the minimum amount to transfer to the sender(entryPoint) to be able to make the call.
     *      The excess is left as a deposit in the entrypoint, for future calls.
     *      can be withdrawn anytime using "entryPoint.withdrawTo()"
     *      In case there is a paymaster in the request (or the current deposit is high enough), this value will be zero.
     */
    function validateUserOp(UserOperation calldata userOp, bytes32 requestId, address aggregator, uint256 missingWalletFunds) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/* solhint-disable no-inline-assembly */

    /**
     * User Operation struct
     * @param sender the sender account of this request
     * @param nonce unique value the sender uses to verify it is not a replay.
     * @param initCode if set, the account contract will be created by this constructor
     * @param callData the method call to execute on this account.
     * @param verificationGasLimit gas used for validateUserOp and validatePaymasterUserOp
     * @param preVerificationGas gas not calculated by the handleOps method, but added to the gas paid. Covers batch overhead.
     * @param maxFeePerGas same as EIP-1559 gas parameter
     * @param maxPriorityFeePerGas same as EIP-1559 gas parameter
     * @param paymasterAndData if set, this field hold the paymaster address and "paymaster-specific-data". the paymaster will pay for the transaction instead of the sender
     * @param signature sender-verified signature over the entire request, the EntryPoint address and the chain ID.
     */
    struct UserOperation {

        address sender;
        uint256 nonce;
        bytes initCode;
        bytes callData;
        uint256 callGasLimit;
        uint256 verificationGasLimit;
        uint256 preVerificationGas;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        bytes paymasterAndData;
        bytes signature;
    }

library UserOperationLib {

    function getSender(UserOperation calldata userOp) internal pure returns (address) {
        address data;
        //read sender from userOp, which is first userOp member (saves 800 gas...)
        assembly {data := calldataload(userOp)}
        return address(uint160(data));
    }

    //relayer/miner might submit the TX with higher priorityFee, but the user should not
    // pay above what he signed for.
    function gasPrice(UserOperation calldata userOp) internal view returns (uint256) {
    unchecked {
        uint256 maxFeePerGas = userOp.maxFeePerGas;
        uint256 maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
        if (maxFeePerGas == maxPriorityFeePerGas) {
            //legacy mode (for networks that don't support basefee opcode)
            return maxFeePerGas;
        }
        return min(maxFeePerGas, maxPriorityFeePerGas + block.basefee);
    }
    }

    function pack(UserOperation calldata userOp) internal pure returns (bytes memory ret) {
        //lighter signature scheme. must match UserOp.ts#packUserOp
        bytes calldata sig = userOp.signature;
        // copy directly the userOp from calldata up to (but not including) the signature.
        // this encoding depends on the ABI encoding of calldata, but is much lighter to copy
        // than referencing each field separately.
        assembly {
            let ofs := userOp
            let len := sub(sub(sig.offset, ofs), 32)
            ret := mload(0x40)
            mstore(0x40, add(ret, add(len, 32)))
            mstore(ret, len)
            calldatacopy(add(ret, 32), ofs, len)
        }
    }

    function hash(UserOperation calldata userOp) internal pure returns (bytes32) {
        return keccak256(pack(userOp));
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}