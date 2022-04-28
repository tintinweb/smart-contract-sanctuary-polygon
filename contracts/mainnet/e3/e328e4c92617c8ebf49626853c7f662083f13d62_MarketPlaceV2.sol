/**
 *Submitted for verification at polygonscan.com on 2022-04-28
*/

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: contracts/Token/Marketplace.sol


pragma solidity ^0.8.0;



contract MarketPlaceV2 {
    //////////////////////////////////////////////////////////////////////////////////////////////////
    // State
    //////////////////////////////////////////////////////////////////////////////////////////////////
    IERC721 s_NFTs;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    enum Status {
        open,
        cancelled,
        executed
    }

    struct Sale {
        address owner;
        Status status;
        uint256 price;
        uint time;
        address token;
    }
    address public owner;
    address public devsAddress=0x6ce19c0edcD9E67d21110e2AEb2FAcAaEf17B103;
    uint public fee=3;
    uint[] private _allIdsNFT;
    uint[] private _openSales;
    mapping(uint => int) private id_openSales;
    mapping(uint256 => Sale[]) public s_sales;
    mapping(uint256 => uint256) s_securty;
    bool public paused=false;
    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Modifiers
    //////////////////////////////////////////////////////////////////////////////////////////////////
    modifier onlyOwner() {
        require(msg.sender == owner,"Not owner");
        _;
    }
    modifier securityFrontRunning(uint256 p_nftID) {
        require(
            s_securty[p_nftID] == 0 ||
            s_securty[p_nftID] < block.number,
            "Error security"
        );
        s_securty[p_nftID] = block.number;

        _;
    }
    modifier whenNotPaused() {
        require(paused == false);
        _;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Constructor
    //////////////////////////////////////////////////////////////////////////////////////////////////

    constructor (address p_nftsContract) {
        s_NFTs = IERC721(p_nftsContract);
        owner=msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Public functions
    //////////////////////////////////////////////////////////////////////////////////////////////////
    function setNewOwner(address newOwner) public onlyOwner {
        owner=newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }
    function setDevAddress(address ad) public onlyOwner {
        devsAddress=ad;
    }
    // Pausa algunas funciones del contrato
    function pause() public onlyOwner {
        paused=true;
    }
    // Restablece algunas funciones pausadas del contrato
    function unpause() public onlyOwner {
        paused=false;
    }
    function setFee(uint value) public onlyOwner {
        fee=value;
    }
    function getOpenSales() public view returns(uint[] memory){
        return _openSales;
    }
    function getVerifiedOpenSales() public view returns(uint[] memory){
        uint[] memory result = new uint[](_openSales.length);
        uint count=0;
        for(uint i=0;i<_openSales.length;i++){
            if(s_NFTs.getApproved(_openSales[i])==address(this)){
                result[count]=_openSales[i];
                count+=1;
            }
        }
        uint[] memory fit_result = new uint[](count);
        for(uint i=0;i<count;i++){
            fit_result[i]=result[i];
        }
        return fit_result;
    }
    function getAllNftIDs() public view returns(uint[] memory){
        return _allIdsNFT;
    }
    function insertOpenSale(uint p_nftID) private {
        bool exist=false;
        for(uint i=0;i<_openSales.length;i++){
            if(_openSales[i]==p_nftID){
                exist=true;
                break;
            }
        }
        if(!exist){
            _openSales.push(p_nftID);
            id_openSales[p_nftID]=int(_openSales.length-1);
        }
    }
    function deleteOpenSale(uint p_nftID) private {
        uint last=_openSales.length-1;
        int i=id_openSales[p_nftID];
        require(i>=int(0) && i<=int(last),"Cannot find NFT");
        _openSales[uint(i)]= _openSales[last];
        _openSales.pop();
        id_openSales[p_nftID]=-1;
    }
    function getHistorical(uint256 p_nftID) public view returns (Sale[] memory){
        return s_sales[p_nftID];
    }
    function getSale(uint256 p_nftID) public view returns (Sale memory){
        return s_sales[p_nftID][s_sales[p_nftID].length-1];
    }
    function openSale(uint256 p_nftID, uint256 p_price, address token) public whenNotPaused securityFrontRunning(p_nftID) {
        require(s_NFTs.getApproved(p_nftID)==address(this),"Not Approved");
        if (s_sales[p_nftID].length>0) {
            _openSale(p_nftID,p_price,token);
        } else {
            require(msg.sender == getSale(p_nftID).owner,"Without permission");
            require(getSale(p_nftID).status != Status.open,"It's currently open");
            _openSale(p_nftID,p_price,token);
        }
    }
    function _openSale(uint256 p_nftID, uint256 p_price, address token) private {
            //s_NFTs.transferFrom(msg.sender, address(this), p_nftID);
            s_sales[p_nftID].push(Sale(msg.sender,Status.open,p_price,block.timestamp,token));
            insertOpenSale(p_nftID);
            _allIdsNFT.push(p_nftID);
    }
    function cancelSale(uint256 p_nftID) public whenNotPaused securityFrontRunning(p_nftID) {
        require(msg.sender == getSale(p_nftID).owner,"Without permission");
        require(getSale(p_nftID).status == Status.open, "Is not Open");
        Sale memory last=getSale(p_nftID);
        s_sales[p_nftID].push(Sale(last.owner,Status.cancelled,last.price,block.timestamp,last.token));
        //s_NFTs.transferFrom(address(this), last.owner, p_nftID);
        deleteOpenSale(p_nftID);
    }
    function buy(uint256 p_nftID) public whenNotPaused securityFrontRunning(p_nftID) {
        require(s_NFTs.getApproved(p_nftID)==address(this),"Not in Sale");
        Sale memory last=getSale(p_nftID);
        require(last.status == Status.open, "Is not Open");
        require(IERC20(last.token).transferFrom(msg.sender, last.owner, last.price), "Error transfer token - price");
        require(IERC20(last.token).transferFrom(msg.sender, devsAddress, (last.price * fee) / 100 ), "Error transfer fee"); // fee 3%
        s_NFTs.transferFrom(last.owner, msg.sender, p_nftID);
        s_sales[p_nftID].push(Sale(msg.sender,Status.executed,last.price,block.timestamp,last.token));
        deleteOpenSale(p_nftID);
    }
}