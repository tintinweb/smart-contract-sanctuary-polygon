// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

/**
 * @title IOwnable:
 *
 * @author Farasat Ali
 *
 * @notice This is an interface which will be implemented to provide  contract
 * ownership to the deployer with the facility to transfer ownership.
 */
interface IOwnable {
    /**
     * @notice implement to get the address of the owner.
     *
     * @return owner returns owner of the contract.
     */
    function getOwner() external returns (address owner);

    /**
     * @notice implement to transfer the ownership of the contract.
     *
     * @param newOwner address of the new owner.
     */
    function transferOwnership(address newOwner) external;

    /**
     * @notice implement to give up the ownership of the contract.
     */
    function renounceOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

//interface
import "./interfaces/IOwnable.sol";
// library
import "../utils/NotAvailableForOperationLib.sol";

/**
 * @title Ownable:
 *
 * @author Farasat Ali.
 *
 * @notice this implementation is to make give contract ownership to the
 * deployer with the facility to transfer and revoke ownership.
 */

contract Ownable is IOwnable {
    // ============================================================= //
    //                          VARIABLES                            //
    // ============================================================= //

    // it is the address which is stored when the contract is deployed
    address internal _owner;

    // ============================================================= //
    //                          EVENTS                               //
    // ============================================================= //

    /**
     * @notice emitted when a contract ownership is transferred from an
     * old address to new address.
     *
     * @param oldOwner previous owner of the contract.
     * @param newOwner new owner of the contract.
     * @param when when transfer is happend.
     */
    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner,
        uint256 indexed when
    );

    // ============================================================= //
    //                          MODIFIERS                            //
    // ============================================================= //

    /**
     * @notice to check if the function is being called by owner if `true`
     * then allow the function to continue else raise exception. compares the
     * stored owner address with the address of sender and raise exception if
     * both are not equal contract.
     *
     * Requirements:
     *       ‼ caller should be the owner.
     *
     */
    modifier onlyOwner() {
        if (_owner != msg.sender)
            revert NotAvailableForOperationLib.NotAvailableForOperation(20);
        _;
    }

    /**
     * @notice to check for the address passed. It compares the incoming
     * address (msg.sender) with the 0x0000000000000000000000000000000000000000
     * and if matched then the transaction is reverted with error containing
     * the passed string.
     *
     * Requirements:
     *       ‼ provided address should not be invalid.
     *
     */
    modifier checkForInvalidAddress(address newOwner) {
        if (newOwner == address(0))
            revert NotAvailableForOperationLib.NotAvailableForOperation(21);
        _;
    }

    // ============================================================= //
    //                          CONSTRUCTOR                          //
    // ============================================================= //

    /**
     * @notice calls the _transferOwnership function and sets the
     * deployer (msg.sender) which sets the private variable private
     * owner with the deployer's address.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    // ============================================================= //
    //                          METHODS                              //
    // ============================================================= //

    /**
     * @notice updates or changes the address of old owner within the
     * contract with the incoming address (msg.sender).
     *
     * emit the `OwnershipTransferred` event when successful.
     *
     * @param newOwner address to which ownership of this contract will be transferred.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, _owner, block.timestamp);
    }

    /**
     * @notice returns the address of the owner stored in the private
     * owner variable.
     *
     * @return owner address of owner stored
     */
    function getOwner() external view override returns (address) {
        return _owner;
    }

    /**
     * @notice changes the address of old owner within the contract and
     * with the incoming address (msg.sender) by calling the internal
     * transferOwnership.
     *
     * emit the `OwnershipTransferred` event when successful.
     *
     * Requirements:
     *       ‼ caller of the function should be the current owner.
     *       ‼ the address to which ownership is being transferred should be a valid address or a non-zero address.
     *
     * @param newOwner address to which ownership of this contract will be transferred.
     *
     */
    function transferOwnership(
        address newOwner
    ) external override onlyOwner checkForInvalidAddress(newOwner) {
        _transferOwnership(newOwner);
    }

    /**
     * @notice it lets owner give up their ownership and leave contract without
     * by calling internal _transferOwnership with a 0 address.
     *
     * emit the `OwnershipTransferred` event when successful.
     *
     * Requirements:
     *       ‼ caller of the function should be the current owner of the contract.
     */
    function renounceOwnership() external override onlyOwner {
        _transferOwnership(address(0));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

// interfaces
import "./interfaces/IERC1155DaoProxy.sol";

/**
 * @title ERC1155DaoAbstract
 *
 * @author Farasat Ali
 *
 * @notice This is an abstract contract that will provide functions of ERC1155Dao
 * to be called by proxy contract.
 */

abstract contract ERC1155DaoAbstract is IERC1155DaoProxy {
    /**
     * @notice returns the platformFeesInWei.
     *
     * Signature for getPlatformFeesInWei() : `0xc6e5124d`
     */
    function getPlatformFeesInWei() external view returns (uint256) {}

    /**
     * @notice returns the details of a particular token with `tokenId`.
     *
     * Signature for getTokenDetails(string) : `0xc1e03728`
     *
     * @param tokenId   id of the token.
     */
    function getTokenDetails(
        uint256 tokenId
    ) external view returns (TokenDetails memory) {}

    /**
     * @notice returns the details of a particular token with `tokenId + serialNo`.
     *
     * Signature for getTokenBearer(string,uint256) : `0xd763e522`
     *
     * @param tokenId   id of the token.
     * @param serialNo  serial number of the token.
     */
    function getTokenBearer(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (TokenBearer memory) {}

    /**
     * @notice returns the balance of a user or current contract.
     *
     * Signature for getBalance(string,address) : `0xb0a79459`
     *
     * @param tokenId   id of the token.
     * @param account   address of the user to be queried. Can be a user of current contract.
     */
    function getBalance(
        uint256 tokenId,
        address account
    ) external view returns (uint256) {}

    /**
     * @notice returns the address of the highest bidder for `tokenId + serialNo`.
     *
     * Signature for getHighestBidder(string,uint256) : `0x4b4a39b9`
     *
     * @param tokenId   id of the token.
     * @param serialNo  serial number of the token.
     */
    function getHighestBidder(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (address) {}

    /**
     * @notice returns the bidded amount for `tokenId + serialNo + bidder`.
     *
     * Signature for getOtherBidders(string,uint256,address) : `0xa6c2177b`
     *
     * @param tokenId   id of the token.
     * @param serialNo  serial number of the token.
     * @param bidder    address of the bidder.
     */
    function getOtherBidders(
        uint256 tokenId,
        uint256 serialNo,
        address bidder
    ) external view returns (uint256) {}

    /**
     * @notice returns the metadata id of the token.
     *
     * Signature for getMetadataId(uint256) : `0xa0202a9a`
     *
     * @param tokenId   id of the token.
     */
    function getMetadataId(
        uint256 tokenId
    ) external view returns (string memory) {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

// interface
import "./interfaces/IERC1155DaoProxy.sol";
// abstract contract
import "./ERC1155DaoAbstract.sol";
// contracts
import "../access/Ownable.sol";

/**
 * @title ERC1155DaoProxy:
 *
 * @author Farasat Ali
 *
 * @dev Proxy to the calls of the ERC1155Dao Contract.
 */
contract ERC1155DaoProxy is IERC1155DaoProxy, Ownable {
    // ============================================================= //
    //                          VARIABLES                            //
    // ============================================================= //

    // holds the pointer towards the functions of the  contract being proxied
    ERC1155DaoAbstract private _erc1155dao;

    // holds the address of the  contract being proxied
    address private _erc1155daoproxy;

    // ============================================================= //
    //                          MODIFIERS                            //
    // ============================================================= //

    /// @notice reverts if the lengths of two arguments do not match
    modifier denyIfLengthMismatch(uint256 arg1Length, uint256 arg2Length) {
        if (arg1Length != arg2Length)
            revert ArgsLengthMismatch(arg1Length, arg2Length);
        _;
    }

    // ============================================================= //
    //                          Constructor                          //
    // ============================================================= //

    /**
     * @notice called on contract Initialization and calls the Ownable
     * constructor which sets the owner of the contract and also sets
     * the address of the contract being proxied and a pointer towards the
     * functions of  contract being proxied.
     *
     * @param   erc1155dao address of the contract being proxied.
     */
    constructor(address erc1155dao) Ownable() {
        _erc1155daoproxy = erc1155dao;
        _erc1155dao = ERC1155DaoAbstract(erc1155dao);
    }

    // ============================================================= //
    //                          ERRORS                               //
    // ============================================================= //

    /// @notice only token owner is allowed to perform this operation. Signature : `0xd26ade4d`
    error ArgsLengthMismatch(uint256 arg1, uint256 arg2);

    /// @notice token has reached its expiry. Signature : `0x3c091c33`
    error TokenExpired();

    /// @notice token do not have enough life to perform this operation. Signature : `0x40ee372b`
    error NotEnoughTokenLife();

    // ============================================================= //
    //                          METHODS                              //
    // ============================================================= //

    // Transactions

    /**
     * @notice also sets the address  of the contract being 
     * proxied and a pointer towards the functions
     * of contract being proxied.
     *
     * requirements:
     *      ‼ caller must be the owner of the contract.
     *
     * Signature for setNewProxyAddress(address) : `0x2ba5b083`
     *
     * @param newAddress    address of the contract being proxied.
     */
    function setNewProxyAddress(address newAddress) external onlyOwner {
        _erc1155daoproxy = newAddress;
        _erc1155dao = ERC1155DaoAbstract(newAddress);
    }

    // CALLS

    /**
     * @notice returns the token balance of the user or the contract.
     *
     * Signature for balanceOf(uint256,address) : `0x3656eec2`
     *
     * @param tokenId       id of the token whose balance is to be known.
     * @param account       address of the contract or account.
     *
     * @return balance of the user or token.
     */
    function balanceOf(
        uint256 tokenId,
        address account
    ) public view returns (uint256) {
        return _erc1155dao.getBalance(tokenId, account);
    }

    /**
     * @notice returns the batch token balance of the user or the contract.
     *
     * requirements:
     *      ‼ length of arguments must not mismatch.
     *
     * Signature for balanceOfBatch(uint256[],address[]) : `0xec68692d`
     *
     * @param tokenIds      ids of the token whose balance is to be known.
     * @param accounts      addresses of the contract or account.
     *
     * @return batch balance of the user or contract.
     */
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

    /**
     * @notice returns the address of the owner of the contract.
     *
     * Signature for ownerOf(uint256,uint256) : `0xd9dad80d`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial No of the token.
     *
     * @return owner of the token.
     */
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

    /**
     * @notice returns the batch addresses of the owner of the contract.
     *
     * requirements:
     *      ‼ length of arguments must not mismatch.
     *
     * Signature for ownerOfBatch(uint256[],uint256[]) : `0x588a5022`
     *
     * @param tokenIds      ids of the token.
     * @param serialNos     serial Numbers of the token.
     *
     * @return owners of the token.
     */
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

    /**
     * @notice returns the mint status of the token.
     *
     * Signature for mintStatus(uint256) : `0x3f1cdbdf`
     *
     * @param tokenId       id of the token.
     *
     * @return mint status of the token.
     */
    function mintStatus(uint256 tokenId) public view returns (bool) {
        return _erc1155dao.getTokenDetails(tokenId).isMinted;
    }

    /**
     * @notice returns the mint statuses of the token.
     *
     * Signature for mintStatusBatch(uint256[]) : `0xf4e72d12`
     *
     * @param tokenIds      ids of the token.
     *
     * @return mint statuses of the token.
     */
    function mintStatusBatch(
        uint256[] memory tokenIds
    ) external view returns (bool[] memory) {
        bool[] memory batchMintStatus = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            batchMintStatus[i] = mintStatus(tokenIds[i]);
        }
        return batchMintStatus;
    }

    /**
     * @notice returns the total supply of the token.
     *
     * Signature for totalSupply(uint256) : `0xbd85b039`
     *
     * @param tokenId       id of the token.
     *
     * @return total supply of the token.
     */
    function totalSupply(uint256 tokenId) public view returns (uint256) {
        return _erc1155dao.getTokenDetails(tokenId).totalSupply;
    }

    /**
     * @notice returns the total supply of the tokens.
     *
     * requirements:
     *      ‼ length of arguments must not mismatch.
     *
     * Signature for totalSupplyBatch(uint256[]) : `0x77954ac2`
     *
     * @param tokenIds      ids of the token.
     *
     * @return total supply of the tokens.
     */
    function totalSupplyBatch(
        uint256[] memory tokenIds
    ) external view returns (uint256[] memory) {
        uint256[] memory batchTotalSupply = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            batchTotalSupply[i] = totalSupply(tokenIds[i]);
        }
        return batchTotalSupply;
    }

    /**
     * @notice returns the price of the tokens.
     *
     * Signature for tokenPrice(uint256) : `0xd4ddce8a`
     *
     * @param tokenId       id of the token.
     *
     * @return price of the tokens.
     */
    function tokenPrice(uint256 tokenId) public view returns (uint200) {
        return _erc1155dao.getTokenDetails(tokenId).tokenPrice;
    }

    /**
     * @notice returns the prices of the tokens.
     *
     * requirements:
     *      ‼ length of arguments must not mismatch.
     *
     * Signature for tokenPriceBatch(uint256[]) : `0x6f027a18`
     *
     * @param tokenIds      ids of the token.
     *
     * @return prices of the tokens.
     */
    function tokenPriceBatch(
        uint256[] memory tokenIds
    ) external view returns (uint200[] memory) {
        uint200[] memory batchTokenPrice = new uint200[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            batchTokenPrice[i] = tokenPrice(tokenIds[i]);
        }
        return batchTokenPrice;
    }

    /**
     * @notice returns the expected usage life of the tokens.
     *
     * Signature for getTokenExpectedUsageLife(uint256) : `0x6b52bb98`
     *
     * @param tokenId     id of the token.
     *
     * @return expected usage life of the tokens.
     */
    function getTokenExpectedUsageLife(
        uint256 tokenId
    ) public view returns (uint32) {
        return _erc1155dao.getTokenDetails(tokenId).expectedUsageLife;
    }

    /**
     * @notice returns the expected usage lives of the tokens.
     *
     * requirements:
     *      ‼ length of arguments must not mismatch.
     *
     * Signature for getTokenExpectedUsageLifeBatch(uint256[]) : `0x019f2d11`
     *
     * @param tokenIds    ids of the token.
     *
     * @return expected usage lives of the tokens.
     */
    function getTokenExpectedUsageLifeBatch(
        uint256[] memory tokenIds
    ) external view returns (uint32[] memory) {
        uint32[] memory batchTokenEUL = new uint32[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            batchTokenEUL[i] = getTokenExpectedUsageLife(tokenIds[i]);
        }
        return batchTokenEUL;
    }

    /**
     * @notice returns the expiry date of the tokens.
     *
     * Signature for getTokenExpiryDate(uint256) : `0x826321d7`
     *
     * @param tokenId       id of the token.
     *
     * @return expiry date of the tokens.
     */
    function getTokenExpiryDate(uint256 tokenId) public view returns (uint48) {
        return _erc1155dao.getTokenDetails(tokenId).expireOn;
    }

    /**
     * @notice returns the expiry dates of the tokens.
     *
     * requirements:
     *      ‼ length of arguments must not mismatch.
     *
     * Signature for getTokenExpiryDateBatch(uint256[]) : `0x59136e93`
     *
     * @param tokenIds     ids of the token.
     *
     * @return expiry dates of the tokens.
     */
    function getTokenExpiryDateBatch(
        uint256[] memory tokenIds
    ) external view returns (uint48[] memory) {
        uint48[] memory batchTokenED = new uint48[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            batchTokenED[i] = getTokenExpiryDate(tokenIds[i]);
        }
        return batchTokenED;
    }

    /**
     * @notice returns the bidding life of the tokens.
     *
     * Signature for getTokenBiddingLife(uint256,uint256) : `0x0173d90e`
     *
     * @param tokenId      id of the token.
     * @param serialNo     serial Number of the token.
     *
     * @return bidding life of the tokens.
     */
    function getTokenBiddingLife(
        uint256 tokenId,
        uint256 serialNo
    ) public view returns (uint48) {
        return _erc1155dao.getTokenBearer(tokenId, serialNo).biddingLife;
    }

    /**
     * @notice returns the bidding lives of the tokens.
     *
     * requirements:
     *      ‼ length of arguments must not mismatch.
     *
     * Signature for getTokenBiddingLifeBatch(uint256[],uint256[]) : `0x9fea3b59`
     *
     * @param tokenIds     ids of the token.
     * @param serialNos    serial Numbers of the token.
     *
     * @return bidding lives of the tokens.
     */
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

    /**
     * @notice returns the starting auction price of the tokens.
     *
     * Signature for getStartingPriceForAuction(uint256,uint256) : `0xd28a9995`
     *
     * @param tokenId      id of the token.
     * @param serialNo     serial Number of the token.
     *
     * @return starting auction price of the tokens.
     */
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

    /**
     * @notice returns the starting auction prices of the tokens.
     *
     * requirements:
     *      ‼ length of arguments must not mismatch.
     *
     * Signature for getStartingPriceForAuctionBatch(uint256[],uint256[]) : `0x8aae0a6a`
     *
     * @param tokenIds      ids of the token.
     * @param serialNos     serial Numbers of the token.
     *
     * @return starting auction prices of the tokens.
     */
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

    /**
     * @notice calculates and returns the starting auction price of the tokens.
     *
     * requirements:
     *      ‼ token must not be expired.
     *      ‼ token life must be enough.
     *
     * Signature for checkStartingPriceForAuction(uint256,uint256,uint256) : `0xe40a5f35`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     * @param biddingLife   bidding time for the token.
     *
     * @return starting auction price of the tokens.
     */
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

        if (tokenOwner.startOfLife == 0 && block.timestamp > tokenDet.expireOn)
            revert TokenExpired();
        if (
            tokenOwner.startOfLife != 0 &&
            block.timestamp + biddingLife > tokenOwner.endOfLife
        ) revert NotEnoughTokenLife();

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

    /**
     * @notice calculates and returns the starting auction prices of the tokens.
     *
     * requirements:
     *      ‼ length of arguments must not mismatch.
     *      ‼ token must not be expired.
     *      ‼ token life must be enough.
     *
     * Signature for checkStartingPriceForAuctionBatch(uint256[],uint256[],uint256[]) : `0x6079d216`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     * @param biddingLives   bidding times for the token.
     *
     * @return starting auction prices of the tokens.
     */
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

    /**
     * @notice returns the fixed price of the tokens.
     *
     * Signature for getListPriceForFixedPriceBatch(uint256,uint256) : `0x1f634eaf`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     *
     * @return fixed price of the tokens.
     */
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

    /**
     * @notice returns the fixed prices of the tokens.
     *
     * requirements:
     *      ‼ length of arguments must not mismatch.
     *
     * Signature for getListPriceForFixedPriceBatch(uint256[],uint256[]) : `0x043089de`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     *
     * @return fixed prices of the tokens.
     */
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

    /**
     * @notice calculate and returns the fixed price of the tokens.
     *
     * requirements:
     *      ‼ token must not be expired.
     *      ‼ token life must be enough.
     *
     * Signature for checkListPriceForFixedPriceRange(uint256,uint256) : `0xb690eade`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     *
     * @return fixed price of the tokens.
     */
    function checkListPriceForFixedPriceRange(
        uint256 tokenId,
        uint256 serialNo
    ) public view returns (ListingPriceTuple memory) {
        TokenBearer memory tokenOwner = _erc1155dao.getTokenBearer(
            tokenId,
            serialNo
        );
        TokenDetails memory tokenDet = _erc1155dao.getTokenDetails(tokenId);

        if (tokenOwner.startOfLife == 0 && block.timestamp > tokenDet.expireOn)
            revert TokenExpired();
        if (
            tokenOwner.startOfLife != 0 &&
            block.timestamp > tokenOwner.endOfLife
        ) revert NotEnoughTokenLife();

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

    /**
     * @notice calculate and returns the fixed prices of the tokens.
     *
     * requirements:
     *      ‼ length of arguments must not mismatch.
     *      ‼ token must not be expired.
     *      ‼ token life must be enough.
     *
     * Signature for checkListPriceForFixedPriceRangeBatch(uint256[],uint256[]) : `0x910eff3f`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     *
     * @return fixed prices of the tokens.
     */
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

    /**
     * @notice returns the lending price per day of the tokens.
     *
     * Signature for getListPriceForLendingPerDay(uint256,uint256) : `0x8ddd08fd`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     *
     * @return lending price per day of the tokens.
     */
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

    /**
     * @notice returns the lending prices per day of the tokens.
     *
     * requirements:
     *      ‼ length of arguments must not mismatch.
     *
     * Signature for getListPriceForLendingPerDayBatch(uint256[],uint256[]) : `0x16054276`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     *
     * @return lending prices per day of the tokens.
     */
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

    /**
     * @notice returns the lending prices per N day of the tokens.
     *
     * Signature for getListPriceForLendingNDays(uint256,uint256,uint256) : `0x8592deae`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     *
     * @return lending prices per N day of the tokens.
     */
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

    /**
     * @notice returns the lending prices per N day of the tokens.
     *
     * requirements:
     *      ‼ length of arguments must not mismatch.
     *
     * Signature for getListPriceForLendingNDaysBatch(uint256[],uint256[],uint256[]) : `0x19d1ee7a`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     *
     * @return lending prices per N day of the tokens.
     */
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

    /**
     * @notice calculate and returns the lending price range of the tokens.
     *
     * requirements:
     *      ‼ token must not be expired.
     *      ‼ token life must be enough.
     *
     * Signature for checkLendingPrice(uint256,uint256) : `0x8f70d5e8`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     *
     * @return lending price range of the tokens.
     */
    function checkLendingPrice(
        uint256 tokenId,
        uint256 serialNo
    ) public view returns (ListingPriceTuple memory) {
        TokenBearer memory tokenOwner = _erc1155dao.getTokenBearer(
            tokenId,
            serialNo
        );
        TokenDetails memory tokenDet = _erc1155dao.getTokenDetails(tokenId);

        if (tokenOwner.startOfLife == 0 && block.timestamp > tokenDet.expireOn)
            revert TokenExpired();
        if (
            tokenOwner.startOfLife != 0 &&
            block.timestamp > tokenOwner.endOfLife
        ) revert NotEnoughTokenLife();

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

    /**
     * @notice calculate and returns the lending price ranges of the tokens.
     *
     * requirements:
     *      ‼ length of arguments must not mismatch.
     *      ‼ token must not be expired.
     *      ‼ token life must be enough.
     *
     * Signature for checkLendingPriceBatch(uint256[],uint256[]) : `0x9f030647`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     *
     * @return lending price ranges of the tokens.
     */
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

    /**
     * @notice returns the auction status of the tokens.
     *
     * Signature for isOpenForAuction(uint256,uint256) : `0x94f232a9`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     *
     * @return auction status of the tokens.
     */
    function isOpenForAuction(
        uint256 tokenId,
        uint256 serialNo
    ) public view returns (bool) {
        return
            _erc1155dao.getTokenBearer(tokenId, serialNo).fixedOrAuction == 2;
    }

    /**
     * @notice returns the auction status of the tokens.
     *
     * requirements:
     *      ‼ length of arguments must not mismatch.
     *
     * Signature for isOpenForAuctionBatch(uint256[],uint256[]) : `0x9289959f`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     *
     * @return auction status of the tokens.
     */
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

    /**
     * @notice returns the fixed price status of the tokens.
     *
     * Signature for isOpenForFixedPrice(uint256,uint256) : `0x0ad0b958`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     *
     * @return fixed price status of the tokens.
     */
    function isOpenForFixedPrice(
        uint256 tokenId,
        uint256 serialNo
    ) public view returns (bool) {
        return
            _erc1155dao.getTokenBearer(tokenId, serialNo).fixedOrAuction == 1;
    }

    /**
     * @notice returns the fixed price status of the tokens.
     *
     * requirements:
     *      ‼ length of arguments must not mismatch.
     *
     * Signature for isOpenForFixedPriceBatch(uint256[],uint256[]) : `0x002e9e61`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     *
     * @return fixed price status of the tokens.
     */
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

    /**
     * @notice returns the lending status of the tokens.
     *
     * Signature for isOpenLending(uint256,uint256) : `0xeec7450e`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     *
     * @return lending status of the tokens.
     */
    function isOpenLending(
        uint256 tokenId,
        uint256 serialNo
    ) public view returns (bool) {
        return _erc1155dao.getTokenBearer(tokenId, serialNo).lendingStatus;
    }

    /**
     * @notice returns the lending status of the tokens.
     *
     * requirements:
     *      ‼ length of arguments must not mismatch.
     *
     * Signature for isOpenLendingBatch(uint256[],uint256[]) : `0x52282c74`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     *
     * @return lending status of the tokens.
     */
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

    /**
     * @notice returns the activation status of the tokens.
     *
     * Signature for isTokenActivated(uint256,uint256) : `0x446b50ef`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     *
     * @return activation status of the tokens.
     */
    function isTokenActivated(
        uint256 tokenId,
        uint256 serialNo
    ) public view returns (bool) {
        return _erc1155dao.getTokenBearer(tokenId, serialNo).isActivated;
    }

    /**
     * @notice returns the activation status of the tokens.
     *
     * requirements:
     *      ‼ length of arguments must not mismatch.
     *
     * Signature for isTokenActivatedBatch(uint256[],uint256[]) : `0xb032203a`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     *
     * @return activation status of the tokens.
     */
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

    /**
     * @notice returns the start of life of the tokens.
     *
     * Signature for getTokenStartOfLife(uint256,uint256) : `0xc1da63d3`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     *
     * @return start of life of the tokens.
     */
    function getTokenStartOfLife(
        uint256 tokenId,
        uint256 serialNo
    ) public view returns (uint48) {
        return _erc1155dao.getTokenBearer(tokenId, serialNo).startOfLife;
    }

    /**
     * @notice returns the start of life of the tokens.
     *
     * requirements:
     *      ‼ length of arguments must not mismatch.
     *
     * Signature for getTokenStartOfLifeBatch(uint256[],uint256[]) : `0xe30bea5c`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     *
     * @return start of life of the tokens.
     */
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

    /**
     * @notice returns the end of life of the tokens.
     *
     * Signature for getTokenEndOfLife(uint256,uint256) : `0x7da2f962`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Numbers of the token.
     *
     * @return end of life of the tokens.
     */
    function getTokenEndOfLife(
        uint256 tokenId,
        uint256 serialNo
    ) public view returns (uint48) {
        return _erc1155dao.getTokenBearer(tokenId, serialNo).endOfLife;
    }

    /**
     * @notice returns the end of life of the tokens.
     *
     * requirements:
     *      ‼ length of arguments must not mismatch.
     *
     * Signature for getTokenEndOfLifeBatch(uint256[],uint256[]) : `0x1802d999`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     *
     * @return end of life of the tokens.
     */
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

    /**
     * @notice returns the platform fees in wei.
     *
     * Signature for getPlatformFeesInWei() : `0xc6e5124d`
     *
     * @return platform fees in wei.
     */
    function getPlatformFeesInWei() external view returns (uint256) {
        return _erc1155dao.getPlatformFeesInWei();
    }

    /**
     * @notice returns the highest bid on the tokens.
     *
     * Signature for getHighestBid(uint256,uint256) : `0x1802d999`
     *
     * @param tokenId      idof the token.
     * @param serialNo     serial Numberof the token.
     *
     * @return highest bid on the tokens.
     */
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

    /**
     * @notice returns the highest bid on the tokens.
     *
     * requirements:
     *      ‼ length of arguments must not mismatch.
     *
     * Signature for getHighestBidBatch(uint256[],uint256[]) : `0xf6067ad2`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     *
     * @return highest bid on the tokens.
     */
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

    /**
     * @notice returns the address of highest bidder on the tokens.
     *
     * Signature for getHighestBidder(uint256,uint256) : `0x4b4a39b9`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     *
     * @return address of highest bidder on the tokens.
     */
    function getHighestBidder(
        uint256 tokenId,
        uint256 serialNo
    ) public view returns (address) {
        return _erc1155dao.getHighestBidder(tokenId, serialNo);
    }

    /**
     * @notice returns the address of highest bidder on the tokens.
     *
     * requirements:
     *      ‼ length of arguments must not mismatch.
     *
     * Signature for getHighestBidderBatch(uint256[],uint256[]) : `0xd8f10a9e`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     *
     * @return address of highest bidder on the tokens.
     */
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

    /**
     * @notice returns the bid of the given bidder on the tokens.
     *
     * Signature for getYourBid(uint256,uint256) : `0x629b3d8e`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     *
     * @return bid of the given bidder on the tokens.
     */
    function getYourBid(
        uint256 tokenId,
        uint256 serialNo
    ) public view returns (uint256) {
        return _erc1155dao.getOtherBidders(tokenId, serialNo, msg.sender);
    }

    /**
     * @notice returns the bid of the given bidder on the tokens.
     *
     * requirements:
     *      ‼ length of arguments must not mismatch.
     *
     * Signature for getYourBidBatch(uint256[],uint256[]) : `0x5928801c`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     *
     * @return bid of the given bidder on the tokens.
     */
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

    /**
     * @notice returns the whether you have highest bid or not on the tokens.
     *
     * Signature for isYourBidHighest(uint256,uint256) : `0xf3de95a0`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     *
     * @return whether you have highest bid or not on the tokens.
     */
    function isYourBidHighest(
        uint256 tokenId,
        uint256 serialNo
    ) public view returns (bool) {
        return msg.sender == _erc1155dao.getHighestBidder(tokenId, serialNo);
    }

    /**
     * @notice returns the whether you have highest bid or not on the tokens.
     *
     * requirements:
     *      ‼ length of arguments must not mismatch.
     *
     * Signature for isYourBidHighestBatch(uint256[],uint256[]) : `0x350afaf0`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     *
     * @return whether you have highest bid or not on the tokens.
     */
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

    /**
     * @notice returns the bid of a user on the tokens.
     *
     * Signature for getUserBid(uint256,uint256,uint256) : `0x865a495a`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     * @param user          address of the user
     *
     * @return bid of a user on the tokens.
     */
    function getUserBid(
        uint256 tokenId,
        uint256 serialNo,
        address user
    ) public view returns (uint256) {
        return _erc1155dao.getOtherBidders(tokenId, serialNo, user);
    }

    /**
     * @notice returns the bid of a user on the tokens.
     *
     * requirements:
     *      ‼ length of arguments must not mismatch.
     *
     * Signature for getUserBidBatch(uint256[],uint256[],uint256[]) : `0x89f09ffa`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     * @param users          address of the user
     *
     * @return bid of a user on the tokens.
     */
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

    /**
     * @notice returns the metadata id of the tokens.
     *
     * Signature for getTokenMetadatId(uint256[]) : `0x09d049f8`
     *
     * @param tokenId       id of the token.
     *
     * @return metadata id of the tokens.
     */
    function getTokenMetadatId(
        uint256 tokenId
    ) public view returns (string memory) {
        return _erc1155dao.getMetadataId(tokenId);
    }

    /**
     * @notice returns the metadata id of the tokens.
     *
     * Signature for getTokenMetadatId(uint256[]) : `0xd9891552`
     *
     * @param tokenIds       ids of the token.
     *
     * @return metadata id of the tokens.
     */
    function getTokenMetadatIdBatch(
        uint256[] memory tokenIds
    ) external view returns (string[] memory) {
        string[] memory metadatUri = new string[](tokenIds.length);

        for (uint i = 0; i < tokenIds.length; ++i) {
            metadatUri[i] = getTokenMetadatId(tokenIds[i]);
        }

        return metadatUri;
    }

    /**
     * @notice returns the working status of the tokens.
     *
     * Signature for getTokenStatus(uint256,uint256) : `0x92cdbdf1`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     *
     * @return working status of the tokens.
     */
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

    /**
     * @notice gets the addressof the contract being proxied
     *
     * Signature for getProxyAddress() : `0x43a73d9a`
     */
    function getProxyAddress() external view returns (address) {
        return _erc1155daoproxy;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

/**
 * @title IERC1155DaoProxy:
 *
 * @author Farasat Ali
 *
 * @dev Interface Proxy to the calls of the ERC1155Dao Contract.
 */

interface IERC1155DaoProxy {
    /**
     * @notice Struct to return the min max prices in the functions.
     *
     * @param min   Min price in the function. It will be a number less than max.
     * @param max   Max price in the function. It will be a number greater than min.
     */
    struct ListingPriceTuple {
        uint256 min;
        uint256 max;
    }

    /**
     * @notice Struct to return the status of the token in the functions.
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

    /**
     * @notice sets the owner of the contract and also sets the address
     * of the contract being proxied and a pointer towards the functions
     * of  contract being proxied.
     *
     * Signature for setNewProxyAddress(address) : `0x2ba5b083`
     *
     * @param newAddress    address of the contract being proxied.
     */
    function setNewProxyAddress(address newAddress) external;

    /**
     * @notice returns the token balance of the user or the contract.
     *
     * Signature for balanceOf(uint256,address) : `0x3656eec2`
     *
     * @param tokenId       id of the token whose balance is to be known.
     * @param account       address of the contract or account.
     *
     * @return balance of the user or token.
     */
    function balanceOf(
        uint256 tokenId,
        address account
    ) external view returns (uint256);

    /**
     * @notice returns the batch token balance of the user or the contract.
     *
     * Signature for balanceOfBatch(uint256[],address[]) : `0xec68692d`
     *
     * @param tokenIds      ids of the token whose balance is to be known.
     * @param accounts      addresses of the contract or account.
     *
     * @return batch balance of the user or contract.
     */
    function balanceOfBatch(
        uint256[] memory tokenIds,
        address[] memory accounts
    ) external view returns (uint256[] memory);

    /**
     * @notice returns the address of the owner of the contract.
     *
     * Signature for ownerOf(uint256,uint256) : `0xd9dad80d`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial No of the token.
     *
     * @return owner of the token.
     */
    function ownerOf(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (address);

    /**
     * @notice returns the batch addresses of the owner of the contract.
     *
     * Signature for ownerOfBatch(uint256[],uint256[]) : `0x588a5022`
     *
     * @param tokenIds      ids of the token.
     * @param serialNos     serial Numbers of the token.
     *
     * @return owners of the token.
     */
    function ownerOfBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (address[] memory);

    /**
     * @notice returns the mint status of the token.
     *
     * Signature for mintStatus(uint256) : `0x3f1cdbdf`
     *
     * @param tokenId       id of the token.
     *
     * @return mint status of the token.
     */
    function mintStatus(uint256 tokenId) external view returns (bool);

    /**
     * @notice returns the mint statuses of the token.
     *
     * Signature for mintStatusBatch(uint256[]) : `0xf4e72d12`
     *
     * @param tokenIds      ids of the token.
     *
     * @return mint statuses of the token.
     */
    function mintStatusBatch(
        uint256[] memory tokenIds
    ) external view returns (bool[] memory);

    /**
     * @notice returns the total supply of the token.
     *
     * Signature for totalSupply(uint256) : `0xbd85b039`
     *
     * @param tokenId       id of the token.
     *
     * @return total supply of the token.
     */
    function totalSupply(uint256 tokenId) external view returns (uint256);

    /**
     * @notice returns the total supply of the tokens.
     *
     * Signature for totalSupplyBatch(uint256[]) : `0x77954ac2`
     *
     * @param tokenIds      ids of the token.
     *
     * @return total supply of the tokens.
     */
    function totalSupplyBatch(
        uint256[] memory tokenIds
    ) external view returns (uint256[] memory);

    /**
     * @notice returns the price of the tokens.
     *
     * Signature for tokenPrice(uint256) : `0xd4ddce8a`
     *
     * @param tokenId       id of the token.
     *
     * @return price of the tokens.
     */
    function tokenPrice(uint256 tokenId) external view returns (uint200);

    /**
     * @notice returns the prices of the tokens.
     *
     * Signature for tokenPriceBatch(uint256[]) : `0x6f027a18`
     *
     * @param tokenIds      ids of the token.
     *
     * @return prices of the tokens.
     */
    function tokenPriceBatch(
        uint256[] memory tokenIds
    ) external view returns (uint200[] memory);

    /**
     * @notice returns the expected usage life of the tokens.
     *
     * Signature for getTokenExpectedUsageLife(uint256) : `0x6b52bb98`
     *
     * @param tokenId     id of the token.
     *
     * @return expected usage life of the tokens.
     */
    function getTokenExpectedUsageLife(
        uint256 tokenId
    ) external view returns (uint32);

    /**
     * @notice returns the expected usage lives of the tokens.
     *
     * Signature for getTokenExpectedUsageLifeBatch(uint256[]) : `0x019f2d11`
     *
     * @param tokenIds    ids of the token.
     *
     * @return expected usage lives of the tokens.
     */
    function getTokenExpectedUsageLifeBatch(
        uint256[] memory tokenIds
    ) external view returns (uint32[] memory);

    /**
     * @notice returns the expiry date of the tokens.
     *
     * Signature for getTokenExpiryDate(uint256) : `0x826321d7`
     *
     * @param tokenId       id of the token.
     *
     * @return expiry date of the tokens.
     */
    function getTokenExpiryDate(uint256 tokenId) external view returns (uint48);

    /**
     * @notice returns the expiry dates of the tokens.
     *
     * Signature for getTokenExpiryDateBatch(uint256[]) : `0x59136e93`
     *
     * @param tokenIds     ids of the token.
     *
     * @return expiry dates of the tokens.
     */
    function getTokenExpiryDateBatch(
        uint256[] memory tokenIds
    ) external view returns (uint48[] memory);

    /**
     * @notice returns the bidding life of the tokens.
     *
     * Signature for getTokenBiddingLife(uint256,uint256) : `0x0173d90e`
     *
     * @param tokenId      id of the token.
     * @param serialNo     serial Number of the token.
     *
     * @return bidding life of the tokens.
     */
    function getTokenBiddingLife(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (uint48);

    /**
     * @notice returns the bidding lives of the tokens.
     *
     * Signature for getTokenBiddingLifeBatch(uint256[],uint256[]) : `0x9fea3b59`
     *
     * @param tokenIds     ids of the token.
     * @param serialNos    serial Numbers of the token.
     *
     * @return bidding lives of the tokens.
     */
    function getTokenBiddingLifeBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (uint48[] memory);

    /**
     * @notice returns the starting auction price of the tokens.
     *
     * Signature for getStartingPriceForAuction(uint256,uint256) : `0xd28a9995`
     *
     * @param tokenId      id of the token.
     * @param serialNo     serial Number of the token.
     *
     * @return starting auction price of the tokens.
     */
    function getStartingPriceForAuction(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (uint256);

    /**
     * @notice returns the starting auction prices of the tokens.
     *
     * Signature for getStartingPriceForAuctionBatch(uint256[],uint256[]) : `0x8aae0a6a`
     *
     * @param tokenIds      ids of the token.
     * @param serialNos     serial Numbers of the token.
     *
     * @return starting auction prices of the tokens.
     */
    function getStartingPriceForAuctionBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (uint256[] memory);

    /**
     * @notice calculates and returns the starting auction price of the tokens.
     *
     * Signature for checkStartingPriceForAuction(uint256,uint256,uint256) : `0xe40a5f35`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     * @param biddingLife   bidding time for the token.
     *
     * @return starting auction price of the tokens.
     */
    function checkStartingPriceForAuction(
        uint256 tokenId,
        uint256 serialNo,
        uint256 biddingLife
    ) external view returns (uint256);

    /**
     * @notice calculates and returns the starting auction prices of the tokens.
     *
     * Signature for checkStartingPriceForAuctionBatch(uint256[],uint256[],uint256[]) : `0x6079d216`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     * @param biddingLives   bidding times for the token.
     *
     * @return starting auction prices of the tokens.
     */
    function checkStartingPriceForAuctionBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos,
        uint256[] memory biddingLives
    ) external view returns (uint256[] memory);

    /**
     * @notice returns the fixed price of the tokens.
     *
     * Signature for getListPriceForFixedPriceBatch(uint256,uint256) : `0x1f634eaf`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     *
     * @return fixed price of the tokens.
     */
    function getListPriceForFixedPrice(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (uint256);

    /**
     * @notice returns the fixed prices of the tokens.
     *
     * Signature for getListPriceForFixedPriceBatch(uint256[],uint256[]) : `0x043089de`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     *
     * @return fixed prices of the tokens.
     */
    function getListPriceForFixedPriceBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (uint256[] memory);

    /**
     * @notice calculate and returns the fixed price of the tokens.
     *
     * Signature for checkListPriceForFixedPriceRange(uint256,uint256) : `0xb690eade`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     *
     * @return fixed price of the tokens.
     */
    function checkListPriceForFixedPriceRange(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (ListingPriceTuple memory);

    /**
     * @notice calculate and returns the fixed prices of the tokens.
     *
     * Signature for checkListPriceForFixedPriceRangeBatch(uint256[],uint256[]) : `0x910eff3f`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     *
     * @return fixed prices of the tokens.
     */
    function checkListPriceForFixedPriceRangesBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (ListingPriceTuple[] memory);

    /**
     * @notice returns the lending price per day of the tokens.
     *
     * Signature for getListPriceForLendingPerDay(uint256,uint256) : `0x8ddd08fd`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     *
     * @return lending price per day of the tokens.
     */
    function getListPriceForLendingPerDay(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (uint256);

    /**
     * @notice returns the lending prices per day of the tokens.
     *
     * Signature for getListPriceForLendingPerDayBatch(uint256[],uint256[]) : `0x16054276`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     *
     * @return lending prices per day of the tokens.
     */
    function getListPriceForLendingPerDayBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (uint256[] memory);

    /**
     * @notice returns the lending prices per N day of the tokens.
     *
     * Signature for getListPriceForLendingNDays(uint256,uint256,uint256) : `0x8592deae`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     *
     * @return lending prices per N day of the tokens.
     */
    function getListPriceForLendingNDays(
        uint256 tokenId,
        uint256 serialNo,
        uint256 noOfDays
    ) external view returns (uint256);

    /**
     * @notice returns the lending prices per N day of the tokens.
     *
     * Signature for getListPriceForLendingNDaysBatch(uint256[],uint256[],uint256[]) : `0x19d1ee7a`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     *
     * @return lending prices per N day of the tokens.
     */
    function getListPriceForLendingPerNDaysBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos,
        uint256[] memory noOfDays
    ) external view returns (uint256[] memory);

    /**
     * @notice calculate and returns the lending price range of the tokens.
     *
     * Signature for checkLendingPrice(uint256,uint256) : `0x8f70d5e8`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     *
     * @return lending price range of the tokens.
     */
    function checkLendingPrice(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (ListingPriceTuple memory);

    /**
     * @notice calculate and returns the lending price ranges of the tokens.
     *
     * Signature for checkLendingPriceBatch(uint256[],uint256[]) : `0x9f030647`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     *
     * @return lending price ranges of the tokens.
     */
    function checkLendingPriceBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (ListingPriceTuple[] memory);

    /**
     * @notice returns the auction status of the tokens.
     *
     * Signature for isOpenForAuction(uint256,uint256) : `0x94f232a9`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     *
     * @return auction status of the tokens.
     */
    function isOpenForAuction(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (bool);

    /**
     * @notice returns the auction status of the tokens.
     *
     * Signature for isOpenForAuctionBatch(uint256[],uint256[]) : `0x9289959f`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     *
     * @return auction status of the tokens.
     */
    function isOpenForAuctionBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (bool[] memory);

    /**
     * @notice returns the fixed price status of the tokens.
     *
     * Signature for isOpenForFixedPrice(uint256,uint256) : `0x0ad0b958`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     *
     * @return fixed price status of the tokens.
     */
    function isOpenForFixedPrice(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (bool);

    /**
     * @notice returns the fixed price status of the tokens.
     *
     * Signature for isOpenForFixedPriceBatch(uint256[],uint256[]) : `0x002e9e61`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     *
     * @return fixed price status of the tokens.
     */
    function isOpenForFixedPriceBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (bool[] memory);

    /**
     * @notice returns the lending status of the tokens.
     *
     * Signature for isOpenLending(uint256,uint256) : `0xeec7450e`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     *
     * @return lending status of the tokens.
     */
    function isOpenLending(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (bool);

    /**
     * @notice returns the lending status of the tokens.
     *
     * Signature for isOpenLendingBatch(uint256[],uint256[]) : `0x52282c74`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     *
     * @return lending status of the tokens.
     */
    function isOpenLendingBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (bool[] memory);

    /**
     * @notice returns the activation status of the tokens.
     *
     * Signature for isTokenActivated(uint256,uint256) : `0x446b50ef`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     *
     * @return activation status of the tokens.
     */
    function isTokenActivated(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (bool);

    /**
     * @notice returns the activation status of the tokens.
     *
     * Signature for isTokenActivatedBatch(uint256[],uint256[]) : `0xb032203a`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     *
     * @return activation status of the tokens.
     */
    function isTokenActivatedBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (bool[] memory);

    /**
     * @notice returns the start of life of the tokens.
     *
     * Signature for getTokenStartOfLife(uint256,uint256) : `0xc1da63d3`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     *
     * @return start of life of the tokens.
     */
    function getTokenStartOfLife(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (uint48);

    /**
     * @notice returns the start of life of the tokens.
     *
     * Signature for getTokenStartOfLifeBatch(uint256[],uint256[]) : `0xe30bea5c`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     *
     * @return start of life of the tokens.
     */
    function getTokenStartOfLifeBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (uint48[] memory);

    /**
     * @notice returns the end of life of the tokens.
     *
     * Signature for getTokenEndOfLife(uint256,uint256) : `0x7da2f962`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Numbers of the token.
     *
     * @return end of life of the tokens.
     */
    function getTokenEndOfLife(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (uint48);

    /**
     * @notice returns the end of life of the tokens.
     *
     * Signature for getTokenEndOfLifeBatch(uint256[],uint256[]) : `0x1802d999`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     *
     * @return end of life of the tokens.
     */
    function getTokenEndOfLifeBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (uint48[] memory);

    /**
     * @notice returns the platform fees in wei.
     *
     * Signature for getPlatformFeesInWei() : `0xc6e5124d`
     *
     * @return platform fees in wei.
     */
    function getPlatformFeesInWei() external view returns (uint256);

    /**
     * @notice returns the highest bid on the tokens.
     *
     * Signature for getHighestBid(uint256,uint256) : `0x1802d999`
     *
     * @param tokenId      idof the token.
     * @param serialNo     serial Numberof the token.
     *
     * @return highest bid on the tokens.
     */
    function getHighestBid(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (uint256);

    /**
     * @notice returns the highest bid on the tokens.
     *
     * Signature for getHighestBidBatch(uint256[],uint256[]) : `0xf6067ad2`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     *
     * @return highest bid on the tokens.
     */
    function getHighestBidBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (uint256[] memory);

    /**
     * @notice returns the address of highest bidder on the tokens.
     *
     * Signature for getHighestBidder(uint256,uint256) : `0x4b4a39b9`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     *
     * @return address of highest bidder on the tokens.
     */
    function getHighestBidder(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (address);

    /**
     * @notice returns the address of highest bidder on the tokens.
     *
     * Signature for getHighestBidderBatch(uint256[],uint256[]) : `0xd8f10a9e`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     *
     * @return address of highest bidder on the tokens.
     */
    function getHighestBidderBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (address[] memory);

    /**
     * @notice returns the bid of the given bidder on the tokens.
     *
     * Signature for getYourBid(uint256,uint256) : `0x629b3d8e`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     *
     * @return bid of the given bidder on the tokens.
     */
    function getYourBid(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (uint256);

    /**
     * @notice returns the bid of the given bidder on the tokens.
     *
     * Signature for getYourBidBatch(uint256[],uint256[]) : `0x5928801c`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     *
     * @return bid of the given bidder on the tokens.
     */
    function getYourBidsBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (uint256[] memory);

    /**
     * @notice returns the whether you have highest bid or not on the tokens.
     *
     * Signature for isYourBidHighest(uint256,uint256) : `0xf3de95a0`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     *
     * @return whether you have highest bid or not on the tokens.
     */
    function isYourBidHighest(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (bool);

    /**
     * @notice returns the whether you have highest bid or not on the tokens.
     *
     * Signature for isYourBidHighestBatch(uint256[],uint256[]) : `0x350afaf0`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     *
     * @return whether you have highest bid or not on the tokens.
     */
    function isYourBidsHighestsBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos
    ) external view returns (bool[] memory);

    /**
     * @notice returns the bid of a user on the tokens.
     *
     * Signature for getUserBid(uint256,uint256,uint256) : `0x865a495a`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     * @param user          address of the user
     *
     * @return bid of a user on the tokens.
     */
    function getUserBid(
        uint256 tokenId,
        uint256 serialNo,
        address user
    ) external view returns (uint256);

    /**
     * @notice returns the bid of a user on the tokens.
     *
     * Signature for getUserBidBatch(uint256[],uint256[],uint256[]) : `0x89f09ffa`
     *
     * @param tokenIds       ids of the token.
     * @param serialNos      serial Numbers of the token.
     * @param users          address of the user
     *
     * @return bid of a user on the tokens.
     */
    function getUserBidBatch(
        uint256[] memory tokenIds,
        uint256[] memory serialNos,
        address[] memory users
    ) external view returns (uint256[] memory);

    /**
     * @notice returns the metadata id of the tokens.
     *
     * Signature for getTokenMetadatId(uint256[]) : `0x09d049f8`
     *
     * @param tokenId       id of the token.
     *
     * @return metadata id of the tokens.
     */
    function getTokenMetadatId(
        uint256 tokenId
    ) external view returns (string memory);

    /**
     * @notice returns the metadata id of the tokens.
     *
     * Signature for getTokenMetadatId(uint256[]) : `0xd9891552`
     *
     * @param tokenIds       ids of the token.
     *
     * @return metadata id of the tokens.
     */
    function getTokenMetadatIdBatch(
        uint256[] memory tokenIds
    ) external view returns (string[] memory);

    /**
     * @notice returns the working status of the tokens.
     *
     * Signature for getTokenStatus(uint256,uint256) : `0x92cdbdf1`
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial Number of the token.
     *
     * @return working status of the tokens.
     */
    function getTokenStatus(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (TokenStatus memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

/**
 * @title NotAvailableForOperationLib:
 *
 * @author Farasat Ali
 *
 * @notice Provides common error function for all contracts.
 */
library NotAvailableForOperationLib {
    /// @notice operation is not allowed due to one of the following reasons - Signature : `0xdd73df38`:
    /// `1` -> token Owner is allowed
    /// `2` -> token owner is not allowed
    /// `3` -> must end lending first
    /// `4` -> token is expired
    /// `5` -> not enough life
    /// `6` -> value is out of range
    /// `7` -> transfer or bidding before sale is not allowed
    /// `8` -> token already active
    /// `9` -> token already inactive
    /// `10` -> life must be multiple of the day
    /// `11` -> auction inactive
    /// `12` -> auction ended
    /// `13` -> borrower active
    /// `14` -> only winner can claim
    /// `15` -> already listed for fixed price or auction
    /// `16` -> already in lending
    /// `17` -> not listed for fixed price or auction
    /// `18` -> not minted
    /// `19` -> already minted
    /// `20` -> not the Owner
    /// `21` -> invalid Address
    /// `22` -> no Bid
    /// `23` -> bid Lower than previous
    /// `24` -> highest bidder cannot revoke
    /// `25` -> Paused
    /// `26` -> Not Address
    error NotAvailableForOperation(uint256 status);
}