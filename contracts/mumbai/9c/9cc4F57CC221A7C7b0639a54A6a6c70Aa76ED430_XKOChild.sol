// SPDX-License-Identifier: MIT
//  _/      _/  _/    _/    _/_/
//   _/  _/    _/  _/    _/    _/
//     _/      _/_/      _/    _/
//   _/  _/    _/  _/    _/    _/
// _/      _/  _/    _/    _/_/
pragma solidity ^0.8.9;

import "./ERC20Capped.sol";
import "./AccessControl.sol";
import "./Context.sol";
import "./Counters.sol";
import "./EIP712.sol";

contract ChainConstants {
    string constant public ERC712_VERSION = "1";
    address constant public MUMBAI_CHILD_CHAIN_MANAGER = 0xb5505a6d998549090530911180f38aC5130101c6;
    address constant public POLYGON_CHILD_CHAIN_MANAGER = 0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa;
}

abstract contract NativeMetaTransaction is EIP712 {
    using Counters for Counters.Counter;

    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );

    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );

    mapping(address => Counters.Counter) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
        nonce: nonces[userAddress].current(),
        from: userAddress,
        functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress].increment();

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );

        require(success, "Function call not successful");

        return returnData;
    }

    function _hashMetaTransaction(MetaTransaction memory metaTx) internal pure returns (bytes32) {
        return
        keccak256(
            abi.encode(
                META_TRANSACTION_TYPEHASH,
                metaTx.nonce,
                metaTx.from,
                keccak256(metaTx.functionSignature)
            )
        );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user].current();
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
        signer ==
        ECDSA.recover(
            _hashTypedDataV4(_hashMetaTransaction(metaTx)),
            sigV,
            sigR,
            sigS
        );
    }
}

abstract contract ContextMixin {
    function msgSender() internal view returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
            // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                mload(add(array, index)),
                0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

// File: contracts/child/ChildToken/IChildToken.sol
interface IChildToken {
    function deposit(address user, bytes calldata depositData) external;
}

/// @custom:security-contact [email protected]
contract XKOChild is ERC20Capped, AccessControl, ChainConstants, NativeMetaTransaction, ContextMixin, IChildToken {
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");

    constructor(string memory name, string memory symbol) ERC20(name, symbol) ERC20Capped(100000000000 * 10 ** decimals()) EIP712(name, ChainConstants.ERC712_VERSION) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEPOSITOR_ROLE, _childChainManager());
        _mint(msg.sender, 100000000000 * 10 ** decimals());
    }

    function _childChainManager() internal view returns(address) {
        if(block.chainid == 80001) {
            return MUMBAI_CHILD_CHAIN_MANAGER;
        }
        return POLYGON_CHILD_CHAIN_MANAGER;
    }

    function _msgSender() internal override view returns (address sender) {
        return ContextMixin.msgSender();
    }

    /**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by ChildChainManager
     * Should handle deposit by minting the required amount for user
     * Make sure minting is done only by this function
     * @param user user address for whom deposit is being done
     * @param depositData abi encoded amount
     */
    function deposit(address user, bytes calldata depositData) external override onlyRole(DEPOSITOR_ROLE) {
        uint256 amount = abi.decode(depositData, (uint256));
        _mint(user, amount);
    }

    /**
     * @notice called when user wants to withdraw tokens back to root chain
     * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
     * @param amount amount of tokens to withdraw
     */
    function withdraw(uint256 amount) external {
        _burn(_msgSender(), amount);
    }
}