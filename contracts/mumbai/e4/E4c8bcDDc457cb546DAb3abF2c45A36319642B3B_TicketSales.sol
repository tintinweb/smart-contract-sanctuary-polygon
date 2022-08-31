/**
 *Submitted for verification at polygonscan.com on 2022-08-30
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: ERC20tickets.sol


pragma solidity ^0.8.4;





contract TicketSales is Ownable {
    IERC1155 private _token;
    IERC20 private token20;

    uint256 private tokenId = 0;

    uint256 public ticketCost;
    uint256 public ticketAmount;
    uint256 public ticketAmountPerUser;

    uint256 public currentAmount;

    bool public pause;
    //Admins
    mapping(uint256 => Admin) idToAdmin;
    mapping(address => uint256) adrToId;
    mapping(address => bool) isAdmin;
    uint256 public adminAmount;
    address[] private admins;

    struct Admin {
        uint256 id;
        address user;
        bool isAdmin;
    }

    struct ticketInfo {
        uint256 totalTicketBuyCost;
        uint256 totalTicketBuyAmount;
        uint256 walletBoughtTicketAmount;
        uint256 walletBuyTicketAmount;
    }

    mapping(address => ticketInfo) public WalletBuyTicket;

    mapping(address => bool) public whitelist;
    mapping(address => bool) public blacklist;

    uint256 public usersWhitelisted;
    uint256 public userBlacklisted;

    address assetContractAddress;
    string assetContractName;

    constructor(
    //        string memory contractName,
        uint256 ticketCost_,
        uint256 ticketAmountPerUser_,
        uint256 ticketAmount_,
        string memory assetName_,
        address payingContract_

    ){
        token20 = IERC20(payingContract_);        
        assetContractAddress = payingContract_;
        assetContractName = assetName_;
        ticketCost = ticketCost_;
        ticketAmount = ticketAmount_;
        ticketAmountPerUser = ticketAmountPerUser_;
    }

    function addWhitelist(address whiteAddress) external {
        if (isAdmin[whiteAddress]) {
            require(
                msg.sender == owner(),
                "only owner can add admin to whitelist"
            );
        } else {
            require(
                msg.sender == owner() || idToAdmin[adrToId[msg.sender]].isAdmin,
                "only owner or admin can add to whitelist"
            );
            if (idToAdmin[adrToId[msg.sender]].isAdmin) {
                require(whiteAddress != owner(), "Not possible to add owner");
            }
        }
        require(whitelist[whiteAddress] == false, "Already in whitelist");
        require(blacklist[msg.sender] == false, "Admin blacklisted");

        usersWhitelisted++;

        whitelist[whiteAddress] = true;
    }

    function removeWhitelist(address whiteAddress) external {
        if (isAdmin[whiteAddress]) {
            require(
                msg.sender == owner(),
                "only owner can delete admin from whitelist"
            );
        } else {
            require(
                msg.sender == owner() || idToAdmin[adrToId[msg.sender]].isAdmin,
                "only owner or admin can delete from whitelist"
            );
            if (idToAdmin[adrToId[msg.sender]].isAdmin) {
                require(whiteAddress != owner(), "Not possible to add owner");
            }
        }
        require(blacklist[msg.sender] == false, "Admin blacklisted");

        require(whitelist[whiteAddress] == true, "User is not in whitelist");
        whitelist[whiteAddress] = false;

        usersWhitelisted--;
    }

    function isUserInWhitelist(address user) external view returns (bool) {
        require(
            msg.sender == owner() ||
            msg.sender == user ||
            idToAdmin[adrToId[msg.sender]].isAdmin
        );

        return (whitelist[user]);
    }

    function addBlacklist(address blackAddress) external {
        if (isAdmin[blackAddress]) {
            require(msg.sender == owner(), "Only owner can add admin to blacklist");
            idToAdmin[adrToId[blackAddress]].isAdmin = false;
            for (uint256 i; i < admins.length; i++) {
                if (admins[i] == idToAdmin[adrToId[blackAddress]].user) {
                    removeAdmin(i);
                    break;
                }
            }
            adminAmount--;
            isAdmin[blackAddress] = false;
        } else {
            require(
                msg.sender == owner() || idToAdmin[adrToId[msg.sender]].isAdmin,
                "Only owner or admin can add to blacklist"
            );
            if (idToAdmin[adrToId[msg.sender]].isAdmin) {
                require(blackAddress != owner(), "Not possible to add owner");
            }
        }

        require(blacklist[msg.sender] == false, "Admin blacklisted");
        require(blacklist[blackAddress] == false, "User already blacklisted");

        blacklist[blackAddress] = true;
    }

    function removeBlacklist(address blackAddress) external {
        if (isAdmin[blackAddress]) {
            require(
                msg.sender == owner(),
                "only Owner can delete admin from blacklist"
            );
        } else {
            require(
                msg.sender == owner() || idToAdmin[adrToId[msg.sender]].isAdmin,
                "only owner or admin can delete from blacklist"
            );
            if (idToAdmin[adrToId[msg.sender]].isAdmin) {
                require(blackAddress != owner(), "Not possible to add owner");
            }
        }
        require(blacklist[blackAddress] == true, "Admin is not blacklisted");
        require(blacklist[msg.sender] == false, "Admin is not blacklisted");
        blacklist[blackAddress] = false;
        userBlacklisted--;
    }

    function isUserInBlacklist(address user) external view returns (bool) {
        require(
            msg.sender == owner() ||
            msg.sender == user ||
            idToAdmin[adrToId[msg.sender]].isAdmin
        );

        return blacklist[user];
    }

    function changePauseStatus() external onlyOwner {
        pause = !pause;
    }

    function addAdmin(address adminAddress) external onlyOwner {
        require(blacklist[msg.sender] == false, "User blacklisted");
        require(isAdmin[adminAddress] != true, "Already admin");
        adminAmount++;
        idToAdmin[adminAmount] = Admin(adminAmount, adminAddress, true);
        adrToId[adminAddress] = adminAmount;
        admins.push(adminAddress);
        isAdmin[adminAddress] = true;
    }

    function showAdminList() external view returns (address[] memory) {
        return (admins);
    }

    function deleteAdmin(address adminAddress) external onlyOwner {
        //require(blacklist[adminAddress] == false, "User blacklisted");
        require(
            idToAdmin[adrToId[adminAddress]].isAdmin == true,
            "User is not in admin list"
        );
        idToAdmin[adrToId[adminAddress]].isAdmin = false;
        for (uint256 i; i < admins.length; i++) {
            if (admins[i] == idToAdmin[adrToId[adminAddress]].user) {
                removeAdmin(i);
                break;
            }
        }
        adminAmount--;
        isAdmin[adminAddress] = false;
    }

    function removeAdmin(uint256 index) internal returns (address[] memory) {

        for (uint256 i = index; i < admins.length - 1; i++) {
            admins[i] = admins[i + 1];
        }
        delete admins[admins.length - 1];
        admins.pop();
        return admins;
    }

    
    function ticketBuy(address to_, uint256 amount_) external payable{
        require(!pause, "Contract is on pause");
        require(WalletBuyTicket[to_].walletBoughtTicketAmount + amount_ <= ticketAmountPerUser, "buying amount exceed");
        require(token20.balanceOf(msg.sender) >= amount_ * ticketCost, "You have not enough token balance for purchase!");
        // require(whitelist[msg.sender], "Please join into whitelist first!");
        require(!blacklist[msg.sender], "You are in blacklist!");

        
         

        token20.transferFrom(
            msg.sender,
            address(this),
            amount_ * ticketCost
        );

       

        WalletBuyTicket[to_].walletBoughtTicketAmount += amount_;
        //WalletBuyTicket[to_].walletBuyTicketAmount -= amount_;
        WalletBuyTicket[to_].totalTicketBuyAmount += amount_;
        WalletBuyTicket[to_].totalTicketBuyCost += amount_ * ticketCost;
    }

    function ticketTransfer(address to, uint256 amount) external {
        require(WalletBuyTicket[msg.sender].walletBoughtTicketAmount > amount, "You have not enough ticket");

        WalletBuyTicket[msg.sender].walletBoughtTicketAmount -= amount;
        WalletBuyTicket[msg.sender].totalTicketBuyAmount -= amount;
        WalletBuyTicket[msg.sender].totalTicketBuyCost -= amount * ticketCost;

        WalletBuyTicket[to].walletBoughtTicketAmount += amount;
        WalletBuyTicket[to].totalTicketBuyAmount += amount;
        WalletBuyTicket[to].totalTicketBuyCost += amount * ticketCost;
    }

    function checkBNBBalance() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function checkTokenBalance() external view onlyOwner returns (uint256) {
        return token20.balanceOf(address(this));
    }

    function checkOwner() public view returns (address){
        return owner();
    }

    function updateTicketCost(uint256 newTicketCost) external onlyOwner {
        ticketCost = newTicketCost;
    }

    function updateTicketAmount(uint256 newTicketAmount) external onlyOwner {
        ticketAmount = newTicketAmount;
    }

    function updateTicketAmountPerUser(uint256 newTicketAmountPerUSer) external onlyOwner {
        ticketAmountPerUser = newTicketAmountPerUSer;
    }

    function checkTicketCost() public view returns (uint256){
        return ticketCost;
    }

    function checkTicketAmount() public view returns (uint256) {
        return ticketAmount;
    }

    function checkTicketAmountPerUser() public view returns (uint256) {
        return ticketAmountPerUser;
    }

    function checkCostAssetName() public view returns (string memory) {
        return assetContractName;
    }

    function checkAssetAddress() public view returns (address) {
        return assetContractAddress;
    }

    function checkWalletBuyTicket(address checkWalletAddress) public view returns (ticketInfo memory){
        return WalletBuyTicket[checkWalletAddress];
    }

    function getOwner() public view returns (address) {
        return owner();
    }

    function withdrawToken() public onlyOwner returns (uint256) {
        uint256 withdrawable = token20.balanceOf(address(this));
        require(withdrawable > 0, "withdraw: Nothing to withdraw");
        require(token20.transfer(
                getOwner(),
                token20.balanceOf(address(this))
            ), "Withdraw: Can't withdraw!");
        return withdrawable;
    }

    function withdraw() public payable onlyOwner {
        (bool success,) = payable(msg.sender).call{
        value : address(this).balance
        }("");
        require(success);
    }
}