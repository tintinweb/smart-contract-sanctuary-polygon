/**
 *Submitted for verification at polygonscan.com on 2022-08-11
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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: Breeding_main.sol


pragma solidity ^0.8.0;





interface ICharacter {
    function buyCharacter(uint256 quantity) external;
    function breedNFT(uint256 matronId, uint256 sireId,address _receiver, uint256 _breedingTime) external returns (uint256 tokenID);
}

contract Breeding is Ownable, Pausable {

    struct eggNFT {
        uint256 matronId;
        uint256 sireId;
        uint256 timeAvailable;
        uint256 claimedTime;
        bool received;
    }

    uint256 public breedingFee = 10 * 10 ** 18; // 10 LDN Token

    uint256 public breedingTime = 5 * 60 * 60 * 24; //5 days lock

    uint256 [7] public requiredPoint = [100 * 10 ** 18, 200 * 10 ** 18, 300 * 10 ** 18, 400 * 10 ** 18, 500 * 10 ** 18, 600 * 10 ** 18, 700 * 10 ** 18];

    address public tokenBase;
    address public nftBase;
    address public yacToken;
    address public addressReceiveFee;

    mapping(uint256 => uint8) public nftBreedingCount;
    mapping(uint256 => uint256[2]) public nftParent;

    event BreedingEvent(
        address owner,
        uint256 matronId,
        uint256 sireId,
        uint256 characterId,
        uint256 timeAvailable
    );

    constructor(address _tokenBaseAddress, address _gamePointAddress, address _nftBaseAddress) {
        tokenBase = _tokenBaseAddress;
        nftBase = _nftBaseAddress;
        yacToken = _gamePointAddress;
        addressReceiveFee = msg.sender;
    }

    function setTimeBreeding(uint256 _breedingTime) external onlyOwner {
        breedingTime = _breedingTime;
    }

    function setBreedingPrice(uint256 _breedingPrice) external onlyOwner {
        breedingFee = _breedingPrice;
    }

    function setRequiredPoint(uint256[] calldata _amount) external onlyOwner{
        require(_amount.length <= 7, "Forbidden");
        for(uint8 i = 0; i < _amount.length; i++){
            requiredPoint[i] = _amount[i];
        }
    }

    function setAddressReceiveFee(address addressReceiveFee_) external onlyOwner{
        addressReceiveFee = addressReceiveFee_;
    }

    function setPointAddress(address YACaddress_) external onlyOwner{
        yacToken = YACaddress_;
    }

    function setBaseToken(address tokenAddress_) external onlyOwner {
        tokenBase = tokenAddress_;
    }

    function getBreedingFeePerCount(uint256 breedingCount) external view returns(uint256){
        return requiredPoint[breedingCount];
    }

    function _breedingWith(
        uint256 _matronId,
        uint256 _sireId,
        address _sender
    ) internal {
        uint256 timeAvailable = block.timestamp + breedingTime;
        eggNFT memory cNFT;
        cNFT.timeAvailable = timeAvailable;
        cNFT.received = false;
        cNFT.matronId = _matronId;
        cNFT.sireId = _sireId;

        nftBreedingCount[_matronId]++;
        nftBreedingCount[_sireId]++;

        uint256 characterId = ICharacter(nftBase).breedNFT(_matronId, _sireId, _sender, breedingTime);
        nftParent[characterId] = [cNFT.matronId, cNFT.sireId];

        emit BreedingEvent(
            _sender,
            _matronId,
            _sireId,
            characterId,
            timeAvailable
        );
    }
    
    function _checkAvailableBreeding(uint256 _matronId, uint256 _sireId)
        internal
        view
        returns (bool)
    {
        require(_matronId != _sireId, "Can't self breeding");

        require(
            IERC721(nftBase).ownerOf(_matronId) == msg.sender,
            'Forbidden'
        );
        require(
            IERC721(nftBase).ownerOf(_matronId) ==
                IERC721(nftBase).ownerOf(_sireId),
            '2 NFT have difference owner'
        );

        require(
            nftBreedingCount[_matronId] < 7,
            'Matron NFT breeding exceed limited'
        );
        require(
            nftBreedingCount[_sireId] < 7,
            'Sire NFT breeding exceed limited'
        );

        //Breeding with parent are not allowed and sibling are not allowed too
        if (
            (nftParent[_matronId][0] == 0 && nftParent[_matronId][1] == 0) &&
            (nftParent[_sireId][0] == 0 && nftParent[_sireId][1] == 0)
        ) {
            // Both Matron and Sire are first genes
            return true;
        } else if (
            (nftParent[_matronId][0] == 0 && nftParent[_matronId][1] == 0) &&
            (nftParent[_sireId][0] != nftParent[_sireId][1])
        ) {
            //Matron are gene 0, Sire are gene 1
            require(
                nftParent[_sireId][0] != _matronId &&
                    nftParent[_sireId][1] != _matronId,
                'NFT Sire are not allowed'
            );
        } else if (
            (nftParent[_sireId][0] == 0 && nftParent[_sireId][1] == 0) &&
            (nftParent[_matronId][0] != nftParent[_matronId][1])
        ) {
            //Matron are gene 1, Sire are gene 0
            require(
                nftParent[_matronId][0] != _sireId &&
                    nftParent[_matronId][1] != _sireId,
                'NFT Matron are not allowed'
            );
        } else {
            //Both Matron and Sire are not gene 0
            require(
                nftParent[_sireId][0] != _matronId &&
                    nftParent[_sireId][1] != _matronId,
                'NFT Sire are not allowed'
            );
            require(
                nftParent[_matronId][0] != _sireId &&
                    nftParent[_matronId][1] != _sireId,
                'NFT Matron are not allowed'
            );
            uint8 warning = 0;
            if(nftParent[_matronId][0] == nftParent[_sireId][0] || nftParent[_matronId][0] == nftParent[_sireId][1]){
                warning += 1;
            } else if(nftParent[_matronId][1] == nftParent[_sireId][0] || nftParent[_matronId][1] == nftParent[_sireId][1]){
                warning += 1;
            }
            require(warning < 2, "Breeding not allowed");
        }

        return true;
    }

    function calcFeeBreeding(uint256 _matronId, uint256 _sireId) public view returns (uint256) {
        uint256 matronCount = nftBreedingCount[_matronId];
        uint256 sireCount = nftBreedingCount[_sireId];
        return (requiredPoint[matronCount] + requiredPoint[sireCount] );
    }
    
    function breeding(uint256 _matronId, uint256 _sireId)
        external
        whenNotPaused
    {
        _checkAvailableBreeding(_matronId, _sireId);
        uint256 fee = calcFeeBreeding(_matronId, _sireId);
        require(
            IERC20(yacToken).balanceOf(msg.sender) >= fee,
            'Not enough token'
        );

        IERC20(tokenBase).transferFrom(msg.sender, addressReceiveFee, breedingFee);
        IERC20(yacToken).transferFrom(msg.sender, addressReceiveFee, fee);
        _breedingWith(_matronId, _sireId, msg.sender);
    }
}