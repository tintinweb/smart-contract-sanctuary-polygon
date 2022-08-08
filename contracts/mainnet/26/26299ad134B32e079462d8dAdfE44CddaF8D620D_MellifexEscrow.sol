/**
 *Submitted for verification at polygonscan.com on 2022-08-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint8);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function mint() external returns (uint256);
}

contract MellifexEscrow is Ownable {
    enum Statuses {
        Created,        // 0
        Deposit,        // 1
        Paid,           // 2
        Completed,      // 3
        Dispute,        // 4
        BuyerToCancel,  // 5
        SellerToCancel, // 6
        Canceled,       // 7
        Mediated        // 8
    }

    struct EscrowInfo {
        string escrowId;
        string description;
        IERC20 token;
        IERC721 nft;
        uint256 nftId; // Id of the nft to be transfered.
        uint256 amount; // amount buyer is meant to pay.
        uint256 deposit; // amount paid by the buyer
        uint256 commission; // Percentage of commission 1% = 10000, 100% = 1000000
        uint256 fee; // Escrow transaction fee.
        address buyer;
        address seller;
        address mediator;
        address affiliate;
        uint256 expiryDate; // Epoch timestamp of expiry date and time
        uint256 missingDecimal; // Some tokens like USDC doesn't have 18 decimals
        Statuses status;
    }

    uint256 private constant PRECISION = 1e6; // Precision for handling percentages, 100% = 1000000 /  1e6. 10000

    uint256 public transactionFee = 1e4; // default: 1e4 = 10000 or 1%

    address public adminWallet;

    address public nft; // address of the NFT contract

    bool public useNFT = false;

    mapping(string => EscrowInfo) private escrows;

    mapping(address => bool) public allowedTokens;
    address[] public token_array;

    /* ========== MODIFIERS ========== */

    modifier onlyAllowedToken(address token) {
        require(allowedTokens[token], "TOKEN not allowed");
        _;
    }

    modifier onlyBuyer(string memory escrowId) {
        require(
            msg.sender == escrows[escrowId].buyer,
            "MEX: !Buyer"
        );
        _;
    }

    modifier onlySeller(string memory escrowId) {
        require(
            msg.sender == escrows[escrowId].seller,
            "MEX: !Seller"
        );
        _;
    }
    modifier eitherBuyerOrSeller(string memory escrowId) {
        require(
            msg.sender == escrows[escrowId].seller ||
                msg.sender == escrows[escrowId].buyer,
            "MEX: Not seller or buyer"
        );
        _;
    }

    modifier onlyMediator(string memory escrowId) {
        require(
            msg.sender == escrows[escrowId].mediator,
            "MEX: Not Mediator"
        );
        _;
    }

    modifier orderIsOpen(string memory escrowId) {
        require(
            escrows[escrowId].status == Statuses.Paid     ||
            escrows[escrowId].status == Statuses.Created  ||
            escrows[escrowId].status == Statuses.Deposit,
            "Order not open"
        );
        _;
    }

    modifier canDisputeOrRefund(string memory escrowId) {
        require(
            escrows[escrowId].status != Statuses.Dispute &&
                escrows[escrowId].status != Statuses.Completed &&
                escrows[escrowId].status != Statuses.Mediated &&
                escrows[escrowId].status != Statuses.Canceled,
            "Cannot open dispute or refund"
        );
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor() {
        adminWallet = msg.sender;
    }

    // function getNFT() internal view returns (address) {
    //     if (useNFT) {
    //         return nft;
    //     }
    //     return address(0);
    // }

    // function mintNFT() internal returns (uint256) {
    //     if (useNFT) {
    //         return IERC721(nft).mint();
    //     }
    //     return 0;
    // }

    function _createTransaction(
        string memory escrowId,
        string memory description,
        address token,
        address buyer,
        address seller,
        address mediator,
        address affiliate,
        uint256 amount,
        uint256 deposit,
        uint256 commission,
        uint256 expiryDate
    )
        internal
        onlyAllowedToken(token)
        returns (bool)
    {
        require(escrows[escrowId].buyer == address(0) , "MEX: ID existed");
        require(buyer != seller, "MEX: Buyer is seller");

        escrows[escrowId] = EscrowInfo(
            escrowId,
            description,
            IERC20(token),
            IERC721(useNFT ? nft : address(0)),
            useNFT ? IERC721(nft).mint() : 0, // mintNFT(),
            amount,
            deposit,
            commission,
            transactionFee,
            buyer,
            seller,
            mediator,
            affiliate,
            expiryDate,
            18 - IERC20(token).decimals(),
            deposit > 0 ? Statuses.Paid : Statuses.Created
        );

        emit EscrowCreated(escrowId, buyer, seller);
        return true;
    }

    function createEscrow(
        string memory escrowId,
        string memory description,
        address token,
        address buyer,
        address seller,
        address mediator,
        address affiliate,
        uint256 amount,
        uint256 commission,
        uint256 expiryDate
    ) external {
        _createTransaction(
            escrowId,
            description,
            token,
            buyer,
            seller,
            mediator,
            affiliate,
            amount,
            0, // deposit
            commission,
            expiryDate
        );
    }

    function createEscrowAndPay(
        string memory escrowId,
        string memory description,
        address token,
        address buyer,
        address seller,
        address mediator,
        address affiliate,
        uint256 amount,
        uint256 commission,
        uint256 expiryDate
    ) external {
        // uint256 oldBalance = IERC20(token).balanceOf(address(this));

        uint256 actualAmount = amount / 10**IERC20(token).decimals(); // remove extra zeros.
        require(
            IERC20(token).transferFrom(msg.sender, address(this), actualAmount),
            "Unable to transfer token"
        );
        // require(
        //     IERC20(token).balanceOf(address(this)) - oldBalance >= actualAmount,
        //     "Insufficient amount sent"
        // );
        emit EscrowFunded(escrowId, amount);

        _createTransaction(
            escrowId,
            description,
            token,
            buyer,
            seller,
            mediator,
            affiliate,
            amount,
            amount, // deposit
            commission,
            expiryDate
        );

        escrows[escrowId].deposit = amount;
        escrows[escrowId].status = Statuses.Paid;
    }

    function fundEscrow(string memory escrowId, uint256 amount) external orderIsOpen(escrowId) {
        // uint256 oldBalance = escrows[escrowId].token.balanceOf(address(this));
        uint256 actualAmount = amount / 10**escrows[escrowId].missingDecimal; // remove extra zeros.
        require(
            escrows[escrowId].token.transferFrom(msg.sender, address(this), actualAmount),
            "Unable to transfer token"
        );
        // require(
        //     escrows[escrowId].token.balanceOf(address(this)) - oldBalance >= actualAmount,
        //     "Insufficient amount sent"
        // );

        escrows[escrowId].deposit += amount;

        if (escrows[escrowId].deposit >= escrows[escrowId].amount) {
            escrows[escrowId].status = Statuses.Paid;
        }
        else if(escrows[escrowId].status == Statuses.Created){
            escrows[escrowId].status = Statuses.Deposit;
        }

        emit EscrowFunded(escrowId, amount);
    }

    function getEscrow(string memory escrowId)
        external
        view
        returns (EscrowInfo memory)
    {
        return escrows[escrowId];
    }

    function escrowStatus(string memory escrowId)
        external
        view
        returns (Statuses)
    {
        return escrows[escrowId].status;
    }

    function releaseEscrow(string memory escrowId)
        external
        onlyBuyer(escrowId)
        orderIsOpen(escrowId)
    {
        uint256 amount = escrows[escrowId].deposit / 10**escrows[escrowId].missingDecimal;

        uint256 fee = (amount * escrows[escrowId].fee) / PRECISION;
        uint256 commission = (amount * escrows[escrowId].commission) / PRECISION;

        amount = amount - (fee + commission);

        escrows[escrowId].status = Statuses.Completed;

        escrows[escrowId].token.transfer(escrows[escrowId].seller, amount); // Seller's fund
        escrows[escrowId].token.transfer(adminWallet, fee); // Fee
        if (commission > 0 && escrows[escrowId].affiliate != address(0)) {
            escrows[escrowId].token.transfer(escrows[escrowId].affiliate, commission); // affiliate's commission
        }

        if(useNFT && escrows[escrowId].nftId != 0){
            escrows[escrowId].nft.transferFrom(address(this), escrows[escrowId].buyer, escrows[escrowId].nftId);
        }

        emit EscrowCompleted(escrowId);
    }

    function cancelEscrow(string memory escrowId)
        external
        onlyBuyer(escrowId)
        orderIsOpen(escrowId)
    {
        escrows[escrowId].status = Statuses.BuyerToCancel;
    }

    function cancelSale(string memory escrowId)
        external
        onlySeller(escrowId)
        orderIsOpen(escrowId)
    {
        escrows[escrowId].status = Statuses.SellerToCancel;
    }

    function approveCancel(string memory escrowId) external {
        if (escrows[escrowId].status == Statuses.BuyerToCancel) {
            require(
                msg.sender == escrows[escrowId].seller,
                "MEX:Only the seller can approve"
            );
        } else if (escrows[escrowId].status == Statuses.SellerToCancel) {
            require(
                msg.sender == escrows[escrowId].buyer,
                "MEX: Only the buyer can approve"
            );
        } else {
            revert("MEX: Approval not allowed");
        }

        escrows[escrowId].status = Statuses.Canceled;

        escrows[escrowId].token.transfer(escrows[escrowId].buyer, escrows[escrowId].deposit  / 10**escrows[escrowId].missingDecimal);
        // if (useNFT && escrows[escrowId].nftId != 0) {
        //     // Seller owns NFT
        //     escrows[escrowId].nft.transferFrom(address(this), escrows[escrowId].seller, escrows[escrowId].nftId);
        // }

        emit EscrowCanceled(escrowId);
    }

    function refundEscrow(string memory escrowId)
        external
        onlyBuyer(escrowId)
        canDisputeOrRefund(escrowId)
    {
        require(escrows[escrowId].expiryDate < block.timestamp, "Refund: Order not expired");

        escrows[escrowId].status = Statuses.Canceled;

        escrows[escrowId].token.transfer(escrows[escrowId].buyer, escrows[escrowId].deposit / 10**escrows[escrowId].missingDecimal);
        // if(useNFT && escrows[escrowId].nftId != 0){ // seller owns NFT
        //     escrows[escrowId].nft.transferFrom(address(this), escrows[escrowId].seller, escrows[escrowId].nftId);
        // }

        emit EscrowCanceled(escrowId);
    }

    function disputeEscrow(string memory escrowId)
        external
        eitherBuyerOrSeller(escrowId)
        canDisputeOrRefund(escrowId)
    {
        escrows[escrowId].status = Statuses.Dispute;
        emit EscrowDisputed(escrowId);
    }

    function resolveEscrow(
        string memory escrowId,
        uint256 mediationFee,
        uint256 buyerRatio,
        uint256 sellerRatio,
        bool transferNFT
    ) external onlyMediator(escrowId) {
        require(escrows[escrowId].status == Statuses.Dispute, "Order not in dispute");
        require(buyerRatio + sellerRatio == PRECISION, "Distribution not 100%");

        escrows[escrowId].status = Statuses.Mediated;
        if(escrows[escrowId].deposit > 0) {
            uint256 amount = escrows[escrowId].deposit / 10**escrows[escrowId].missingDecimal;

            uint256 fee = (amount * transactionFee) / PRECISION;
            uint256 commission = (amount * escrows[escrowId].commission) / PRECISION;
            amount = amount - (fee + commission + (mediationFee / 10**escrows[escrowId].missingDecimal));

            escrows[escrowId].token.transfer(escrows[escrowId].buyer, (amount * buyerRatio) / PRECISION); // Buyer's refund
            escrows[escrowId].token.transfer(escrows[escrowId].seller, (amount * sellerRatio) / PRECISION); // Seller's fund

            escrows[escrowId].token.transfer(adminWallet, fee); // Fee
            escrows[escrowId].token.transfer(escrows[escrowId].mediator, (mediationFee / 10**escrows[escrowId].missingDecimal)); // Mediator Fee
            if (commission > 0 && escrows[escrowId].affiliate != address(0)) {
                escrows[escrowId].token.transfer(escrows[escrowId].affiliate, commission); // affiliate's commission
            }

            if(useNFT && escrows[escrowId].nftId != 0){ // buyer owns NFT
                if(transferNFT){
                    escrows[escrowId].nft.transferFrom(address(this), escrows[escrowId].buyer, escrows[escrowId].nftId);
                }
            }
        }

        emit EscrowMediated(escrowId);
    }

    function totalEscrow(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /** ADMIN FUNCTIONS */

    function updatetransactionFee(uint256 fee) external onlyOwner {
        transactionFee = fee;
    }

    function updateAdminWallet(address admin) external onlyOwner {
        adminWallet = admin;
    }

    function addToken(address token) external onlyOwner {
        allowedTokens[token] = true;
        token_array.push(token);

        emit TokenAdded(token);
    }

    function removeToken(address token) external onlyOwner {
        delete allowedTokens[token];
        for (uint256 i = 0; i < token_array.length; i++) {
            if (token_array[i] == token) {
                token_array[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }

        emit TokenRemoved(token);
    }

    function updateNFT(address newNFT) external onlyOwner {
        nft = newNFT;
        emit NftUpdated(nft);
    }

    function toggleNFT() external onlyOwner {
        useNFT = !useNFT;
    }

    /* ========== EVENTS ========== */
    event EscrowCreated(
        string indexed escrowId,
        address indexed buyer,
        address indexed seller
    );
    event EscrowFunded(string indexed escrowId, uint256 indexed amount);
    event EscrowDisputed(string indexed escrowId);
    event EscrowCompleted(string indexed escrowId);
    event EscrowCanceled(string indexed escrowId);
    event EscrowMediated(string indexed escrowId);
    event TokenAdded(address indexed token);
    event TokenRemoved(address indexed token);
    event NftUpdated(address indexed nft);
}