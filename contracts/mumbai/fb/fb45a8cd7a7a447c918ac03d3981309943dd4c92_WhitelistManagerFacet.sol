/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../../diamond/IDiamondFacet.sol";
import "./WhitelistManagerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract WhitelistManagerFacet is IDiamondFacet {

    function getFacetName()
      external pure override returns (string memory) {
        return "whitelist-manager";
    }

    // CAUTION: Don't forget to update the version when adding new functionality
    function getFacetVersion()
      external pure override returns (string memory) {
        return "3.1.0";
    }

    function getFacetPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](5);
        pi[0] = "getWhitelistingSettings()";
        pi[1] = "setWhitelistingSettings(bool,uint256,uint256,uint256)";
        pi[2] = "whitelistMe(uint256,string)";
        pi[3] = "whitelistAccounts(address[],uint256[])";
        pi[4] = "getWhitelistEntry(address)";
        return pi;
    }

    function getFacetProtectedPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](2);
        pi[0] = "setWhitelistingSettings(bool,uint256,uint256,uint256)";
        pi[1] = "whitelistAccounts(address[],uint256[])";
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external pure override returns (bool) {
        return interfaceId == type(IDiamondFacet).interfaceId;
    }

    function getWhitelistingSettings()
      external view returns (bool, uint256, uint256, uint256, uint256) {
        return WhitelistManagerInternal._getWhitelistingSettings();
    }

    function setWhitelistingSettings(
        bool whitelistingAllowed,
        uint256 whitelistingFeeWei,
        uint256 whitelistingPriceWeiPerToken,
        uint256 maxNrOfWhitelistedTokensPerAccount
    ) external {
        WhitelistManagerInternal._setWhitelistingSettings(
            whitelistingAllowed,
            whitelistingFeeWei,
            whitelistingPriceWeiPerToken,
            maxNrOfWhitelistedTokensPerAccount
        );
    }

    // Send 0 for nrOfTokens to de-list the address
    function whitelistMe(
        uint256 nrOfTokens,
        string memory paymentMethodName
    ) external payable {
        WhitelistManagerInternal._whitelistAccount(
            msg.sender,
            nrOfTokens,
            paymentMethodName
        );
    }

    // Send 0 for nrOfTokens to de-list an address
    function whitelistAccounts(
        address[] memory accounts,
        uint256[] memory nrOfTokensArray
    ) external {
        WhitelistManagerInternal._whitelistAccounts(
            accounts,
            nrOfTokensArray
        );
    }

    function getWhitelistEntry(address account) external view returns (uint256) {
        return WhitelistManagerInternal._getWhitelistEntry(account);
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface IDiamondFacet is IERC165 {

    // NOTE: The override MUST remain 'pure'.
    function getFacetName() external pure returns (string memory);

    // NOTE: The override MUST remain 'pure'.
    function getFacetVersion() external pure returns (string memory);

    // NOTE: The override MUST remain 'pure'.
    function getFacetPI() external pure returns (string[] memory);

    // NOTE: The override MUST remain 'pure'.
    function getFacetProtectedPI() external pure returns (string[] memory);
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../payment-handler/PaymentHandlerLib.sol";
import "./WhitelistManagerStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library WhitelistManagerInternal {

    event Whitelist(address account, uint256 nrOfTokens);

    function _getWhitelistingSettings()
      internal view returns (bool, uint256, uint256, uint256, uint256) {
        return (
            __s().whitelistingAllowed,
            __s().whitelistingFeeWei,
            __s().whitelistingPriceWeiPerToken,
            __s().maxNrOfWhitelistedTokensPerAccount,
            __s().totalNrOfWhitelists
        );
    }

    function _setWhitelistingSettings(
        bool whitelistingAllowed,
        uint256 whitelistingFeeWei,
        uint256 whitelistingPriceWeiPerToken,
        uint256 maxNrOfWhitelistedTokensPerAccount
    ) internal {
        __s().whitelistingAllowed = whitelistingAllowed;
        __s().whitelistingFeeWei = whitelistingFeeWei;
        __s().whitelistingPriceWeiPerToken = whitelistingPriceWeiPerToken;
        __s().maxNrOfWhitelistedTokensPerAccount = maxNrOfWhitelistedTokensPerAccount;
    }

    // NOTE: Send 0 for nrOfTokens to de-list the address
    function _whitelistAccount(
        address account,
        uint256 nrOfTokens,
        string memory paymentMethodName
    ) internal {
        require(__s().whitelistingAllowed, "WM:NA");
        PaymentHandlerLib._handlePayment(
            1, __s().whitelistingFeeWei,
            nrOfTokens, __s().whitelistingPriceWeiPerToken,
            paymentMethodName
        );
        _whitelist(account, nrOfTokens);
    }

    // NOTE: Send 0 for nrOfTokens to de-list an address
    // NOTE: This is always allowed
    function _whitelistAccounts(
        address[] memory accounts,
        uint256[] memory nrOfTokensArray
    ) internal {
        require(accounts.length == nrOfTokensArray.length, "WM:IL");
        for (uint256 i = 0; i < accounts.length; i++) {
            _whitelist(accounts[i], nrOfTokensArray[i]);
        }
    }

    function _getWhitelistEntry(address account) internal view returns (uint256) {
        return __s().whitelistEntries[account];
    }

    function _whitelist(
        address account,
        uint256 nrOfTokens
    ) private {
        require(__s().maxNrOfWhitelistedTokensPerAccount == 0 ||
                nrOfTokens <= __s().maxNrOfWhitelistedTokensPerAccount,
                "WM:EMAX");
        if (nrOfTokens == 0){
            // de-list the account
            uint256 nrOfTokensToBeRemoved = __s().whitelistEntries[account];
            __s().whitelistEntries[account] = 0;
            __s().totalNrOfWhitelists -= nrOfTokensToBeRemoved;
        }
        else{
            __s().whitelistEntries[account] = nrOfTokens;
            __s().totalNrOfWhitelists += nrOfTokens;
        }
        emit Whitelist(account, nrOfTokens);
    }

    function __s() private pure returns (WhitelistManagerStorage.Layout storage) {
        return WhitelistManagerStorage.layout();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
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

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./PaymentHandlerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library PaymentHandlerLib {

    function _handlePayment(
        uint256 nrOfItems1, uint256 priceWeiPerItem1,
        uint256 nrOfItems2, uint256 priceWeiPerItem2,
        string memory paymentMethodName
    ) internal {
        PaymentHandlerInternal._handlePayment(
            nrOfItems1, priceWeiPerItem1,
            nrOfItems2, priceWeiPerItem2,
            paymentMethodName
        );
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library WhitelistManagerStorage {

    struct Layout {
        bool whitelistingAllowed;
        uint256 whitelistingFeeWei;
        uint256 whitelistingPriceWeiPerToken;
        uint256 maxNrOfWhitelistedTokensPerAccount;
        mapping(address => uint256) whitelistEntries;
        uint256 totalNrOfWhitelists;
        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.facets.collection.whitelist-manager.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../../IUniswapV2Pair.sol";
import "../payment-method-manager/PaymentMethodManagerLib.sol";
import "./PaymentHandlerStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library PaymentHandlerInternal {

    bytes32 constant public WEI_PAYMENT_METHOD_HASH = keccak256(abi.encode("WEI"));

    event TransferTo(
        address to,
        uint256 amount,
        string data
    );
    event TransferETH20To(
        string paymentMethodName,
        address to,
        uint256 amount,
        string data
    );

    function _getPaymentHandlerSettings() internal view returns (address) {
        return __s().payoutAddress;
    }

    function _setPaymentHandlerSettings(
        address payoutAddress
    ) internal {
        __s().payoutAddress = payoutAddress;
    }

    function _transferTo(
        string memory paymentMethodName,
        address to,
        uint256 amount,
        string memory data
    ) internal {
        require(to != address(0), "PH:TTZ");
        require(amount > 0, "PH:ZAM");
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        require(nameHash == WEI_PAYMENT_METHOD_HASH ||
                PaymentMethodManagerLib._paymentMethodExists(nameHash), "PH:MNS");
        if (nameHash == WEI_PAYMENT_METHOD_HASH) {
            require(amount <= address(this).balance, "PH:MTB");
            /* solhint-disable avoid-low-level-calls */
            (bool success, ) = to.call{value: amount}(new bytes(0));
            /* solhint-enable avoid-low-level-calls */
            require(success, "PH:TF");
            emit TransferTo(to, amount, data);
        } else {
            address erc20 =
                PaymentMethodManagerLib._getERC20PaymentMethodAddress(nameHash);
            require(amount <= IERC20(erc20).balanceOf(address(this)), "PH:MTB");
            IERC20(erc20).transfer(to, amount);
            emit TransferETH20To(paymentMethodName, to, amount, data);
        }
    }

    function _handlePayment(
        uint256 nrOfItems1, uint256 priceWeiPerItem1,
        uint256 nrOfItems2, uint256 priceWeiPerItem2,
        string memory paymentMethodName
    ) internal {
        uint256 totalWei =
            nrOfItems1 * priceWeiPerItem1 +
            nrOfItems2 * priceWeiPerItem2;
        if (totalWei == 0) {
            return;
        }
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        require(nameHash == WEI_PAYMENT_METHOD_HASH ||
                PaymentMethodManagerLib._paymentMethodExists(nameHash), "PH:MNS");
        if (nameHash == WEI_PAYMENT_METHOD_HASH) {
            PaymentMethodManagerLib._handleWeiPayment(
                msg.sender, __s().payoutAddress, msg.value, totalWei, "");
        } else {
            PaymentMethodManagerLib.
                _handleERC20Payment(
                    paymentMethodName, msg.sender, __s().payoutAddress, totalWei, "");
        }
    }

    function __s() private pure returns (PaymentHandlerStorage.Layout storage) {
        return PaymentHandlerStorage.layout();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./PaymentMethodManagerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library PaymentMethodManagerLib {

    function _handleWeiPayment(
        address payer,
        address dest,
        uint256 paidPriceWei, // could be the msg.value
        uint256 priceWeiToPay,
        string memory data
    ) internal {
        PaymentMethodManagerInternal._handleWeiPayment(
            payer,
            dest,
            paidPriceWei,
            priceWeiToPay,
            data
        );
    }

    function _handleERC20Payment(
        string memory paymentMethodName,
        address payer,
        address dest,
        uint256 priceWeiToPay,
        string memory data
    ) internal {
        PaymentMethodManagerInternal._handleERC20Payment(
            paymentMethodName,
            payer,
            dest,
            priceWeiToPay,
            data
        );
    }

    function _paymentMethodExists(
        bytes32 paymentMethodNameHash
    ) internal view returns (bool) {
        return PaymentMethodManagerLib._paymentMethodExists(paymentMethodNameHash);
    }

    function _paymentMethodEnabled(
        bytes32 paymentMethodNameHash
    ) internal view returns (bool) {
        return PaymentMethodManagerLib._paymentMethodEnabled(paymentMethodNameHash);
    }

    function _getERC20PaymentMethodAddress(
        bytes32 paymentMethodNameHash
    ) internal view returns (address) {
        return PaymentMethodManagerLib._getERC20PaymentMethodAddress(paymentMethodNameHash);
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library PaymentHandlerStorage {

    struct Layout {
        address payoutAddress;
        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.facets.collection.payment-handler.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../../IUniswapV2Pair.sol";
import "./PaymentMethodManagerStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library PaymentMethodManagerInternal {

    event ERC20PaymentMethodUpdate(
        string paymentMethodName,
        address erc20,
        address wethPair,
        bool enabled,
        string data
    );
    event WeiPayment(
        address payer,
        address dest,
        uint256 paidPriceWei,
        uint256 priceWeiToPay,
        string data
    );
    event ERC20Payment(
        string paymentMethodName,
        address payer,
        address dest,
        uint256 amountWei,
        uint256 amountTokens,
        string data
    );

    function _getPaymentMethodManagerSettings() internal view returns (address) {
        return __s().wethAddress;
    }

    function _setPaymentMethodManagerSettings(
        address wethAddress
    ) internal {
        __s().wethAddress = wethAddress;
    }

    function _getERC20PaymentMethods() internal view returns (string[] memory) {
        return __s().erc20PaymentMethodNames;
    }

    function _getERC20PaymentMethod(
        string memory paymentMethodName
    ) internal view returns (address, address, bool) {
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        require(_paymentMethodExists(nameHash), "PMM:NEM");
        return (
            __s().erc20PaymentMethods[nameHash].erc20,
            __s().erc20PaymentMethods[nameHash].wethPair,
            __s().erc20PaymentMethods[nameHash].enabled
        );
    }

    function _addOrUpdateERC20PaymentMethod(
        string memory paymentMethodName,
        address erc20,
        address wethPair,
        bool enabled,
        string memory data
    ) internal {
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        __s().erc20PaymentMethods[nameHash].erc20 = erc20;
        __s().erc20PaymentMethods[nameHash].wethPair = wethPair;
        __s().erc20PaymentMethods[nameHash].enabled = enabled;
        address token0 = IUniswapV2Pair(wethPair).token0();
        address token1 = IUniswapV2Pair(wethPair).token1();
        require(token0 == __s().wethAddress || token1 == __s().wethAddress, "PMM:IPC");
        bool reverseIndices = (token1 == __s().wethAddress);
        __s().erc20PaymentMethods[nameHash].reverseIndices = reverseIndices;
        if (__s().erc20PaymentMethodNamesIndex[paymentMethodName] == 0) {
            __s().erc20PaymentMethodNames.push(paymentMethodName);
            __s().erc20PaymentMethodNamesIndex[paymentMethodName] =
                __s().erc20PaymentMethodNames.length;
        }
        emit ERC20PaymentMethodUpdate(
            paymentMethodName, erc20, wethPair, enabled, data);
    }

    function _enableERC20TokenPayment(
        string memory paymentMethodName,
        bool enabled
    ) internal {
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        require(_paymentMethodExists(nameHash), "PMM:NEM");
        __s().erc20PaymentMethods[nameHash].enabled = enabled;
        emit ERC20PaymentMethodUpdate(
            paymentMethodName,
            __s().erc20PaymentMethods[nameHash].erc20,
            __s().erc20PaymentMethods[nameHash].wethPair,
            enabled,
            ""
        );
    }

    function _handleWeiPayment(
        address payer,
        address dest,
        uint256 paidPriceWei, // could be the msg.value
        uint256 priceWeiToPay,
        string memory data
    ) internal {
        require(paidPriceWei >= priceWeiToPay, "PMM:IF");
        uint256 remainder = paidPriceWei - priceWeiToPay;
        if (dest != address(0)) {
            /* solhint-disable avoid-low-level-calls */
            (bool success, ) = dest.call{value: priceWeiToPay}(new bytes(0));
            /* solhint-enable avoid-low-level-calls */
            require(success, "PMM:TF");
            emit WeiPayment(payer, dest, paidPriceWei, priceWeiToPay, data);
        } else {
            emit WeiPayment(
                payer, address(this), paidPriceWei, priceWeiToPay, data);
        }
        if (remainder > 0) {
            /* solhint-disable avoid-low-level-calls */
            (bool success, ) = payer.call{value: remainder}(new bytes(0));
            /* solhint-enable avoid-low-level-calls */
            require(success, "PMM:RTF");
        }
    }

    function _handleERC20Payment(
        string memory paymentMethodName,
        address payer,
        address dest,
        uint256 priceWeiToPay,
        string memory data
    ) internal {
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        require(_paymentMethodExists(nameHash), "PMM:NEM");
        require(_paymentMethodEnabled(nameHash), "PMM:NENM");
        PaymentMethodManagerStorage.ERC20PaymentMethod memory paymentMethod =
            __s().erc20PaymentMethods[nameHash];
        (uint112 amount0, uint112 amount1,) = IUniswapV2Pair(paymentMethod.wethPair).getReserves();
        uint256 reserveWei = amount0;
        uint256 reserveTokens = amount1;
        if (paymentMethod.reverseIndices) {
            reserveWei = amount1;
            reserveTokens = amount0;
        }
        require(reserveWei > 0, "PMM:NWR");
        // TODO(kam): check if this is OK
        uint256 amountTokens = (priceWeiToPay * reserveTokens) / reserveWei;
        if (dest == address(0)) {
            dest = address(this);
        }
        // this contract must have already been approved by the msg.sender
        IERC20(paymentMethod.erc20).transferFrom(payer, dest, amountTokens);
        emit ERC20Payment(
            paymentMethodName, payer, dest, priceWeiToPay, amountTokens, data);
    }

    function _paymentMethodExists(
        bytes32 paymentMethodNameHash
    ) internal view returns (bool) {
        return __s().erc20PaymentMethods[paymentMethodNameHash].erc20 != address(0) &&
               __s().erc20PaymentMethods[paymentMethodNameHash].wethPair != address(0);
    }

    function _paymentMethodEnabled(
        bytes32 paymentMethodNameHash
    ) internal view returns (bool) {
        return __s().erc20PaymentMethods[paymentMethodNameHash].enabled;
    }

    function _getERC20PaymentMethodAddress(
        bytes32 paymentMethodNameHash
    ) internal view returns (address) {
        require(_paymentMethodExists(paymentMethodNameHash), "PMM:NEM");
        return __s().erc20PaymentMethods[paymentMethodNameHash].erc20;
    }

    function __s() private pure returns (PaymentMethodManagerStorage.Layout storage) {
        return PaymentMethodManagerStorage.layout();
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library PaymentMethodManagerStorage {

    struct ERC20PaymentMethod {
        // The internal unique name of the ERC-20 payment method
        string name;
        // The ERC-20 contract
        address erc20;
        // Uniswap V2 Pair with WETH
        address wethPair;
        // True if the read pair from Uniswap has a reverse ordering
        // for contract addresses
        bool reverseIndices;
        // If the payment method is enabled
        bool enabled;
    }

    struct Layout {
        // The WETH ERC-20 contract address.
        //   On mainnet, it is: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
        address wethAddress;
        // The list of the existing ERC20 payment method names
        string[] erc20PaymentMethodNames;
        mapping(string => uint256)  erc20PaymentMethodNamesIndex;
        // name > erc20 payment method
        mapping(bytes32 => ERC20PaymentMethod) erc20PaymentMethods;
        // Reserved for future upgrades
        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.facets.collection.payment-method-manager.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}