/**
 *Submitted for verification at polygonscan.com on 2022-05-24
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint public votesTotalAmt = 0;
    uint public votesTotal = 0;
    mapping(address => uint) public votes;
    mapping(address => uint) public votesPrice;
    string private _name;
    string private _symbol;
    uint8 public _decimals;
 //300sec for testing mainnet//3 * 24 * 60 * 60 //3days
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function setVotePrice(uint Price) public virtual returns (bool success) {
        require(Price <= votesTotalAmt / votesTotal * 15, "Price must be at under 10x than current Price");
        require(Price >= votesTotalAmt / votesTotal / 15, "Price must be at least 1/10th current Price");
        votesTotalAmt -= votes[msg.sender] * votesPrice[msg.sender];
        votesPrice[msg.sender] = Price;
        votesTotalAmt += votes[msg.sender] * votesPrice[msg.sender];

        return true;
    }


    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;


        votes[from] = votes[from] - amount;
        votes[to] = votes[to] + amount;
        votesTotalAmt -= amount * votesPrice[from];
        if(votesPrice[to] != 0){
            votesTotalAmt += amount * votesPrice[to];
        }else{
            votesPrice[to] = votesPrice[from];
            votesTotalAmt += amount * votesPrice[to];
        }
        if(to == address(this)){
            votesTotal -= amount;
            votesTotalAmt -= amount * votesPrice[to];
        }
        
        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount, uint256 price) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);
        
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        votes[account] = votes[account] + amount;
        votesTotalAmt += amount * price;
        votesPrice[account]= price;
        votesTotal = votesTotal + amount;
        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        
        votes[account] = votes[account] - amount;
        votesTotalAmt -= amount * votesPrice[account];
        
        votesTotal = votesTotal - amount;
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: contracts/IERC165.sol


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
// File: contracts/DaughterContract.sol

pragma solidity ^0.8.0;



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */


contract Ownable2 {
    address public owner;
    address [] public moderators;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
    modifier OnlyModerators() {
    bool isModerator = false;
    for(uint x=0; x< moderators.length; x++){
    	if(moderators[x] == msg.sender){
		isModerator = true;
		}
		}
        require(msg.sender == owner || isModerator, "Ownable: caller is not the owner/mod");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */

    function Z_addMod(address newModerator, uint spot) public onlyOwner {
    if(spot >= moderators.length){
    	moderators.push(newModerator);
	}else{
	moderators[spot] = newModerator;
	}
    }
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function Z_transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
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


contract DaughterContract is ERC20, Ownable2 {
    uint [] public arrayNFTSymbols;
    IERC721 nftaddress;
    bool init = false;
    uint256 [] public AuctionEnd;
    uint [] public currentBid;
    address [] public topBidder;
    address public TokenAddress = address(0);
    uint public aucLength = 65;
    address public TokenAboveAddress;
    uint public totalAuc = 0;
    uint public aucNum = 0;
    uint public savedTotal = 0;
    uint [] public startAucBurn;
    uint [] public arraySoldNFTs;
    constructor(string memory name, string memory symbol, uint8 dec, uint supply, address ownerz, uint StartBuyout) ERC20(name, symbol, dec) {

        _mint(ownerz, supply * 10 ** dec, StartBuyout * 10**15); //buyout at 0.01 polygon for testing

    }

    function AuctionWon(address didTheyWin) public view returns (int auctionWon){
        for(uint x=0; x < aucNum; x++){
            if(topBidder[x] == didTheyWin ){
                return int(x);
            }
        }

        return -1;
    }
    
    function Admin_TokenAddress(address NFT, uint TokenID) public {
        require(!init, "only set NFT once");
        init = true;
        nftaddress = IERC721(NFT);
        nftaddress.transferFrom(msg.sender, address(this), TokenID);
        arrayNFTSymbols.push(TokenID);
        totalAuc++;

    }


    function Admin_Depsoit(uint TokenID) public {
        arrayNFTSymbols.push(TokenID);
        nftaddress.transferFrom(msg.sender, address(this), TokenID);        
        totalAuc++;

    }

    function Admin_Depsoit_Multi(uint startTokenID, uint totalIDs) public {
        for(uint x=startTokenID; x< totalIDs + startTokenID; x++){        
            arrayNFTSymbols.push(x);
            nftaddress.transferFrom(msg.sender, address(this), x);        
            totalAuc++;
        }
    }

    function Admin_Withdrawl(uint TokenID)public {
        nftaddress.transferFrom(address(this), msg.sender, TokenID);
    }


    function send_NFTs_To_winner(uint aucWin, uint TokenID)public {
        require(msg.sender == topBidder[aucWin], "Must have won auction");
        require(address(address(this)) != topBidder[aucWin], "No self claiming thing");
        require(AuctionEnd[aucWin]  + 1 < block.timestamp, "After block is overwith");
        nftaddress.approve(msg.sender, TokenID);
        nftaddress.transferFrom(address(this), msg.sender, TokenID);
        topBidder[aucWin] = address(this);
        arraySoldNFTs.push(TokenID);
    }


    function startBuyoutAuction(address bidForWhom) public payable virtual returns (bool success){

        require(totalAuc>0, "Must have an NFT to auction");
        if(aucNum > 1){
            require(AuctionEnd[aucNum - 1]  < block.timestamp, "No auctions within same period");
        }
        require(TokenAddress == address(0), "must equal 0 address for eth vault");
        require(msg.value >= votesTotalAmt / votesTotal, "Must bid more than reserve price");
        currentBid.push(msg.value);
        AuctionEnd.push(block.timestamp + aucLength); // 3 days
        topBidder.push(bidForWhom);
        startAucBurn.push(totalSupply() - IERC20(address(this)).balanceOf(address(this)));
        aucNum++;
        totalAuc--;

        return true;

    }


    function startBuyoutAuctionERC20(address bidForWhom, uint value) public virtual returns (bool success) {

        require(totalAuc>0, "Must have an NFT to auction");
        require(TokenAddress != address(0), "must not equal 0 address for erc20 token vault");
        require(ERC20(TokenAddress).transferFrom(msg.sender, address(this), value), "transfer must work");
        if(aucNum > 1){
            require(AuctionEnd[aucNum - 1] < block.timestamp, "No auctions within same period");
        }
        AuctionEnd.push(block.timestamp + aucLength); // //aucLength is time of auction
        currentBid.push(votesTotalAmt / votesTotal);
        topBidder.push(bidForWhom);
        startAucBurn.push(totalSupply() - IERC20(address(this)).balanceOf(address(this)));
        aucNum++;
        totalAuc--;
        return true;
    }


    function bidERC20(address bidForWhom, uint value) public  virtual returns (bool success) {

        require(block.timestamp <= AuctionEnd[aucNum], "Must bid before auction ends");
        require(value > currentBid[aucNum], "Must bid more than reserve price");
        require(ERC20(TokenAddress).transferFrom(address(this), topBidder[aucNum], currentBid[aucNum]), "Must xfer back topBid");
        currentBid[aucNum] = value;
        topBidder[aucNum] = bidForWhom;
        startAucBurn[aucNum] =totalSupply() - IERC20(address(this)).balanceOf(address(this));
        return true;
    }


    function bid(address bidForWhom) public payable  virtual returns (bool success) {

        require(block.timestamp <= AuctionEnd[aucNum], "Must bid before auction ends");
        require(msg.value > currentBid[aucNum], "Must bid more than reserve price");
        address payable receive21r = payable(topBidder[aucNum]);
        receive21r.transfer(currentBid[aucNum]);
        currentBid[aucNum] = msg.value;
        topBidder[aucNum] = bidForWhom;
        startAucBurn[aucNum] = totalSupply() - IERC20(address(this)).balanceOf(address(this));
        return true;

    }


    function currentAuctionBid() public view returns (uint number){
        return currentBid[aucNum];
    }


    function getAuctionTotals(uint amount, uint [] memory aucNumbers)public view returns(uint total){
        uint Bigtotal = 0;
        uint botTotal = 0;
        uint x =0;
        for(x =0; x< aucNumbers.length; x++){
            if(block.timestamp < AuctionEnd[aucNumbers[x]]){
                break;
            }
            Bigtotal += currentBid[aucNumbers[x]];
            botTotal += startAucBurn[aucNumbers[x]];
        }
        return amount * Bigtotal / (botTotal / (x));
    }


    function sharesNeeded() public view returns (uint shares){
        return  (totalSupply() - IERC20(address(this)).balanceOf(address(this))) / (totalAuc + aucNum);
    }


    function buyForERC(uint amount, uint TokenID) public {
        require(totalAuc >= 1,"Must have NFT to sell");
        require(IERC20(address(this)).transferFrom(msg.sender, address(this), sharesNeeded()), "xfer must work");
        nftaddress.approve(msg.sender, TokenID);
        nftaddress.transferFrom(address(this), msg.sender, TokenID);
        arraySoldNFTs.push(TokenID);
        totalAuc--;
    }


    function dispenseAuction(uint amount)public{
        IERC20(address(this)).transferFrom(msg.sender, address(this), amount);
        uint out = estimator(amount);
        if(TokenAddress != address(0)){
            IERC20(TokenAddress).transferFrom(address(this), msg.sender, out);
        }else{
            address payable receive21r = payable(msg.sender);
            receive21r.transfer(out);
            
        }
    }
    
    function estimator(uint amount) public view returns (uint amt){
        uint[] memory aucNu = new uint[](aucNum);
        uint x=0;
        for(x=0; x<aucNum; x++){
            if(block.timestamp <= AuctionEnd[x]){
                break;
            }
            aucNu[x] = (x);
        }
        uint out = getAuctionTotals(amount, aucNu);
        return out;
    }
}