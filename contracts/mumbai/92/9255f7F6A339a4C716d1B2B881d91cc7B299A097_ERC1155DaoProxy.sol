// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

// interfaces
import "./interfaces/IERC1155DaoProxy.sol";

/**
 * @title ERC1155DaoAbstract
 *
 * @author Farasat Ali
 *
 * @notice contains ERC1155Dao function signatures.
 *
 * @dev This is an abstract contract that will provide functions to be
 * called by proxy contract.
 */

abstract contract ERC1155DaoAbstract is IERC1155DaoProxy {
    function getPlatformFeesInWei() external view returns (uint256) {}

    function getTokenDetails(
        uint256 tokenId
    ) external view returns (TokenDetails memory) {}

    function getTokenBearer(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (TokenBearer memory) {}

    function getBalance(
        uint256 tokenId,
        address account
    ) external view returns (uint256) {}

    function getHighestBidder(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (address) {}

    function getOtherBidders(
        uint256 tokenId,
        uint256 serialNo,
        address bidder
    ) external view returns (uint256) {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

// abstract contract
import "./ERC1155DaoAbstract.sol";
// interface
import "./interfaces/IERC1155DaoProxy.sol";

/**
 * @title ERC1155Dao:
 *
 * @author Farasat Ali
 *
 * @dev Imherits the ERC1155 contract and provide functionality for lending/borrowing,
 * transfering, minting, bidding.
 */
contract ERC1155DaoProxy is IERC1155DaoProxy {
    // ============================================================= //
    //                          VARIABLES                            //
    // ============================================================= //

    ERC1155DaoAbstract private _erc1155dao;

    address private _erc1155daoproxy;

    // ============================================================= //
    //                          MODIFIERS                            //
    // ============================================================= //

    // revert the transaction if lengths mismatch
    modifier denyIfLengthMismatch(uint256 arg1Length, uint256 arg2Length) {
        require(arg1Length == arg2Length, "ERC1155Dao: Args Length Mismatch");
        _;
    }

    // ============================================================= //
    //                          Constructor                          //
    // ============================================================= //

    constructor(address erc1155dao) {
        _erc1155daoproxy = erc1155dao;
        _erc1155dao = ERC1155DaoAbstract(erc1155dao);
    }

    // ============================================================= //
    //                          METHODS                              //
    // ============================================================= //

    function balanceOf(
        uint256 tokenId,
        address account
    ) public view returns (uint256) {
        return _erc1155dao.getBalance(tokenId, account);
    }

    function balanceOfBatch(
        uint256[] memory tokenIds,
        address[] memory accounts
    )
        external
        view
        denyIfLengthMismatch(accounts.length, tokenIds.length)
        returns (uint256[] memory)
    {
        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(tokenIds[i], accounts[i]);
        }

        return batchBalances;
    }

    function ownerOf(
        uint256 tokenId,
        uint256 serialNo
    ) public view returns (address) {
        TokenDetails memory td = _erc1155dao.getTokenDetails(tokenId);

        require(td.isMinted, "ERC1155Dao: Not Minted");
        require(td.totalSupply >= serialNo, "ERC1155Dao: Invalid Serial No.");

        uint256 tokenBalance = _erc1155dao.getBalance(
            tokenId,
            _erc1155daoproxy
        );

        if (tokenBalance < serialNo) {
            return _erc1155dao.getTokenBearer(tokenId, serialNo).user;
        } else {
            return _erc1155daoproxy;
        }
    }

    function ownerOfBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    )
        external
        view
        denyIfLengthMismatch(tokenIds.length, serialNos.length)
        returns (address[] memory)
    {
        address[] memory owners = new address[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            owners[i] = ownerOf(tokenIds[i], serialNos[i]);
        }

        return owners;
    }

    function mintStatus(uint256 tokenId) public view returns (bool) {
        return _erc1155dao.getTokenDetails(tokenId).isMinted;
    }

    function mintStatusBatch(
        uint256[] memory tokenIds
    ) external view returns (bool[] memory) {
        bool[] memory batchMintStatus = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            batchMintStatus[i] = mintStatus(tokenIds[i]);
        }
        return batchMintStatus;
    }

    function totalSupply(uint256 tokenId) public view returns (uint256) {
        return _erc1155dao.getTokenDetails(tokenId).totalSupply;
    }

    function totalSupplyBatch(
        uint256[] memory tokenIds
    ) external view returns (uint256[] memory) {
        uint256[] memory batchTotalSupply = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            batchTotalSupply[i] = totalSupply(tokenIds[i]);
        }
        return batchTotalSupply;
    }

    function tokenPrice(uint256 tokenId) public view returns (uint200) {
        return _erc1155dao.getTokenDetails(tokenId).tokenPrice;
    }

    function tokenPriceBatch(
        uint256[] memory tokenIds
    ) external view returns (uint200[] memory) {
        uint200[] memory batchTokenPrice = new uint200[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            batchTokenPrice[i] = tokenPrice(tokenIds[i]);
        }
        return batchTokenPrice;
    }

    function getTokenExpectedUsageLife(
        uint256 tokenId
    ) public view returns (uint32) {
        return _erc1155dao.getTokenDetails(tokenId).expectedUsageLife;
    }

    function getTokenExpectedUsageLifeBatch(
        uint256[] memory tokenIds
    ) external view returns (uint32[] memory) {
        uint32[] memory batchTokenEUL = new uint32[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            batchTokenEUL[i] = getTokenExpectedUsageLife(tokenIds[i]);
        }
        return batchTokenEUL;
    }

    function getTokenExpiryDate(uint256 tokenId) public view returns (uint48) {
        return _erc1155dao.getTokenDetails(tokenId).expireOn;
    }

    function getTokenExpiryDateBatch(
        uint256[] memory tokenIds
    ) external view returns (uint48[] memory) {
        uint48[] memory batchTokenED = new uint48[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            batchTokenED[i] = getTokenExpiryDate(tokenIds[i]);
        }
        return batchTokenED;
    }

    function getTokenBiddingLife(
        uint256 tokenId,
        uint256 serialNo
    ) public view returns (uint48) {
        return _erc1155dao.getTokenBearer(tokenId, serialNo).biddingLife;
    }

    function getTokenBiddingLifeBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (uint48[] memory) {
        uint48[] memory batchTokenBL = new uint48[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            batchTokenBL[i] = getTokenBiddingLife(tokenIds[i], serialNos[i]);
        }
        return batchTokenBL;
    }

    function getStartingPriceForAuction(
        uint256 tokenId,
        uint256 serialNo
    ) public view returns (uint256) {
        TokenBearer memory tokenOwner = _erc1155dao.getTokenBearer(
            tokenId,
            serialNo
        );
        uint256 startingPriceForAuction;

        if (tokenOwner.bidStartingPrice > 0) {
            startingPriceForAuction =
                tokenOwner.bidStartingPrice +
                _erc1155dao.getPlatformFeesInWei();
        } else {
            startingPriceForAuction = 0;
        }

        return startingPriceForAuction;
    }

    function getStartingPriceForAuctionBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (uint256[] memory) {
        uint256[] memory batchTokenBL = new uint256[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            batchTokenBL[i] = getStartingPriceForAuction(
                tokenIds[i],
                serialNos[i]
            );
        }
        return batchTokenBL;
    }

    function checkStartingPriceForAuction(
        uint256 tokenId,
        uint256 serialNo,
        uint256 biddingLife
    ) public view returns (uint256) {
        TokenBearer memory tokenOwner = _erc1155dao.getTokenBearer(
            tokenId,
            serialNo
        );
        TokenDetails memory tokenDet = _erc1155dao.getTokenDetails(tokenId);

        require(
            !(tokenOwner.startOfLife == 0 &&
                block.timestamp < tokenDet.expireOn),
            "ERC1155Dao: Token Expired"
        );
        require(
            !(tokenOwner.startOfLife != 0 &&
                block.timestamp + biddingLife > tokenOwner.endOfLife),
            "ERC1155Dao: Not Enough Token Life"
        );

        uint256 bidStartingPrice;

        unchecked {
            if (tokenOwner.startOfLife == 0) {
                bidStartingPrice = (tokenDet.tokenPrice / 100) * 50;
            } else {
                bidStartingPrice =
                    ((tokenDet.tokenPrice / 100) * 50) *
                    (((tokenOwner.endOfLife - tokenOwner.startOfLife) / 100) *
                        tokenOwner.endOfLife);
            }
        }

        return bidStartingPrice;
    }

    function checkStartingPriceForAuctionBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos,
        uint256[] memory biddingLives
    ) external view returns (uint256[] memory) {
        uint256[] memory bidStartingPrices = new uint256[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            bidStartingPrices[i] = checkStartingPriceForAuction(
                tokenIds[i],
                serialNos[i],
                biddingLives[i]
            );
        }
        return bidStartingPrices;
    }

    function getListPriceForFixedPrice(
        uint256 tokenId,
        uint256 serialNo
    ) public view returns (uint256) {
        TokenBearer memory tokenOwner = _erc1155dao.getTokenBearer(
            tokenId,
            serialNo
        );
        uint256 listPriceForFixedPrice;

        if (tokenOwner.listingPrice > 0) {
            listPriceForFixedPrice =
                tokenOwner.listingPrice +
                _erc1155dao.getPlatformFeesInWei();
        } else {
            listPriceForFixedPrice = 0;
        }

        return listPriceForFixedPrice;
    }

    function getListPriceForFixedPriceBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (uint256[] memory) {
        uint256[] memory batchTokenBL = new uint256[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            batchTokenBL[i] = getListPriceForFixedPrice(
                tokenIds[i],
                serialNos[i]
            );
        }

        return batchTokenBL;
    }

    function checkListPriceForFixedPriceRange(
        uint256 tokenId,
        uint256 serialNo
    ) public view returns (ListingPriceTuple memory) {
        TokenBearer memory tokenOwner = _erc1155dao.getTokenBearer(
            tokenId,
            serialNo
        );
        TokenDetails memory tokenDet = _erc1155dao.getTokenDetails(tokenId);

        require(
            !(tokenOwner.startOfLife == 0 &&
                block.timestamp < tokenDet.expireOn),
            "ERC1155Dao: Token Expired"
        );
        require(
            !(tokenOwner.startOfLife != 0 &&
                block.timestamp > tokenOwner.endOfLife),
            "ERC1155Dao: Not Enough Token Life"
        );

        uint256 fixedPrice;

        unchecked {
            if (tokenOwner.startOfLife == 0) {
                fixedPrice = (tokenDet.tokenPrice / 100) * 90;
            } else {
                fixedPrice =
                    ((tokenDet.tokenPrice / 100) * 90) *
                    (((tokenOwner.endOfLife - tokenOwner.startOfLife) / 100) *
                        tokenOwner.endOfLife);
            }
        }

        return ListingPriceTuple(fixedPrice / 1000, fixedPrice / 10);
    }

    function checkListPriceForFixedPriceRangesBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (ListingPriceTuple[] memory) {
        ListingPriceTuple[] memory listingPriceRanges = new ListingPriceTuple[](
            tokenIds.length
        );

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            listingPriceRanges[i] = checkListPriceForFixedPriceRange(
                tokenIds[i],
                serialNos[i]
            );
        }

        return listingPriceRanges;
    }

    function getListPriceForLendingPerDay(
        uint256 tokenId,
        uint256 serialNo
    ) public view returns (uint256) {
        TokenBearer memory tokenOwner = _erc1155dao.getTokenBearer(
            tokenId,
            serialNo
        );
        uint256 listPriceForLending;

        if (tokenOwner.lendingPricePerDay > 0) {
            listPriceForLending =
                tokenOwner.lendingPricePerDay +
                _erc1155dao.getPlatformFeesInWei();
        } else {
            listPriceForLending = 0;
        }

        return listPriceForLending;
    }

    function getListPriceForLendingPerDayBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (uint256[] memory) {
        uint256[] memory batchListPFL = new uint256[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            batchListPFL[i] = getListPriceForLendingPerDay(
                tokenIds[i],
                serialNos[i]
            );
        }

        return batchListPFL;
    }

    function getListPriceForLendingNDays(
        uint256 tokenId,
        uint256 serialNo,
        uint256 noOfDays
    ) public view returns (uint256) {
        TokenBearer memory tokenOwner = _erc1155dao.getTokenBearer(
            tokenId,
            serialNo
        );
        uint256 listPriceForLending;

        if (tokenOwner.lendingPricePerDay > 0) {
            listPriceForLending =
                (tokenOwner.lendingPricePerDay * noOfDays) +
                _erc1155dao.getPlatformFeesInWei();
        } else {
            listPriceForLending = 0;
        }

        return listPriceForLending;
    }

    function getListPriceForLendingPerNDaysBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos,
        uint256[] memory noOfDays
    ) external view returns (uint256[] memory) {
        uint256[] memory batchListPFL = new uint256[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            batchListPFL[i] = getListPriceForLendingNDays(
                tokenIds[i],
                serialNos[i],
                noOfDays[i]
            );
        }

        return batchListPFL;
    }

    function checkLendingPrice(
        uint256 tokenId,
        uint256 serialNo
    ) public view returns (ListingPriceTuple memory) {
        TokenBearer memory tokenOwner = _erc1155dao.getTokenBearer(
            tokenId,
            serialNo
        );
        TokenDetails memory tokenDet = _erc1155dao.getTokenDetails(tokenId);

        require(
            !(tokenOwner.startOfLife == 0 &&
                block.timestamp < tokenDet.expireOn),
            "ERC1155Dao: Token Expired"
        );
        require(
            !(tokenOwner.startOfLife != 0 &&
                block.timestamp > tokenOwner.endOfLife),
            "ERC1155Dao: Not Enough Token Life"
        );

        uint256 lendingPrice;
        uint256 lendingPriceFloor;
        uint256 lendingPriceCeil;

        unchecked {
            lendingPrice = (tokenDet.tokenPrice / 100) * 98;
            (lendingPriceFloor, lendingPriceCeil) = (
                lendingPrice / 1000 + _erc1155dao.getPlatformFeesInWei(),
                lendingPrice / 10 + _erc1155dao.getPlatformFeesInWei()
            );
        }

        return ListingPriceTuple(lendingPriceFloor, lendingPriceCeil);
    }

    function checkLendingPriceBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (ListingPriceTuple[] memory) {
        ListingPriceTuple[] memory lendingPriceRanges = new ListingPriceTuple[](
            tokenIds.length
        );

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            lendingPriceRanges[i] = checkLendingPrice(
                tokenIds[i],
                serialNos[i]
            );
        }

        return lendingPriceRanges;
    }

    function isOpenForAuction(
        uint256 tokenId,
        uint256 serialNo
    ) public view returns (bool) {
        return
            _erc1155dao.getTokenBearer(tokenId, serialNo).fixedOrAuction == 2;
    }

    function isOpenForAuctionBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    )
        public
        view
        denyIfLengthMismatch(tokenIds.length, serialNos.length)
        returns (bool[] memory)
    {
        bool[] memory batchIsOpenForAuction = new bool[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            batchIsOpenForAuction[i] = isOpenForAuction(
                tokenIds[i],
                serialNos[i]
            );
        }

        return batchIsOpenForAuction;
    }

    function isOpenForFixedPrice(
        uint256 tokenId,
        uint256 serialNo
    ) public view returns (bool) {
        return
            _erc1155dao.getTokenBearer(tokenId, serialNo).fixedOrAuction == 1;
    }

    function isOpenForFixedPriceBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    )
        public
        view
        denyIfLengthMismatch(tokenIds.length, serialNos.length)
        returns (bool[] memory)
    {
        bool[] memory batchIsOpenForFixedPrice = new bool[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            batchIsOpenForFixedPrice[i] = isOpenForFixedPrice(
                tokenIds[i],
                serialNos[i]
            );
        }

        return batchIsOpenForFixedPrice;
    }

    function isOpenLending(
        uint256 tokenId,
        uint256 serialNo
    ) public view returns (bool) {
        return _erc1155dao.getTokenBearer(tokenId, serialNo).lendingStatus;
    }

    function isOpenLendingBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    )
        public
        view
        denyIfLengthMismatch(tokenIds.length, serialNos.length)
        returns (bool[] memory)
    {
        bool[] memory batchIsOpenForFixedPrice = new bool[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            batchIsOpenForFixedPrice[i] = isOpenLending(
                tokenIds[i],
                serialNos[i]
            );
        }

        return batchIsOpenForFixedPrice;
    }

    function isTokenActivated(
        uint256 tokenId,
        uint256 serialNo
    ) public view returns (bool) {
        return _erc1155dao.getTokenBearer(tokenId, serialNo).isActivated;
    }

    function isTokenActivatedBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    )
        external
        view
        denyIfLengthMismatch(tokenIds.length, serialNos.length)
        returns (bool[] memory)
    {
        bool[] memory batchIsTokenActivated = new bool[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            batchIsTokenActivated[i] = isTokenActivated(
                tokenIds[i],
                serialNos[i]
            );
        }

        return batchIsTokenActivated;
    }

    function getTokenStartOfLife(
        uint256 tokenId,
        uint256 serialNo
    ) public view returns (uint48) {
        return _erc1155dao.getTokenBearer(tokenId, serialNo).startOfLife;
    }

    function getTokenStartOfLifeBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    )
        external
        view
        denyIfLengthMismatch(tokenIds.length, serialNos.length)
        returns (uint48[] memory)
    {
        uint48[] memory batchTokenSOL = new uint48[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            batchTokenSOL[i] = getTokenStartOfLife(tokenIds[i], serialNos[i]);
        }

        return batchTokenSOL;
    }

    function getTokenEndOfLife(
        uint256 tokenId,
        uint256 serialNo
    ) public view returns (uint48) {
        return _erc1155dao.getTokenBearer(tokenId, serialNo).endOfLife;
    }

    function getTokenEndOfLifeBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    )
        external
        view
        denyIfLengthMismatch(tokenIds.length, serialNos.length)
        returns (uint48[] memory)
    {
        uint48[] memory batchTokenEOL = new uint48[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            batchTokenEOL[i] = getTokenEndOfLife(tokenIds[i], serialNos[i]);
        }

        return batchTokenEOL;
    }

    function getPlatformFeesInWei() external view returns (uint256) {
        return _erc1155dao.getPlatformFeesInWei();
    }

    function isTokenActive(
        uint256 tokenId,
        uint256 serialNo
    ) public view returns (bool) {
        return _erc1155dao.getTokenBearer(tokenId, serialNo).isActivated;
    }

    function isTokenActiveBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    )
        external
        view
        denyIfLengthMismatch(tokenIds.length, serialNos.length)
        returns (bool[] memory)
    {
        bool[] memory batchIsActive = new bool[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            batchIsActive[i] = isTokenActive(tokenIds[i], serialNos[i]);
        }

        return batchIsActive;
    }

    function getHighestBid(
        uint256 tokenId,
        uint256 serialNo
    ) public view returns (uint256) {
        return
            _erc1155dao.getOtherBidders(
                tokenId,
                serialNo,
                _erc1155dao.getHighestBidder(tokenId, serialNo)
            );
    }

    function getHighestBidBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (uint256[] memory) {
        uint256[] memory batchHighestBids = new uint256[](tokenIds.length);

        for (uint i = 0; i < tokenIds.length; ++i) {
            batchHighestBids[i] = getHighestBid(tokenIds[i], serialNos[i]);
        }

        return batchHighestBids;
    }

    function getHighestBidder(
        uint256 tokenId,
        uint256 serialNo
    ) public view returns (address) {
        return _erc1155dao.getHighestBidder(tokenId, serialNo);
    }

    function getHighestBidderBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (address[] memory) {
        address[] memory batchHighestBidders = new address[](tokenIds.length);

        for (uint i = 0; i < tokenIds.length; ++i) {
            batchHighestBidders[i] = getHighestBidder(
                tokenIds[i],
                serialNos[i]
            );
        }

        return batchHighestBidders;
    }

    function getYourBid(
        uint256 tokenId,
        uint256 serialNo
    ) public view returns (uint256) {
        return _erc1155dao.getOtherBidders(tokenId, serialNo, msg.sender);
    }

    function getYourBidsBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (uint256[] memory) {
        uint256[] memory batchYourBids = new uint256[](tokenIds.length);

        for (uint i = 0; i < tokenIds.length; ++i) {
            batchYourBids[i] = getYourBid(tokenIds[i], serialNos[i]);
        }

        return batchYourBids;
    }

    function isYourBidHighest(
        uint256 tokenId,
        uint256 serialNo
    ) public view returns (bool) {
        return msg.sender == _erc1155dao.getHighestBidder(tokenId, serialNo);
    }

    function isYourBidsHighestsBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (bool[] memory) {
        bool[] memory batchIsYourBH = new bool[](tokenIds.length);

        for (uint i = 0; i < tokenIds.length; ++i) {
            batchIsYourBH[i] = isYourBidHighest(tokenIds[i], serialNos[i]);
        }

        return batchIsYourBH;
    }

    function getUserBid(
        uint256 tokenId,
        uint256 serialNo,
        address user
    ) public view returns (uint256) {
        return _erc1155dao.getOtherBidders(tokenId, serialNo, user);
    }

    function getUserBidBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos,
        address[] memory users
    ) external view returns (uint256[] memory) {
        uint256[] memory batchUserBids = new uint256[](tokenIds.length);

        for (uint i = 0; i < tokenIds.length; ++i) {
            batchUserBids[i] = getUserBid(tokenIds[i], serialNos[i], users[i]);
        }

        return batchUserBids;
    }

    function getTokenStatus(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (TokenStatus memory) {
        TokenBearer memory tokenOwner = _erc1155dao.getTokenBearer(
            tokenId,
            serialNo
        );
        TokenDetails memory tokenDet = _erc1155dao.getTokenDetails(tokenId);

        TokenStatus memory tokenStatus;

        if (tokenOwner.user == address(0)) {
            tokenStatus = TokenStatus({
                tokenOwner: address(0),
                useability: false,
                reason: "Token Not Assigned"
            });
        } else if (
            !tokenOwner.isActivated && block.timestamp >= tokenDet.expireOn
        ) {
            tokenStatus = TokenStatus({
                tokenOwner: tokenOwner.user,
                useability: false,
                reason: "Token Expired"
            });
        } else if (
            tokenOwner.isActivated &&
            tokenOwner.startOfLife + block.timestamp >= tokenOwner.endOfLife
        ) {
            tokenStatus = TokenStatus({
                tokenOwner: tokenOwner.user,
                useability: false,
                reason: "Token End of Life"
            });
        } else if (
            tokenOwner.lendingStatus &&
            tokenOwner.borrowingStartTimestamp + tokenOwner.borrowingPeriod <
            block.timestamp
        ) {
            tokenStatus = TokenStatus({
                tokenOwner: tokenOwner.borrower,
                useability: true,
                reason: "Token Available to Borrower"
            });
        } else if (
            tokenOwner.lendingStatus &&
            tokenOwner.borrowingStartTimestamp + tokenOwner.borrowingPeriod >
            block.timestamp &&
            tokenOwner.lendingStartTimestamp + tokenOwner.lendingPeriod <
            block.timestamp
        ) {
            tokenStatus = TokenStatus({
                tokenOwner: tokenOwner.user,
                useability: false,
                reason: "Token in Lending, Not Borrowed"
            });
        } else if (
            tokenOwner.lendingStatus &&
            tokenOwner.borrowingStartTimestamp + tokenOwner.borrowingPeriod >
            block.timestamp &&
            tokenOwner.lendingStartTimestamp + tokenOwner.lendingPeriod >
            block.timestamp
        ) {
            tokenStatus = TokenStatus({
                tokenOwner: tokenOwner.user,
                useability: true,
                reason: "Token Available to User"
            });
        } else if (
            tokenOwner.lendingStatus &&
            tokenOwner.borrowingStartTimestamp == 0 &&
            tokenOwner.lendingStartTimestamp + tokenOwner.lendingPeriod <
            block.timestamp
        ) {
            tokenStatus = TokenStatus({
                tokenOwner: tokenOwner.user,
                useability: false,
                reason: "Token in Lending, Not Borrowed"
            });
        } else if (
            tokenOwner.lendingStatus &&
            tokenOwner.borrowingStartTimestamp == 0 &&
            tokenOwner.lendingStartTimestamp + tokenOwner.lendingPeriod >
            block.timestamp
        ) {
            tokenStatus = TokenStatus({
                tokenOwner: tokenOwner.user,
                useability: true,
                reason: "Token Available to User"
            });
        } else if (
            tokenOwner.lendingStatus &&
            tokenOwner.borrowingStartTimestamp == 0 &&
            tokenOwner.lendingStartTimestamp == 0
        ) {
            tokenStatus = TokenStatus({
                tokenOwner: tokenOwner.user,
                useability: true,
                reason: "Token Available to User"
            });
        } else if (!tokenOwner.isActivated) {
            tokenStatus = TokenStatus({
                tokenOwner: tokenOwner.user,
                useability: false,
                reason: "Token Not Active"
            });
        } else if (
            tokenOwner.isActivated &&
            tokenOwner.fixedOrAuction == 0 &&
            !tokenOwner.lendingStatus
        ) {
            tokenStatus = TokenStatus({
                tokenOwner: tokenOwner.user,
                useability: true,
                reason: "Token Available to User"
            });
        } else if (tokenOwner.isActivated && tokenOwner.fixedOrAuction > 0) {
            tokenStatus = TokenStatus({
                tokenOwner: tokenOwner.user,
                useability: false,
                reason: "Token in Auction or Listed for Sale"
            });
        }

        return tokenStatus;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

interface IERC1155DaoProxy {
    /**
     * @dev Struct to return the min max prices in the functions.
     *
     * @param min   Min price in the function. It will be a number less than max.
     * @param max   Max price in the function. It will be a number greater than min.
     */
    struct ListingPriceTuple {
        uint256 min;
        uint256 max;
    }

    /**
     * @dev Struct to return the status of the token in the functions.
     *
     * @param tokenOwner    address of the current owner of the token. It can be the `Owner` of the token or `Borrower` of the token.
     * @param useability    is token useable or not. It can be `true` for useable and `false` for not useable.
     * @param reason        tells the reason why it is useable or not. It can be `Token Not Assigned`, `Token Expired`, `Token End of Life`, `Token Available to Borrower`, `Token in Lending, Not Borrowed`, `Token Available to User`, `Token Not Active` and `Token in Auction or Listed for Sale`
     */
    struct TokenStatus {
        address tokenOwner;
        bool useability;
        string reason;
    }

    /**
     * @dev Struct to provide the details of the token and it is populated after token is minted
     *
     * @param tokenSupply           total supply of the token.
     * @param tokenPrice            price of each token.
     * @param expectedUsageLife     time period to which token can be used.
     * @param isMinted              tells whether the token is minted or not. If `true` then token is minted and if `false` the token is not minted.
     * @param expireOn              expiry date for the token.
     */
    struct TokenDetails {
        // 256-bits
        uint256 totalSupply;
        // 192-bits
        uint104 tokenPrice;
        uint32 expectedUsageLife;
        bool isMinted;
        uint48 expireOn;
    }

    /**
     * @dev Struct to provide the details of the user, bidding, listing, lending/borrowing and activation of the token.
     *
     * @param user                      original owner of the token.
     * @param startOfLife               starting timestamp of the token when it became first active.
     * @param endOfLife                 ending timestamp of the token calculated after it became active.
     * @param borrower                  address of the borrower of the token. Default is 0 address if no borrower.
     * @param lendingStartTimestamp     timestamp when lending is started for the token and by default it is 0.
     * @param borrowingStartTimestamp   timestamp when borrowing is started for the token and by default it is 0.
     * @param bidStartingPrice          starting bidding price for the token and by default it is 0.
     * @param biddingLife               Duration for the bidding of a token and by default it is 0.
     * @param listingPrice              listing price for the token and by default it is 0.
     * @param lendingStatus             lending status of the token and by default it is `false` which means lending is not active while `true` means lending is active.
     * @param lendingPeriod             Duration for the lending of a token and by default it is 0.
     * @param borrowingPeriod           Duration for the borrowing of a token and by default it is 0.
     * @param lendingPricePerDay        lending price for the token per day and by default it is 0.
     * @param fixedOrAuction            tells the status whether token is listed for fixed price or auction and by default it is `0` which means `none`. `1` means `fixed price` while `2` means `auction`.
     * @param isActivated               tells the status whether the token is active or not and by default it is `false` which means not active while `true` means it is active.
     */
    struct TokenBearer {
        // 256-bits
        address user;
        uint48 startOfLife;
        uint48 endOfLife;
        // 256-bits
        address borrower;
        uint48 lendingStartTimestamp;
        uint48 borrowingStartTimestamp;
        // 256-bits
        uint104 bidStartingPrice;
        uint48 biddingLife;
        uint104 listingPrice;
        // 192-bits
        bool lendingStatus;
        uint32 lendingPeriod;
        uint32 borrowingPeriod;
        uint104 lendingPricePerDay;
        uint8 fixedOrAuction;
        bool isActivated;
    }

    function balanceOf(
        uint256 tokenId,
        address account
    ) external view returns (uint256);

    function balanceOfBatch(
        uint256[] memory tokenIds,
        address[] memory accounts
    ) external view returns (uint256[] memory);

    function ownerOf(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (address);

    function ownerOfBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (address[] memory);

    function mintStatus(uint256 tokenId) external view returns (bool);

    function mintStatusBatch(
        uint256[] memory tokenIds
    ) external view returns (bool[] memory);

    function totalSupply(uint256 tokenId) external view returns (uint256);

    function totalSupplyBatch(
        uint256[] memory tokenIds
    ) external view returns (uint256[] memory);

    function tokenPrice(uint256 tokenId) external view returns (uint200);

    function tokenPriceBatch(
        uint256[] memory tokenIds
    ) external view returns (uint200[] memory);

    function getTokenExpectedUsageLife(
        uint256 tokenId
    ) external view returns (uint32);

    function getTokenExpectedUsageLifeBatch(
        uint256[] memory tokenIds
    ) external view returns (uint32[] memory);

    function getTokenExpiryDate(uint256 tokenId) external view returns (uint48);

    function getTokenExpiryDateBatch(
        uint256[] memory tokenIds
    ) external view returns (uint48[] memory);

    function getTokenBiddingLife(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (uint48);

    function getTokenBiddingLifeBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (uint48[] memory);

    function getStartingPriceForAuction(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (uint256);

    function getStartingPriceForAuctionBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (uint256[] memory);

    function checkStartingPriceForAuction(
        uint256 tokenId,
        uint256 serialNo,
        uint256 biddingLife
    ) external view returns (uint256);

    function checkStartingPriceForAuctionBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos,
        uint256[] memory biddingLives
    ) external view returns (uint256[] memory);

    function getListPriceForFixedPrice(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (uint256);

    function getListPriceForFixedPriceBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (uint256[] memory);

    function checkListPriceForFixedPriceRange(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (ListingPriceTuple memory);

    function checkListPriceForFixedPriceRangesBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (ListingPriceTuple[] memory);

    function getListPriceForLendingPerDay(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (uint256);

    function getListPriceForLendingPerDayBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (uint256[] memory);

    function getListPriceForLendingNDays(
        uint256 tokenId,
        uint256 serialNo,
        uint256 noOfDays
    ) external view returns (uint256);

    function getListPriceForLendingPerNDaysBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos,
        uint256[] memory noOfDays
    ) external view returns (uint256[] memory);

    function checkLendingPrice(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (ListingPriceTuple memory);

    function checkLendingPriceBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (ListingPriceTuple[] memory);

    function isOpenForAuction(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (bool);

    function isOpenForAuctionBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (bool[] memory);

    function isOpenForFixedPrice(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (bool);

    function isOpenForFixedPriceBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (bool[] memory);

    function isOpenLending(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (bool);

    function isOpenLendingBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (bool[] memory);

    function isTokenActivated(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (bool);

    function isTokenActivatedBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (bool[] memory);

    function getTokenStartOfLife(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (uint48);

    function getTokenStartOfLifeBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (uint48[] memory);

    function getTokenEndOfLife(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (uint48);

    function getTokenEndOfLifeBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (uint48[] memory);

    function getPlatformFeesInWei() external view returns (uint256);

    function isTokenActive(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (bool);

    function isTokenActiveBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (bool[] memory);

    function getHighestBid(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (uint256);

    function getHighestBidBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (uint256[] memory);

    function getHighestBidder(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (address);

    function getHighestBidderBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (address[] memory);

    function getYourBid(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (uint256);

    function getYourBidsBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (uint256[] memory);

    function isYourBidHighest(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (bool);

    function isYourBidsHighestsBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (bool[] memory);

    function getUserBid(
        uint256 tokenId,
        uint256 serialNo,
        address user
    ) external view returns (uint256);

    function getUserBidBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos,
        address[] memory users
    ) external view returns (uint256[] memory);

    function getTokenStatus(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (TokenStatus memory);
}