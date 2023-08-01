// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /**
     * Added manually.
     * Increase Allowance
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return;
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    function recover(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    function tryRecover(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;

            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    function toEthSignedMessageHash(
        bytes32 hash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./UAEDfinancePoolManager.sol";

contract forcePay {
    constructor(address payable _user) payable {
        // EIP-4758: Deactivate SELFDESTRUCT
        selfdestruct(_user);
    }
}

contract UAEDfinancePool {
    address public protocol;
    UAEDfinancePoolManager public uaedPoolManager;

    constructor(address _uaed) {
        protocol = msg.sender;
        uaedPoolManager = new UAEDfinancePoolManager(_uaed);
    }

    receive() external payable {
        require(msg.sender == protocol, "onlyProtocol");
    }

    modifier validateSender() {
        require(
            msg.sender == protocol || msg.sender == address(uaedPoolManager),
            "invalid sender"
        );
        _;
    }

    function ERC20transfer(
        address _tokenAddress,
        address _receiver,
        uint _amount
    ) public validateSender {
        IERC20(_tokenAddress).transfer(_receiver, _amount);
    }

    function ETHtransfer(
        address payable _receiver,
        uint _amount
    ) public validateSender {
        (bool sent, ) = _receiver.call{value: _amount}("");
        if (!sent) {
            new forcePay{value: _amount}(_receiver);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

import "./ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./UAEDfinancePool.sol";

contract UAEDfinancePoolManager {
    using ECDSA for bytes32;

    address public owner;
    address public uaedPool;
    address public uaed;
    bytes4 public depositFuncSig;
    bytes4 public withdrawalFuncSig;
    uint public season;
    uint public withdrawalDuration;

    constructor(address _uaed) {
        owner = tx.origin;
        uaedPool = msg.sender;
        uaed = _uaed;
        depositFuncSig = bytes4(
            abi.encodeWithSignature("_deposit(uint256,address)")
        );
        withdrawalFuncSig = bytes4(
            abi.encodeWithSignature("withdrawal(uint256,bytes)")
        );
        season = (365 days + 6 hours) / 4;
        withdrawalDuration = 3 days;
    }

    mapping(address => uint) public balance;
    mapping(address => uint) public nounce;

    event UAEDdeposit(address sender, uint amount);
    event UAEDWithdrawal(address receiver, uint amount);

    function changeOwner(address _owner) external {
        require(msg.sender == owner, "onlyOwner");
        owner = _owner;
    }

    function getBalance(address _user) external view returns (uint) {
        return balance[_user];
    }

    function onTokenTransfer(
        address _sender,
        uint _value,
        bytes calldata _data
    ) external {
        require(msg.sender == uaed, "only UAED contract");
        require(getSelector(_data) == depositFuncSig);
        bytes memory signature = abi.decode(_data[4:], (bytes));
        _checkSignature(_value, _sender, depositFuncSig, signature);
        _deposit(_value, _sender);
    }

    function getSelector(bytes memory _data) private pure returns (bytes4 sig) {
        assembly {
            sig := mload(add(_data, 32))
        }
    }

    function _checkSignature(
        uint _value,
        address _sender,
        bytes4 _funcSig,
        bytes memory _signature
    ) private {
        address signer = recover(
            getEthSignedMessageHash(_value, _sender, _funcSig),
            _signature
        );
        require(signer == owner, "signer != owner");
        nounce[_sender] += 1;
    }

    function getEthSignedMessageHash(
        uint _value,
        address _sender,
        bytes4 _funcSig
    ) public view returns (bytes32) {
        return
            getMessageHash(_value, _sender, _funcSig).toEthSignedMessageHash();
    }

    function getMessageHash(
        uint _value,
        address _sender,
        bytes4 _funcSig
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _value,
                    _sender,
                    _funcSig,
                    getSeasonTimestamp(),
                    nounce[_sender]
                )
            );
    }

    function getSeasonTimestamp() public view returns (uint _seasonTimestamp) {
        uint mode = block.timestamp % season;
        _seasonTimestamp = mode < withdrawalDuration
            ? block.timestamp - mode
            : block.timestamp + season - mode;
    }

    function recover(
        bytes32 _msg,
        bytes memory _signature
    ) public pure returns (address) {
        return _msg.recover(_signature);
    }

    function _deposit(uint _value, address _sender) private {
        balance[_sender] += _value;
        IERC20(uaed).transfer(uaedPool, _value);
        emit UAEDdeposit(_sender, _value);
    }

    function withdrawal(uint _value) external {
        uint seasonTimestamp = getSeasonTimestamp();
        require(
            seasonTimestamp < block.timestamp &&
                block.timestamp < seasonTimestamp + withdrawalDuration,
            "only in seasonTimestamp"
        );
        _withdrawal(_value);
    }

    function unconditionalWithdrawal(
        uint _value,
        bytes memory signature
    ) external {
        _checkSignature(_value, msg.sender, withdrawalFuncSig, signature);
        _withdrawal(_value);
    }

    function _withdrawal(uint _value) private {
        balance[msg.sender] -= _value;
        UAEDfinancePool(payable(uaedPool)).ERC20transfer(
            uaed,
            msg.sender,
            _value
        );
        emit UAEDWithdrawal(msg.sender, _value);
    }
}