/**
 *Submitted for verification at polygonscan.com on 2022-02-07
*/

// File: lending_pool_flat.sol


// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
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


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// File: lending_pool.sol

pragma solidity 0.8.7;
//SPDX-License-Identifier: UNLICENSED



//import api consumer interface
//maybe implement ierc20 receiver interface

interface IAPIConsumer {
    function get_floor() external view returns(uint256);
    }

contract LendingPool is IERC721Receiver {

    IERC721 public nft_address;
    IERC20 public usdc_address;

    uint256  public nft_pool;
    uint256  public usdc_pool;
    uint256  public reserve;
    uint256  nfts_in_pool;
    address admin;
    uint256  public total_borrowed;

    uint256  public floor_price;
    uint256  blocks_per_year;
    uint256  borrowInterestRate = 20 * 10**16;
    uint256  blocksPerDay = 6570; // 13.15 seconds per block
    uint256  daysPerYear = 365;
    uint256  lenderInterestRate = 10 * 10**16;
 
    uint256  collateral_factor = 3 * 10**17;
    uint256  discount_rate = 85 * 10**16;

    //borrowers
    mapping(address => uint256[]) NftOwnerToIds;
    mapping(address => uint256) NftOwnerToNumStaked;
    mapping(uint256  => address) NftIdToOwner;
    mapping(address => uint256) borrow_balance;
    mapping(address => uint256) borrow_time;

    address[] positions;

    //lenders
    mapping(address => uint256) lend_balance;
    mapping(address => uint256) lend_time;

    constructor(address nft, address ft) {
        nft_address = IERC721(nft);
        //nft allowed for collateral
        usdc_address = IERC20(ft);
        //erc20 ft (fungible token) for lending and borrowing

        admin = msg.sender;
    }


    //nft holder

    function deposit_nft(uint256 token_id) public {
        require(nft_address.ownerOf(token_id) == msg.sender);
        nft_address.safeTransferFrom(msg.sender, address(this), token_id, "");

        nfts_in_pool += 1;
        NftOwnerToIds[msg.sender].push(token_id);
        NftOwnerToNumStaked[msg.sender] += 1;
        NftIdToOwner[token_id] = msg.sender;

        positions.push(msg.sender);

        nft_pool +=1;

     
    }

    function withdraw_nft(uint256 token_id) public {
        require(borrow_balance[msg.sender] == 0); //allow for balance to be less than 1 penny
        nfts_in_pool -=1;
        for (uint i =0; i < NftOwnerToIds[msg.sender].length; i++){
            if (NftOwnerToIds[msg.sender][i] == token_id){
                delete NftOwnerToIds[msg.sender][i];
            }
        }
        NftOwnerToNumStaked[msg.sender] -= 1;
        delete NftIdToOwner[token_id];

        
        nft_address.safeTransferFrom(address(this), msg.sender, token_id, "");

        nft_pool -=1;

    }

    function borrow_usdc(uint256 _amount) public {
        require(NftOwnerToNumStaked[msg.sender] > 0);
        require(borrow_balance[msg.sender] == 0);

        uint256 amount = _amount * 10**18;

        uint256 collateral_value = floor_price * NftOwnerToNumStaked[msg.sender];
        uint256 borrow_limit = collateral_value * collateral_factor;
        //borrow_remaining = max_borrow - borrow_balance[msg.sender];
        require(amount < borrow_limit);
        require(amount < usdc_pool);
        usdc_address.transfer(msg.sender, amount);
        borrow_balance[msg.sender] += amount;
        borrow_time[msg.sender] = block.number;
        usdc_pool -= amount;
        total_borrowed += amount;

        updateLenderInterestRate();

    }

    function payback_usdc() public {
        uint256 fee = 5*10**18;
        uint256  interest_due = borrow_balance[msg.sender] * (block.number-borrow_time[msg.sender] / (blocksPerDay*daysPerYear)) * borrowInterestRate;
        uint256  total_due = fee + interest_due + borrow_balance[msg.sender];
        
        usdc_address.transferFrom(msg.sender, address(this), total_due);
        usdc_pool += interest_due + borrow_balance[msg.sender];
        reserve += fee;
        
        total_borrowed -= borrow_balance[msg.sender];
        borrow_balance[msg.sender] = 0;

        updateLenderInterestRate();
        

    }

    //USDC lender

    function lend_usdc(uint256 _amount) public {
        uint256 amount = _amount * 10**18;
        usdc_address.transferFrom(msg.sender, address(this), amount);
        usdc_pool += amount;
        lend_balance[msg.sender] += amount;
        lend_time[msg.sender] = block.number;

        updateLenderInterestRate();

    }

    function withdraw_usdc() public {
        require(lend_balance[msg.sender] >0);
        uint256  interest_earned = lend_balance[msg.sender] * (block.number-lend_time[msg.sender] / (blocksPerDay*daysPerYear)) * lenderInterestRate;
        uint256  total = lend_balance[msg.sender] + interest_earned; 

        usdc_address.transfer(msg.sender, total);
        usdc_pool -= total;
        lend_balance[msg.sender] = 0;
        delete lend_time[msg.sender];

        updateLenderInterestRate();

    }

    function liquidate(address borrower) public {
        uint256  liquidation_price = NftOwnerToNumStaked[borrower] * floor_price * discount_rate;
        require(borrow_balance[borrower] > liquidation_price);
        usdc_address.transferFrom(msg.sender, address(this), borrow_balance[borrower]);
        usdc_pool += borrow_balance[borrower];
        
        total_borrowed -= borrow_balance[borrower];
        borrow_balance[borrower] = 0;
        delete borrow_time[borrower];

        //move nfts from user who was liquidated to liquidator
        NftOwnerToNumStaked[msg.sender] = NftOwnerToNumStaked[borrower];
        NftOwnerToNumStaked[borrower] =0;

        
        for (uint i =0; i < NftOwnerToIds[borrower].length; i++){
            if (NftOwnerToIds[borrower][i] > 0){
                uint256  token_id = NftOwnerToIds[borrower][i];
                NftIdToOwner[token_id] = msg.sender;
                NftOwnerToIds[msg.sender].push(token_id);
                delete NftOwnerToIds[borrower][i];
            }
        }

        updateLenderInterestRate();
    }


    function updateLenderInterestRate() public {
        uint256  apy_forecast = total_borrowed * borrowInterestRate;
        lenderInterestRate = apy_forecast / usdc_pool;

    }

    //helper

    function update_floor() public {
        //call APIConsumer and get floor

        floor_price = IAPIConsumer(0x637D7d8EE6aE0A038EbC8c72DD4D14373A61FAE7).get_floor() * 10**13;

    }

    function updateBorrowInterestRate(uint256 new_interest) public {
        borrowInterestRate = new_interest;

    }

    //admin

    function withdraw_usdc(address ceo) public {
        require(admin == msg.sender, "user not admin");
        usdc_address.transfer(ceo, reserve);
        reserve = 0;

    }

    //getter

    function get_usdc_pool() public view returns(uint256) {
        return usdc_pool;
    }

    function get_total_borrowed() public view returns(uint256) {
        return total_borrowed;
    }

    function get_borrow_time(address borrower) public view returns(uint256) {
        return borrow_time[borrower];
    }

    function get_lend_balance(address lender) public view returns(uint256) {
        return lend_balance[lender];
    }

    function get_lend_time(address lender) public view returns(uint256) {
        return lend_time[lender];
    }

    function get_nft_pool() public view returns(uint256) {
        return nft_pool;
    }

    function  onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) override external returns (bytes4){
        return this.onERC721Received.selector;
    }

}



/*
come up with a variable way to determine interest rate for usdc lenders.
based on num of nfts staked plus total amount borrowed.
usdc lenders split the rewards earned assuming the interst paid is 15%
*/