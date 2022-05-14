// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC1155 is IERC165 {
    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;

    function mint(
        address creator,
        uint256 supplys
    ) external returns (uint256);

    function setRoyaltyFee(address receiver, uint96 _royalty) external;

    function balanceOf(address account, uint256 tokenId)
        external
        view
        returns (uint256);

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        bytes memory _data
    ) external;

    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        returns (address, uint256);
}

interface ITransferProxy {
    function erc1155safeTransferFrom(
        IERC1155 token,
        address from,
        address to,
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    ) external;

    function erc20safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) external;
}

contract Trade {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event SellerFee(uint8 sellerFee);
    event BuyerFee(uint8 buyerFee);
    event BuyAsset(
        address indexed assetOwner,
        uint256 indexed tokenId,
        uint256 quantity,
        address indexed buyer
    );
    event ExecuteBid(
        address indexed assetOwner,
        uint256 indexed tokenId,
        uint256 quantity,
        address indexed buyer
    );
    // minter fee
    event MintingFee(uint256 fee);
    // whitelist user
    event AddedWhitelistuser(address indexed userAddress);
    event RemovedWhitelistuser(address indexed userAddress);
    //operator
    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);

    event LootTransfer(
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256 values
    );
    //signer
    event signerTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event Paid(address sender, address admin, uint256 amount);

    uint8 private buyerFeePermille;
    uint8 private sellerFeePermille;
    ITransferProxy public transferProxy;
    address public owner;
    address public signer;
    mapping(uint256 => bool) private usedNonce;
    // minter whitelist
    mapping(address => bool) private minters;
    //Mapping for  pre-sale whitelist user
    mapping(address => bool) private whitelistedWallet;

    uint256 public mintingFee = 300 * 10**18;
    uint256 public maxLootlimit = 5;
    uint256 public timeLimit;
    //random generation
    uint256[100] private array;
    uint256 private length = 100;
    uint256 private randNum;

    struct Fee {
        uint256 platformFee;
        uint256 assetFee;
        uint256 royaltyFee;
        uint256 price;
        address tokenCreator;
    }

    /* An ECDSA signature. */
    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 nonce;
    }

    struct Order {
        address seller;
        address buyer;
        address erc20Address;
        address nftAddress;
        uint256 unitPrice;
        uint256 amount;
        uint256 tokenId;
        uint256 qty;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyMinters() {
        require(minters[msg.sender], "Minter: caller doesn't have minter Role");
        _;
    }

    constructor(
        uint8 _buyerFee,
        uint8 _sellerFee,
        ITransferProxy _transferProxy,
        uint8 _opensale
    ) {
        buyerFeePermille = _buyerFee;
        sellerFeePermille = _sellerFee;
        transferProxy = _transferProxy;
        owner = msg.sender;
        signer = msg.sender;
        timeLimit = block.timestamp + (_opensale * 1 hours);
    }

    function buyerServiceFee() external view virtual returns (uint8) {
        return buyerFeePermille;
    }

    function sellerServiceFee() external view virtual returns (uint8) {
        return sellerFeePermille;
    }

    // minterfee
    function setMintingfee(uint256 fee) external onlyOwner returns (bool) {
        mintingFee = fee;
        emit MintingFee(mintingFee);
        return true;
    }

    function setBuyerServiceFee(uint8 _buyerFee)
        external
        onlyOwner
        returns (bool)
    {
        buyerFeePermille = _buyerFee;
        emit BuyerFee(buyerFeePermille);
        return true;
    }

    function setSellerServiceFee(uint8 _sellerFee)
        external
        onlyOwner
        returns (bool)
    {
        sellerFeePermille = _sellerFee;
        emit SellerFee(sellerFeePermille);
        return true;
    }

    function transferOwnership(address newOwner)
        external
        onlyOwner
        returns (bool)
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        return true;
    }

    function addWhitelistedAddress(address[] memory _whitelistedAddress)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _whitelistedAddress.length; ++i) {
            whitelistedWallet[_whitelistedAddress[i]] = true;
            emit AddedWhitelistuser(_whitelistedAddress[i]);
        }
    }

    function setTimeLimit(uint256 noOfDays) external onlyOwner {
        timeLimit = block.timestamp + (noOfDays * 1 hours); //hours
    }

    function isWhitelisted(address _whitelistedAddress)
        external
        view
        returns (bool)
    {
        bool userIsWhitelisted = whitelistedWallet[_whitelistedAddress];
        return userIsWhitelisted;
    }

    function removeWhitelistedAddress(address _whitelistedAddress)
        external
        onlyOwner
    {
        require(whitelistedWallet[_whitelistedAddress], "user is not listed");
        whitelistedWallet[_whitelistedAddress] = false;
        emit RemovedWhitelistuser(_whitelistedAddress);
    }

    function lootPurchaseLimit(uint256 _maxLootlimit)
        external
        onlyOwner
        returns (bool)
    {
        maxLootlimit = _maxLootlimit;
        return true;
    }

    function addMinter(address _minter) external onlyOwner returns (bool) {
        require(!minters[_minter], "Minter already exist");
        minters[_minter] = true;
        emit MinterAdded(_minter);
        return true;
    }

    function removeMinter(address _minter) external onlyOwner returns (bool) {
        require(minters[_minter], "Minter does not exist");
        minters[_minter] = false;
        emit MinterRemoved(_minter);
        return true;
    }

    function mint1155(
        address nftAddress,
        address creator,
        uint256 supply
    ) external onlyMinters returns (bool) {
        IERC1155(nftAddress).mint(creator, supply);
        return true;
    }

    function isMinter(address _minter) external view returns (bool) {
        return minters[_minter];
    }

    function changeSigner(address newSigner) external onlyOwner returns (bool) {
        require(
            newSigner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit signerTransferred(signer, newSigner);
        signer = newSigner;
        return true;
    }

    function buyAsset(Order calldata order, Sign calldata sign)
        external
        returns (bool)
    {
        require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        Fee memory fee = getFees(order.amount, order.nftAddress, order.tokenId);
        require(
            (fee.price >= order.unitPrice * order.qty),
            "Paid invalid amount"
        );
        verifySellerSign(
            order.seller,
            order.tokenId,
            order.unitPrice,
            order.erc20Address,
            order.nftAddress,
            sign
        );
        address buyer = msg.sender;
        tradeAsset(order, fee, buyer, order.seller);
        emit BuyAsset(order.seller, order.tokenId, order.qty, msg.sender);
        return true;
    }

    function executeBid(Order calldata order, Sign calldata sign)
        external
        returns (bool)
    {
        require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        Fee memory fee = getFees(order.amount, order.nftAddress, order.tokenId);
        verifyBuyerSign(
            order.buyer,
            order.tokenId,
            order.amount,
            order.erc20Address,
            order.nftAddress,
            order.qty,
            sign
        );
        address seller = msg.sender;
        tradeAsset(order, fee, order.buyer, seller);
        emit ExecuteBid(msg.sender, order.tokenId, order.qty, order.buyer);
        return true;
    }

    function lootTransfer(
        address nftAddress,
        uint256 lootSize,
        uint256 seed,
        Sign memory sign
    ) external payable returns (bool) {
        require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        require(seed != 0, "Seed value must be greater than zero");
        require(
            block.timestamp >= timeLimit || whitelistedWallet[msg.sender],
            "User not white listed"
        );
        require(lootSize <= maxLootlimit, "Max loot limit reached");
        bool isPaid = transferFee(mintingFee * lootSize);
        require(isPaid, "failed on transfer");
        uint256 supply = 1;
        uint256[]  memory tokenIds = new uint256[] (lootSize)  ;
        verifySign(lootSize, msg.sender, seed, sign);
        for(uint256 i = 0; i < lootSize; i++){
            uint256 tokenId = getNumber(nftAddress, owner, seed);
            seed++;
            tokenIds[i] = tokenId;
            transferProxy.erc1155safeTransferFrom(
                IERC1155(nftAddress),
                owner,
                msg.sender,
                tokenId,
                supply,
                ""
            ); 
        }
        emit LootTransfer(owner, msg.sender, tokenIds, supply);
        return true;
    }

    function getSigner(bytes32 hash, Sign memory sign)
        internal
        pure
        returns (address)
    {
        return
            ecrecover(
                keccak256(
                    abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
                ),
                sign.v,
                sign.r,
                sign.s
            );
    }

    function verifySellerSign(
        address seller,
        uint256 tokenId,
        uint256 amount,
        address paymentAssetAddress,
        address assetAddress,
        Sign memory sign
    ) internal pure {
        bytes32 hash = keccak256(
            abi.encodePacked(
                assetAddress,
                tokenId,
                paymentAssetAddress,
                amount,
                sign.nonce
            )
        );
        require(
            seller == getSigner(hash, sign),
            "seller sign verification failed"
        );
    }

    function verifyBuyerSign(
        address buyer,
        uint256 tokenId,
        uint256 amount,
        address paymentAssetAddress,
        address assetAddress,
        uint256 qty,
        Sign memory sign
    ) internal pure {
        bytes32 hash = keccak256(
            abi.encodePacked(
                assetAddress,
                tokenId,
                paymentAssetAddress,
                amount,
                qty,
                sign.nonce
            )
        );
        require(
            buyer == getSigner(hash, sign),
            "buyer sign verification failed"
        );
    }

    function verifySign(
        uint256 tokenLength,
        address caller,
        uint256 seed,
        Sign memory sign
    ) internal view {
        bytes32 hash = keccak256(
            abi.encodePacked(
                address(this),
                tokenLength,
                caller,
                seed,
                sign.nonce
            )
        );
        require(
            signer == getSigner(hash, sign),
            "Sign: owner sign verification failed"
        );
    }

    function getFees(
        uint256 paymentAmt,
        address buyingAssetAddress,
        uint256 tokenId
    ) internal view returns (Fee memory) {
        address tokenCreator;
        uint256 platformFee;
        uint256 royaltyFee;
        uint256 assetFee;
        uint256 price = (paymentAmt * 1000) / (1000 + buyerFeePermille);
        uint256 buyerFee = paymentAmt - price;
        uint256 sellerFee = (price * sellerFeePermille) / 1000;
        platformFee = buyerFee + sellerFee;
        (tokenCreator, royaltyFee) = (
            (IERC1155(buyingAssetAddress).royaltyInfo(tokenId, price))
        );
        assetFee = price - royaltyFee - sellerFee;
        return Fee(platformFee, assetFee, royaltyFee, price, tokenCreator);
    }

    function tradeAsset(
        Order calldata order,
        Fee memory fee,
        address buyer,
        address seller
    ) internal virtual {
        transferProxy.erc1155safeTransferFrom(
            IERC1155(order.nftAddress),
            seller,
            buyer,
            order.tokenId,
            order.qty,
            ""
        );
        if (fee.platformFee > 0) {
            transferProxy.erc20safeTransferFrom(
                IERC20(order.erc20Address),
                buyer,
                owner,
                fee.platformFee
            );
        }
        if (fee.royaltyFee > 0) {
            transferProxy.erc20safeTransferFrom(
                IERC20(order.erc20Address),
                buyer,
                fee.tokenCreator,
                fee.royaltyFee
            );
        }
        transferProxy.erc20safeTransferFrom(
            IERC20(order.erc20Address),
            buyer,
            seller,
            fee.assetFee
        );
    }

    function getNumber(
        address nftAddress,
        address tokenOwner,
        uint256 salt
    ) internal returns (uint256) {
        uint256 result;
        result = getRandom(nftAddress, tokenOwner, salt) + 1;
        return result;
    }

    function transferFee(uint256 fee) internal returns (bool) {
        if ((payable(owner).send(fee))) {
            emit Paid(msg.sender, owner, fee);
            return true;
        }
        return false;
    }

    function getRandom(
        address nftAddress,
        address tokenOwner,
        uint256 salt
    ) private returns (uint256) {
        require(length != 0,"Minting limit exceeds");
        uint256 rand = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, salt)));
        uint256 randId = rand % length;
        if(array[randId] == 0)
            randNum = randId;
        else
            randNum = array[randId];
        if (IERC1155(nftAddress).balanceOf(tokenOwner, randNum + 1) == 0) {
            array[randId] =  array[length-1] == 0 ? length-1 : array[length-1];
            delete array[length-1];
            length--;
            randNum = getRandom(nftAddress, tokenOwner, salt);
        }
        return randNum;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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