pragma solidity ^0.8.0;
// SPDX-License-Identifier: SEE LICENSE IN LICENSE

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./IERC5006.sol";
import "./IERC1155RentalMarket.sol";

contract W5006Lib {
    function recordOf(
        address oNFT,
        address wNFT,
        uint256 recordId
    ) public view returns (IERC5006.UserRecord memory) {
        if (supportsInterface(oNFT, type(IERC5006).interfaceId)) {
            return IERC5006(oNFT).userRecordOf(recordId);
        } else {
            return IERC5006(wNFT).userRecordOf(recordId);
        }
    }

    function recordOf2(address market, uint256 rentingId)
        public
        view
        returns (
            IERC5006.UserRecord memory record,
            IERC1155RentalMarket.Renting memory renting,
            IERC1155RentalMarket.Lending memory lending,
            address nft5006,
            bool is5006
        )
    {
        renting = IERC1155RentalMarket(market).rentingOf(rentingId);
        if (renting.recordId == 0) {
            record = IERC5006.UserRecord(0, address(0), 0, address(0), 0);
        }
        lending = IERC1155RentalMarket(market).lendingOf(renting.lendingId);

        is5006 = IERC165(lending.nftAddress).supportsInterface(
            type(IERC5006).interfaceId
        );
        if (is5006) {
            record = IERC5006(lending.nftAddress).userRecordOf(
                renting.recordId
            );
            nft5006 = lending.nftAddress;
        } else {
            address wNFT = IERC1155RentalMarket(market).wNFTOf(
                lending.nftAddress
            );
            record = IERC5006(wNFT).userRecordOf(renting.recordId);
            nft5006 = wNFT;
        }
    }

    function supportsInterface(address nft, bytes4 interfaceId)
        public
        view
        returns (bool)
    {
        return IERC165(nft).supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6 <0.9.0;

import "./IWrappedInERC5006.sol";

interface IERC1155RentalMarket {
    struct Lending {
        uint256 nftId;
        address nftAddress;
        uint64 amount;
        address lender;
        uint64 frozen;
        address renter;
        uint64 expiry;
        address paymentToken;
        uint96 pricePerDay;
    }

    struct Renting {
        bytes32 lendingId;
        uint256 recordId;
    }

    event UpdateLending(
        bytes32 lendingId,
        uint256 nftId,
        address nftAddress,
        uint64 amount,
        address lender,
        address renter,
        uint64 expiry,
        address paymentToken,
        uint96 pricePerDay
    );

    event CancelLending(bytes32 lendingId);

    event Rent(
        bytes32 lendingId,
        uint256 rentingId,
        uint256 nftId,
        address nftAddress,
        uint64 amount,
        address to,
        uint64 duration,
        address paymentToken,
        uint96 pricePerDay
    );
    event ClearRent(uint256 rentingId);

    event DeployWrapERC5006(address oNFT, address wNFT);

    function createLending(
        address nftAddress,
        uint256 nftId,
        uint64 amount,
        uint64 expiry,
        uint96 pricePerDay,
        address paymentToken,
        address renter
    ) external;

    function cancelLending(bytes32 lendingId) external;

    function clearRenting5006(uint256[] calldata rentingIds) external;

    function clearRenting1155(uint256[] calldata rentingIds) external;

    function lendingOf(bytes32 lendingId)
        external
        view
        returns (Lending memory);

    function rentingOf(uint256 rentingId)
        external
        view
        returns (Renting memory);

    function recordOf(uint256 rentingId)
        external
        view
        returns (IERC5006.UserRecord memory);

    function rent5006(
        bytes32 lendingId,
        uint64 amount,
        uint64 cycleAmount,
        address to,
        address paymentToken,
        uint96 pricePerDay
    ) external payable;

    function rent1155(
        bytes32 lendingId,
        uint64 amount,
        uint64 cycleAmount,
        address to,
        address paymentToken,
        uint96 pricePerDay
    ) external payable;

    function wNFTOf(address nftAddress) external view returns (address);

}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IERC5006 {
    struct UserRecord {
        uint256 tokenId;
        address owner;
        uint64 amount;
        address user;
        uint64 expiry;
    }
    /**
     * @dev Emitted when permission (for `user` to use `amount` of `tokenId` token owned by `owner`
     * until `expiry`) is given.
     */
    event CreateUserRecord(
        uint256 recordId,
        uint256 tokenId,
        uint64 amount,
        address owner,
        address user,
        uint64 expiry
    );
    /**
     * @dev Emitted when record of `recordId` is deleted. 
     */
    event DeleteUserRecord(uint256 recordId);

    /**
     * @dev Returns the usable amount of `tokenId` tokens  by `account`.
     */
    function usableBalanceOf(address account, uint256 tokenId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the amount of frozen tokens of token type `id` by `account`.
     */
    function frozenBalanceOf(address account, uint256 tokenId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the `UserRecord` of `recordId`.
     */
    function userRecordOf(uint256 recordId)
        external
        view
        returns (UserRecord memory);

    /**
     * @dev Gives permission to `user` to use `amount` of `tokenId` token owned by `owner` until `expiry`.
     *
     * Emits a {CreateUserRecord} event.
     *
     * Requirements:
     *
     * - If the caller is not `owner`, it must be have been approved to spend ``owner``'s tokens
     * via {setApprovalForAll}.
     * - `owner` must have a balance of tokens of type `id` of at least `amount`.
     * - `user` cannot be the zero address.
     * - `amount` must be greater than 0.
     * - `expiry` must after the block timestamp.
     */
    function createUserRecord(
        address owner,
        address user,
        uint256 tokenId,
        uint64 amount,
        uint64 expiry
    ) external returns (uint256);

    /**
     * @dev Atomically delete `record` of `recordId` by the caller.
     *
     * Emits a {DeleteUserRecord} event.
     *
     * Requirements:
     *
     * - the caller must have allowance.
     */
    function deleteUserRecord(uint256 recordId) external;
}

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

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "./IWrappedIn.sol";
import "./IERC5006.sol";

interface IWrappedInERC5006 is IERC5006, IWrappedIn {
    function stakeAndCreateUserRecord(
        uint256 tokenId,
        uint64 amount,
        address to,
        uint64 expiry
    ) external returns (uint256);

    function redeemRecord(uint256 recordId, address to) external;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IWrappedIn {
    function stake(
        uint256 tokenId,
        uint256 amount,
        address to
    ) external;

    function redeem(
        uint256 tokenId,
        uint256 amount,
        address to
    ) external;

    function initializeWrap(
        address originalAddress_
    ) external;
}