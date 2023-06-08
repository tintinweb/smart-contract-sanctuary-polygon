// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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

/**
 *
 *      ε≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤,                           ╓≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤╖
 *    ╔░░░░░░░░░░░░░░░░░░░░░█                   ,     ]░░░░░░░░░░░░░░░░░░░░░░║ε
 *    ╠░░░░░░░░░░░░░░░░░░░░░▓░░            ,≤φ░''░░░µ,]░░░░░░░░░░░░░░░░░░░░░░╟▌░
 *    ╠░░░░░░░░░░░░░░░░░░░░▄▓▐▌       ,≤φ░░,▄▄#╝╙╙`_  ]░░░░░░░░▐▓▀▀▀▀▀▒░░░░░░╟▌░_
 *    ╠░░░░░░░░░▓╙╙╙╙╙╙╙╙╙╙╚░░▒╓ ,≤φ▒▄▄#▀╠╩╙"▒≥      ╓░▒▒"φ░░░░▐▌     ▒░░░░░░╟▒░
 *    ╠░░░░░░░░░▓_Γ       ╓φ░░░░,╙╠╚│░░]█.▒░░░░╚▄   Θ░░░░)░░░░░▐░░░░░░░░░░░░░╠░░░░▄▒░░░░░░░░░░░░╗
 *    ╠░░░░░░░░░▓_ε        ░░░░█▄-╩░░░░╚╝α▒░░░░░╟▒╓▒░░░░#░░░░░░▐░░░░░░░░░░░░░╠░░░░╣▒░░░░░░░░░░░░░▓⌐
 *    ╠░░░░░░░░░▓_ε       ╠░▒]█╚░░░░░░░░░░░▓░░░░░╚░░░░░╩░░░░░░░▐▄▄▄▄▄░φφφφ▄▄▄░░░░░╣▒░░░░░▄▄▒░░░░░╣░░
 *    ╠Γ░░░░░░░░╙░▒≥≥≥≥≥≥φ╡░░▐▒░║▓▒░░░░]▓▓╝╙╠░░░░░░░░╔▓░░░░░░░░▐▌└--∩░░░░║▌│░▒░░░░╣▒░░░░░╫▒╠░░░░░╣░░
 *    ╠Γ░░░░░░░░░░░░░░░░░╚╡░░░░░║▒╬░░░░░╩φ▒""╠░░░░░░φ▓╚▒░░░░░░░▐▌¡  Γ⌠░░░╙Θφ≥⌐░░░░╣▒φ░░░░╬░╙]░░░░╣░░
 *    ╠░░░░░░░░░░░░░░░░░░░░░░░░░║▒╬░░░░░░░░╟╕φ░░░░░▓▓.▐░░░░░░░░▐▌¡  Γ⌠░░░░░░░░░░░░╣▒░░░░░▒░░░░░░░╣░░
 *     ╙░░░░░░░░░░░░░░░░░░░░░░░╓╣▒╚░░░░░░░░╣▒░░░░╔▓╩;▒_φ░░░░░░░╟█¡  ╚░░░░░░░░░░░░▄▓▒░░░░░Γ░░░░░╔▓╩'Γ
 *       ╙╙╙╙╙╙╙╙╙╙╙╙╙║▓▀▀▀▀▀▀▀▀╝#▓#▀▀▀▀▀▀▀▀▀▓▀▀▀▓█▄▓###╣▓▀▀╫▓╙╙▄####▓▀▀▀▀▀▀▀▀▀▀▓▓░▒░░░░░╫▒╙╙╙╙╙░░╛
 *                   ╓▓'_________╫╩_________╔▌__╔▓█╙__▄▓▓▓░_▐▓▄╩└_╓▓▓▒_________φ▓╩_"φ▄▄▄φ▓⌐░
 *                   ▓╗╗╗ε░░φ╗╗╗▓▒░░╔▓▓▓∩░░╔▌.░╔╩│░░▄▓▓▀_║▒░░╩│░╓▓▓▓▒░░φ▓▓▓∩░░╔▓▌    _╚││¡≥"
 *                    _]▓σσ╣▓╜_╟▒σσ╣▓▌╔╬σσφ▓σσσσσσφ▓▓▀_  ▐▒σσσ▄▓▓▀╔▒σσφ▓▌╔╬σσφ▓▌_
 *                    ]▓░░╟▓▀ ╔▒░░░░░░░░░╠▓░░╠▓╬░░░╙█Q  ,▓░░░║▓▀_╔▒░░░░░░░░░║▓▌_
 *                   ,▓╚╚╫▓▌ ╔▒╚╝╚╚╚╚╚╚╚╢▓╚╚╢▓█_╙╣╢╝╚╚█µ▓╚╚╚╫▓╩ ╓▓╚╚╚╚╚╚╚╚╚╢▓▌_
 *                   ╚╝╝╝╝▀_ ╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝_   ╙╝╝╝╝╝╝╝╝╝╝╝  ╝╝╝╝╝╝╝╝╝╝╝╝╩_
 *
 */

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interface/IToken.sol";

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

contract CityPopTokyoClaimer is ReentrancyGuard {
    address public token;

    constructor(address _token) {
        token = _token;
    }

    function multipleTransferWithAuthorization(
        address[] memory from,
        address[] memory to,
        uint256[] memory amount,
        uint256[] memory deadline,
        bytes32[] memory nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external nonReentrant {
        require(
            from.length == to.length &&
                to.length == amount.length &&
                amount.length == deadline.length &&
                deadline.length == nonce.length &&
                nonce.length == v.length &&
                v.length == r.length &&
                r.length == s.length,
            "CityPopTokyoClaimer : length is mismatch"
        );

        for (uint256 a; a < from.length; a++) {
            IToken(token).transferWithAuthorization(
                from[a],
                to[a],
                amount[a],
                deadline[a],
                nonce[a],
                v[a],
                r[a],
                s[a]
            );
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

interface IToken {
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function authorizationState(
        address,
        address,
        bytes32
    ) external view returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function burnFrom(address owner, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external returns (bool);

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool);

    function initialize(
        uint256 supply_,
        address owner_,
        string memory tokenName_,
        string memory tokenSymbol_
    ) external;

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function proxiableUUID() external view returns (bytes32);

    function renounceOwnership() external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transferOwnership(address newOwner) external;

    function transferWithAuthorization(
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(
        address newImplementation,
        bytes memory data
    ) external;
}