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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

library TransferHelpers {
    bytes4 private constant T_SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
    bytes4 private constant TF_SELECTOR =
        bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));

    function safeTranfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(T_SELECTOR, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelpers: Transfer Failed!"
        );
    }

    function safeTranferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(TF_SELECTOR, from, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelpers: Transfer Failed!"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./libraries/TransferHelpers.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract P2P is ReentrancyGuard {
    struct Listing {
        uint256 price;
        uint256 amount;
        uint256 limit;
        address seller;
    }

    event ListToken(
        address indexed seller,
        address indexed fromToken,
        address indexed toToken,
        uint256 price,
        uint256 amount,
        uint256 limit
    );

    event BuyToken(
        address indexed buyer,
        address indexed fromToken,
        address indexed seller,
        address toToken,
        uint256 boughtTokens,
        uint256 soldToken
    );

    event CancelListing(
        address indexed seller,
        address indexed fromToken,
        address indexed toToken
    );

    modifier notListed(address _fromToken, address _toToken) {
        Listing memory listing = listings[msg.sender][_fromToken][_toToken];
        require(listing.price == 0, "P2P: Already listed");
        _;
    }

    modifier isListed(
        address _fromToken,
        address _toToken,
        address _seller
    ) {
        Listing memory listing = listings[_seller][_fromToken][_toToken];
        require(listing.seller != address(0), "P2P: Not listed");
        _;
    }

    modifier isEnoughToken(
        uint256 _price,
        uint256 _amount,
        address _fromToken
    ) {
        require(_price > 0, "P2P: Invalid Price");
        require(_amount > 0, "P2P: Invalid Amount");
        require(
            IERC20Metadata(_fromToken).balanceOf(msg.sender) >= _amount,
            "P2P: Amount Exceeds balance"
        );
        _;
    }

    mapping(address => mapping(address => mapping(address => Listing))) private listings;

    function updateListing(
        address _seller,
        address _fromToken,
        address _toToken,
        uint256 _price,
        uint256 _amount,
        uint256 _limit
    ) private isListed(_fromToken, _toToken, _seller) {
        require(_price > 0, "P2P: Invalid Price");

        if (_amount > IERC20Metadata(_fromToken).balanceOf(_seller) || _amount == 0) {
            delete listings[_seller][_fromToken][_toToken];
            emit CancelListing(msg.sender, _fromToken, _toToken);
        } else {
            // stack too deep error
            {
                listings[_seller][_fromToken][_toToken] = Listing(
                    _price,
                    _amount,
                    _limit,
                    _seller
                );
            }
            emit ListToken(_seller, _fromToken, _toToken, _price, _amount, _limit);
        }
    }

    function listToken(
        address _fromToken,
        address _toToken,
        uint256 _price,
        uint256 _amount,
        uint256 _limit
    ) external notListed(_fromToken, _toToken) isEnoughToken(_price, _amount, _fromToken) {
        require(_amount >= _limit, "P2P: Limit should be less than amount");
        Listing memory listing;
        listing.price = _price;
        listing.amount = _amount;
        listing.limit = _limit;
        listing.seller = msg.sender;

        listings[msg.sender][_fromToken][_toToken] = listing;
        // listings[msg.sender][_fromToken][_toToken] = Listing(_price, _amount, _limit, msg.sender); // from and to are tokens
        emit ListToken(msg.sender, _fromToken, _toToken, _price, _amount, _limit);
    }

    function buyToken(
        address _fromToken,
        address _toToken,
        address _seller,
        uint256 _amount
    ) external isListed(_toToken, _fromToken, _seller) nonReentrant {
        Listing memory listing = listings[_seller][_toToken][_fromToken];
        require(_amount >= listing.limit && _amount <= listing.amount, "P2P: Out of limit");

        uint256 decimals = 10**IERC20Metadata(_toToken).decimals();

        // `seller from` = `buyer to` and vice versa
        TransferHelpers.safeTranferFrom(
            _fromToken,
            msg.sender,
            address(this),
            (listing.price * _amount) / decimals // this is important as we are passing token amount with decimals as if we pass amount without decimals then they won't be able to buy tokens in decimals e.g. 0.001 BTC
        ); // buyer -> contract
        TransferHelpers.safeTranferFrom(_toToken, _seller, address(this), _amount); // seller -> contract

        uint256 amount = (_amount * 9998) / 10000; // fee
        uint256 amount2 = ((listing.price * _amount * 9998) / decimals) / 10000; // fee

        TransferHelpers.safeTranfer(_toToken, msg.sender, amount);
        TransferHelpers.safeTranfer(_fromToken, _seller, amount2);

        emit BuyToken(msg.sender, _fromToken, _seller, _toToken, _amount, amount2);

        updateListing(
            _seller,
            _toToken,
            _fromToken,
            listing.price,
            (listing.amount - _amount),
            listing.limit
        );
    }

    function cancelListing(address _fromToken, address _toToken)
        external
        isListed(_fromToken, _toToken, msg.sender)
    {
        delete listings[msg.sender][_fromToken][_toToken];
        emit CancelListing(msg.sender, _fromToken, _toToken);
    }

    function getListing(
        address _seller,
        address _fromToken,
        address _toToken
    ) external view returns (Listing memory listing) {
        listing = listings[_seller][_fromToken][_toToken];
    }
}