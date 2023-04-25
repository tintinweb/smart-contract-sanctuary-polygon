// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @title Contract ownership standard interface (event only)
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173Events {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";

import "./OwnableStorage.sol";
import "./IERC173Events.sol";

abstract contract OwnableInternal is IERC173Events, Context {
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        require(_msgSender() == _owner(), "Ownable: sender must be owner");
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transferOwnership(address account) internal virtual {
        OwnableStorage.layout().setOwner(account);
        emit OwnershipTransferred(_msgSender(), account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openzeppelin.contracts.storage.Ownable");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setOwner(Layout storage l, address owner) internal {
        l.owner = owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IMarketplaceBaseOwnable {
    event FeeUpdate(uint104 newFee);
    event MintFeeUpdate(uint104 newMintFee);
    event DecimalsUpdate(uint8 newDecimals);
    event FeeReceipientUpdate(address newAddress);
    event PaymentOptionAdded(address token, address feed, uint8 decimals);
    event PaymentOptionRemoved(address token);

    function setFee(uint104 newFee) external;

    function setMintFee(uint104 newMintFee) external;

    function setDecimals(uint8 newDecimals) external;

    function setFeeReceipient(address newAddress) external;

    function addPayableToken(
        address token,
        address feed,
        uint8 decimals
    ) external;

    function removeTokenFeed(address token) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {OwnableInternal} from "../../access/ownable/OwnableInternal.sol";

import {MarketplaceBaseStorage} from "./storage/MarketplaceBaseStorage.sol";
import {IMarketplaceBaseOwnable} from "./interfaces/IMarketplaceBaseOwnable.sol";

/**
 * @title MarketplaceBaseOwnable - Admin - Ownable
 * @notice Allows diamond owner to change config of marketplace.
 *
 * @custom:type eip-2535-facet
 * @custom:category Marketplace
 * @custom:peer-dependencies OwnableInternal
 * @custom:provides-interfaces IMarketplaceBaseOwnable
 */
contract MarketplaceBaseOwnable is IMarketplaceBaseOwnable, OwnableInternal {
    function setFee(uint104 newFee) external override onlyOwner {
        MarketplaceBaseStorage.Layout storage l = MarketplaceBaseStorage
            .layout();
        l.sokosFee = newFee;
        emit FeeUpdate(newFee);
    }

    function setMintFee(uint104 newMintFee) external override onlyOwner {
        MarketplaceBaseStorage.Layout storage l = MarketplaceBaseStorage
            .layout();
        l.mintFee = newMintFee;
        emit MintFeeUpdate(newMintFee);
    }

    function setDecimals(uint8 newDecimals) external override onlyOwner {
        MarketplaceBaseStorage.Layout storage l = MarketplaceBaseStorage
            .layout();
        l.sokosDecimals = newDecimals;
        emit DecimalsUpdate(newDecimals);
    }

    function setFeeReceipient(address newAddress) external override onlyOwner {
        MarketplaceBaseStorage.Layout storage l = MarketplaceBaseStorage
            .layout();
        l.feeReceipient = payable(newAddress);
        emit FeeReceipientUpdate(newAddress);
    }

    function addPayableToken(
        address newToken,
        address feed,
        uint8 decimals
    ) external override onlyOwner {
        MarketplaceBaseStorage.Layout storage l = MarketplaceBaseStorage
            .layout();
        require(newToken != address(0), "invalid token");

        MarketplaceBaseStorage.TokenFeed memory token = l.payableToken[
            newToken
        ];
        require(token.feed != address(0), "already payable token");
        token.feed = feed;
        token.decimals = decimals;
        emit PaymentOptionAdded(newToken, feed, decimals);
    }

    function removeTokenFeed(address token) external override onlyOwner {
        require(token != address(0), "invalid token");

        MarketplaceBaseStorage.Layout storage l = MarketplaceBaseStorage
            .layout();

        delete l.payableToken[token];
        emit PaymentOptionRemoved(token);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library MarketplaceBaseStorage {
    struct TokenFeed {
        address feed;
        uint8 decimals;
    }

    struct Layout {
        uint104 sokosFee;
        uint104 mintFee;
        uint8 sokosDecimals;
        address payable feeReceipient;
        mapping(address => TokenFeed) payableToken;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("SOKOS.contracts.storage.MarketplaceBase");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}