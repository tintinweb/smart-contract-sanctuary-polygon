// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {MintParams} from "../structs/erc721/ERC721Structs.sol";
import "../interfaces/IOmniseaONFT721Psi.sol";
import "../interfaces/IOmniseaDropsManager.sol";
import "../interfaces/IOmniseaPaymentsManager.sol";
import "../interfaces/IOmniseaReceiver.sol";
import "../interfaces/IOmniseaRouter.sol";
import "./OmniseaPaymentsManager.sol";

contract OmniseaDropsManager is IOmniseaDropsManager, IOmniseaReceiver, ReentrancyGuard {
    event Minted(address collAddr, address rec, uint256 quantity);
    event Paid(address rec);

    error InvalidPrice(address collAddr, address spender, uint256 paid, uint256 quantity);

    struct LZConfig {
        bool payInZRO;
        address zroPaymentAddress;
    }

    uint256 private _fee;
    address private _feeManager;
    address private _owner;
    address public immutable override paymentsManager;

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor() {
        _owner = msg.sender;
        _feeManager = address(0x61104fBe07ecc735D8d84422c7f045f8d29DBf15);
        paymentsManager = address(new OmniseaPaymentsManager());
    }

    function setFee(uint256 fee) external onlyOwner {
        require(fee <= 20);
        _fee = fee;
    }

    function setFeeManager(address _newManager) external onlyOwner {
        _feeManager = _newManager;
    }

    function mint(MintParams memory _params) public payable { // TODO (Must) Removed nonReentrant for testing
        require(_params.coll != address(0), "OmniseaDropsManager: !collAddr");
        require(_params.quantity > 0, "OmniseaDropsManager: !quantity");

        IOmniseaONFT721Psi collection = IOmniseaONFT721Psi(_params.coll);

        uint256 price = collection.mintPrice(_params.phaseId);
        uint256 quantityPrice = price * _params.quantity;
        if (quantityPrice > 0) {
            bool isFromRemote = msg.sender == address(this);

            if (isFromRemote) {
                require(msg.value >= quantityPrice, "OmniseaDropsManager: <price");
            } else {
                require(msg.value == quantityPrice, "OmniseaDropsManager: !=price");
            }
            address payee = isFromRemote ? _params.to : msg.sender;
            IOmniseaPaymentsManager(paymentsManager).onPayment(payee, quantityPrice, address(collection));

            (bool p,) = payable(paymentsManager).call{value : quantityPrice}("");
            require(p, "OmniseaDropsManager: !p");
        }

        address minter = _params.to == address(0) ? msg.sender : _params.to;
        collection.mint(minter, _params.quantity, _params.merkleProof, _params.phaseId);
        emit Minted(_params.coll, minter, _params.quantity);
    }

    function omReceive(
        uint16,
        bytes memory,
        bytes memory _payload
    ) external override payable { // TODO (Must) Removed nonReentrant for testing
        (MintParams memory params) = abi.decode(_payload, (MintParams));

        mint(params);
    }

    function mintTo(
        MintParams calldata _params,
        IOmniseaRouter _omniseaRouter,
        uint16 dstChainId,                      // Stargate/LayerZero chainId
        uint16 srcPoolId,                       // stargate poolId - *must* be the poolId for the bridgeToken asset
        uint16 dstPoolId,                       // stargate destination poolId
        uint nativeAmountIn,                    // exact amount of native token coming in on source
        uint amountOutMin,                      // minimum amount of stargatePoolId token to get out of amm router
        uint amountOutMinSg,                    // minimum amount of stargatePoolId token to get out on destination chain
        uint amountOutMinDest,                  // minimum amount of native token to receive on destination
        address dstOmniseaRouter,               // destination contract. it must implement sgReceive()
        address omReceiver
    ) external payable nonReentrant {
        bytes memory payload;
        {
            payload = abi.encode(_params);
        }

        address to = _params.to;
        _omniseaRouter.swapNativeForNative{value: msg.value}(
            dstChainId,
            srcPoolId,
            dstPoolId,
            nativeAmountIn,
            to,
            amountOutMin,
            amountOutMinSg,
            amountOutMinDest,
            dstOmniseaRouter,
            omReceiver,
            payload
        );
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct CreateParams {
    string name;
    string symbol;
    string uri;
    string tokensURI;
    uint24 maxSupply;
    bool isZeroIndexed;
    uint24 royaltyAmount;
    uint256 endTime;
}

struct MintParams {
    address coll;
    uint24 quantity;
    bytes32[] merkleProof;
    uint8 phaseId;
    address to;
}

struct OmnichainMintParams {
    address collection;
    uint24 quantity;
    uint256 paid;
    uint8 phaseId;
    address minter;
}

struct Phase {
    uint256 from;
    uint256 to;
    uint24 maxPerAddress;
    uint256 price;
    bytes32 merkleRoot;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IOmniseaONFT721Psi {
    function mint(address owner, uint24 quantity, bytes32[] memory _merkleProof, uint8 _phaseId) external;
    function mintPrice(uint8 _phaseId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {OmnichainMintParams} from "../structs/erc721/ERC721Structs.sol";

interface IOmniseaDropsManager {
    function paymentsManager() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {CreateParams} from "../structs/erc721/ERC721Structs.sol";

interface IOmniseaPaymentsManager {
    function onPayment(address _payee, uint256 _paid, address _collection) external;
    function payout(address _recipient, uint256 _endTime) external;
    function refund(address _refundee, uint256 _endTime) external;
    function isFlagged(address _collection) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IOmniseaReceiver {
    function omReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        bytes memory _payload
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IOmniseaRouter {
    function swapNativeForNative(
        uint16 dstChainId,                      // Stargate/LayerZero chainId
        uint16 srcPoolId,                       // stargate poolId - *must* be the poolId for the bridgeToken asset
        uint16 dstPoolId,                       // stargate destination poolId
        uint nativeAmountIn,                    // exact amount of native token coming in on source
        address to,                             // the address to send the destination tokens to
        uint amountOutMin,                      // minimum amount of stargatePoolId token to get out of amm router
        uint amountOutMinSg,                    // minimum amount of stargatePoolId token to get out on destination chain
        uint amountOutMinDest,                  // minimum amount of native token to receive on destination
        address dstOmniseaRouter,               // destination contract. it must implement sgReceive()
        address omReceiver,                     // destination contract. it must implement sgReceive()
        bytes memory payloadForCall             // payload for the omReceive() call on destination
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IOmniseaONFT721Psi.sol";
import "../interfaces/IOmniseaPaymentsManager.sol";

contract OmniseaPaymentsManager is IOmniseaPaymentsManager, ReentrancyGuard {
    mapping(address => bool) public flagged;
    mapping(address => uint256) public paid;
    mapping(address => mapping(address => uint256)) public paidBy;
    uint256 private _fee;
    address private _feeManager;
    address private _owner;

    constructor() {
        _owner = msg.sender; // OmniseaDropsManager
        _feeManager = address(0x61104fBe07ecc735D8d84422c7f045f8d29DBf15);
    }

    function onPayment(address _payee, uint256 _paid, address _collection) external override {
        require(msg.sender == _owner);
        paid[_collection] += _paid;
        paidBy[_collection][_payee] += _paid;
    }

    function payout(address _recipient, uint256 _endTime) external override nonReentrant {
        require(block.timestamp >= _endTime + 2 hours); // TODO (Must): Change to 14 days
        require(!flagged[msg.sender]);

        uint256 toPayout = paid[msg.sender];
        require(toPayout > 0);
        paid[msg.sender] = 0;

        uint256 feeAmount;
        if (_fee > 0) {
            feeAmount = (toPayout * _fee) / 100;

            (bool p1,) = payable(_feeManager).call{value : feeAmount}("");
            require(p1);
        }

        (bool p2,) = payable(_recipient).call{value : (toPayout - feeAmount)}("");
        require(p2);
    }

    function refund(address _refundee, uint256 _endTime) external override nonReentrant {
        require(flagged[msg.sender] && block.timestamp >= _endTime + 21 days);
        uint256 paidByRefundee = paidBy[msg.sender][_refundee];
        require(paidByRefundee > 0);
        paidBy[msg.sender][_refundee] = 0;

        (bool p,) = payable(_refundee).call{value: paidByRefundee}("");
        require(p, "!p");
    }

    function isFlagged(address _collection) external view override returns (bool) {
        return flagged[_collection];
    }

    function setFlagged(address _toFlag, bool _flagged) external {
        require(msg.sender == _feeManager);
        flagged[_toFlag] = _flagged;
    }

    function setFee(uint256 fee) external {
        require(msg.sender == _feeManager);
        require(fee <= 20);
        _fee = fee;
    }

    function setFeeManager(address _newManager) external {
        require(msg.sender == _feeManager);
        _feeManager = _newManager;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}