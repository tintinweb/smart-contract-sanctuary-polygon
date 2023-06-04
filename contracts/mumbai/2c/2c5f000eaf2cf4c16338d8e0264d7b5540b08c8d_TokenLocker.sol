// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenLocker {
    uint256 private immutable _chainId;
    address public immutable notary;
    uint256 public lockIndex;

    struct Lock {
        address owner;
        uint256 toChainId;
        address payToken;
        uint256 payTokenAmount;
        address buyToken;
        uint256 buyTokenAmount;
        bool executed;
        bool cancelled;
    }
    // locks[lockId]
    mapping(uint256 => Lock) public locks;

    // Lock의 수령 대상 정보 저장
    struct Recipient {
        address recipient;
        uint256 recipientLockId;
    }
    // recipients[lockId]
    mapping(uint256 => Recipient) public recipients;

    // isRequestCancel[lockId]
    mapping(uint256 => bool) public isRequestCancel;

    event NewLock(
        address owner,
        uint256 lockId,
        uint256 toChain,
        address payToken,
        uint256 payTokenAmount,
        address buyToken,
        uint256 buyTokenAmount
    );
    event SetRecipient(
        uint256 lockId,
        address recipient,
        uint256 recipientLockId
    );
    event Executed(uint256 lockId);
    event RequestCancel(uint256 lockId);
    event Cancelled(uint256 lockId);

    constructor(address _notary) {
        _chainId = block.chainid;
        notary = _notary;
    }

    /// @notice 공증인 계정에서 생성한 sign 검증에 필요한 해시값 생성
    /// @param lockId 해시값을 생성할 Lock ID
    /// @param action "EXECUTE" 또는 "CANCEL"
    function hash(
        uint256 lockId,
        string memory action
    ) public view returns (bytes32) {
        // 해시할 때 체인 ID를 포함해서 다른 체인에서 사용된 서명값을 재사용하는 행위 차단
        return keccak256(abi.encodePacked(_chainId, lockId, action));
    }

    /// @notice personal_sign 검증에 사용할 수 있는 해시값 생성
    /// @param messageHash personal_sign 검증에 사용할 해시값
    function getEthSignedHash(
        bytes32 messageHash
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );
    }

    /// @notice 공증인 계정에서 생성한 sign 검증
    /// @param action "EXECUTE" 또는 "CANCEL"
    /// @param lockId sign을 검증할 Lock ID
    /// @param digest hash()로 생성된 해시값
    /// @param v 공증인 계정에서 생성한 sign의 V 값(ex, 0x1b)
    /// @param r 공증인 계정에서 생성한 sign의 R 값(ex, 0xa795754cbc06513557f4fbe7f00a2b3267fe1d08922be34639675795226ba149)
    /// @param s 공증인 계정에서 생성한 sign의 S 값(ex, 0x0a3b4468386b6f54b19e9e7249da9c378cbcd1a2e1d24a97087c9154d72c19df)
    function checkSign(
        string memory action,
        uint256 lockId,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view {
        require(digest == hash(lockId, action), "invalid digest");

        address signer = ecrecover(getEthSignedHash(digest), v, r, s);
        require(signer == notary, "invalid signer");
    }

    /// @notice 새로운 Lock 생성
    /// @param toChainId 거래할 대상 체인 ID
    /// @param payToken 지불 토큰 주소, address(0)는 네이티브 토큰
    /// @param payTokenAmount 지불할 토큰 수량
    /// @param buyToken 구매할 토큰 주소, address(0)는 네이티브 토큰
    /// @param buyTokenAmount 구매할 토큰 수량
    function create(
        uint256 toChainId,
        address payToken,
        uint256 payTokenAmount,
        address buyToken,
        uint256 buyTokenAmount
    ) external payable {
        uint256 lockId;
        unchecked {
            lockId = lockIndex++;
        }

        locks[lockId] = Lock({
            owner: msg.sender,
            toChainId: toChainId,
            payToken: payToken,
            payTokenAmount: payTokenAmount,
            buyToken: buyToken,
            buyTokenAmount: buyTokenAmount,
            executed: false,
            cancelled: false
        });

        if (payToken == address(0)) {
            require(
                msg.value == payTokenAmount,
                "TokenLocker: not enought token"
            );
        } else {
            IERC20(payToken).transfer(address(this), payTokenAmount);
        }

        emit NewLock(
            msg.sender,
            lockId,
            toChainId,
            payToken,
            payTokenAmount,
            buyToken,
            buyTokenAmount
        );
    }

    /// @notice Lock된 토큰을 수령할 상대방 지정
    /// @param lockId 수령할 상대방을 지정할 Lock ID
    /// @param recipient Lock된 토큰을 수령할 계정
    /// @param recipientLockId Lock된 토큰을 수령할 상대의 Lock ID
    function setRecipient(
        uint256 lockId,
        address recipient,
        uint256 recipientLockId
    ) external {
        require(locks[lockId].owner == msg.sender, "only owner");
        require(recipients[lockId].recipient == address(0), "already set");

        recipients[lockId].recipient = recipient;
        recipients[lockId].recipientLockId = recipientLockId;

        emit SetRecipient(lockId, recipient, recipientLockId);
    }

    /// @notice 공증인 계정에서 생성한 sign을 검증한 뒤, Lock된 토큰을 recipient에게 전송
    /// @param lockId Lock된 토큰을 전송할 Lock ID
    /// @param digest hash()로 생성된 Lock ID에 해당하는 해시값
    /// @param v 공증인 계정에서 생성한 sign의 V 값(ex, 0x1b)
    /// @param r 공증인 계정에서 생성한 sign의 R 값(ex, 0xa795754cbc06513557f4fbe7f00a2b3267fe1d08922be34639675795226ba149)
    /// @param s 공증인 계정에서 생성한 sign의 S 값(ex, 0x0a3b4468386b6f54b19e9e7249da9c378cbcd1a2e1d24a97087c9154d72c19df)
    function execute(
        uint256 lockId,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(lockId < lockIndex, "TokenLocker: invalid Lock ID");
        require(
            locks[lockId].executed == false,
            "TokenLocker: already executed"
        );

        checkSign("EXECUTE", lockId, digest, v, r, s);
        locks[lockId].executed = true;

        address token = locks[lockId].payToken;
        if (token == address(0)) {
            payable(recipients[lockId].recipient).transfer(
                locks[lockId].payTokenAmount
            );
        } else {
            IERC20(token).transfer(
                recipients[lockId].recipient,
                locks[lockId].payTokenAmount
            );
        }

        emit Executed(lockId);
    }

    /// @notice Lock을 취소하기 위한 sign을 공증인에게 요청하는 이벤트 발생
    /// @dev execute에 필요한 키가 배포된 경우 취소 불가능
    /// @param lockId 취소할 Lock ID
    function requestCancel(uint256 lockId) external {
        require(locks[lockId].owner == msg.sender, "TokenLocker: only owner");
        require(
            recipients[lockId].recipient != address(0),
            "TokenLocker: not necessary"
        );
        require(
            isRequestCancel[lockId] == false,
            "TokenLocker: already requested"
        );

        isRequestCancel[lockId] = true;
        emit RequestCancel(lockId);
    }

    /// @notice 공증인 계정에서 생성한 sign을 검증한 뒤, Lock을 취소하고 토큰 환불
    /// @param lockId 취소할 Lock ID
    /// @param digest hash()로 생성된 Lock ID에 해당하는 해시값
    /// @param v 공증인 계정에서 생성한 sign의 V 값(ex, 0x1b)
    /// @param r 공증인 계정에서 생성한 sign의 R 값(ex, 0xa795754cbc06513557f4fbe7f00a2b3267fe1d08922be34639675795226ba149)
    /// @param s 공증인 계정에서 생성한 sign의 S 값(ex, 0x0a3b4468386b6f54b19e9e7249da9c378cbcd1a2e1d24a97087c9154d72c19df)
    function cancel(
        uint256 lockId,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(lockId < lockIndex, "TokenLocker: invalid Lock ID");

        // recipeint를 지정하기 전에는 공증인을 거칠 필요없이 바로 취소 가능
        // recipient를 지정한 뒤에는 reqeustCancel()로 취소 요청을 하고,
        // 공증인이 제공한 sign을 받아서 제공해야함.
        require(
            isRequestCancel[lockId] == true ||
                recipients[lockId].recipient == address(0),
            "TokenLocker: not cancelable"
        );
        require(
            locks[lockId].cancelled == false,
            "TokenLocker: already cancelled"
        );

        checkSign("CANCEL", lockId, digest, v, r, s);
        locks[lockId].cancelled = true;

        address token = locks[lockId].payToken;
        if (token == address(0)) {
            payable(locks[lockId].owner).transfer(locks[lockId].payTokenAmount);
        } else {
            IERC20(token).transfer(
                locks[lockId].owner,
                locks[lockId].payTokenAmount
            );
        }

        emit Cancelled(lockId);
    }
}

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
}