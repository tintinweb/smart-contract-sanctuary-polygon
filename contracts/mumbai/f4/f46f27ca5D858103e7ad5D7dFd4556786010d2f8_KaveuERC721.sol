// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 *
 * @author Rao Nagos
 * KaveuERC721 - Kaveu - KVU
 * Repository URL : https://github.com/Kaveu/kaveu-core
 * Website URL : https://kaveu.io
 *
 * Kaveu is a project based on NFTs which are used as a key to be allowed to use an arbitration bot (IA) on CEXs/DEXs.
 * Each NFT has a basic `claws` to arbitrate 2 tokens on the C/DEXs. The same `claws` can be borrowed from third parties if the owners allows it.
 */
contract KaveuERC721 is ERC721, ERC721Holder, Ownable, ReentrancyGuard {
    // Identify who the caller is
    enum AssignState {
        DEFAULT,
        BY_OWNER,
        BY_BORROWER
    }

    /**
     * @param deadline The loan period
     * @param totalAmount The price of the loan
     * @param totalBorrow The total number of claw that were borrowed by {borrower}
     * @param caller The one who called the function and also who will receive the refunds
     * @param borrower The dedicated account
     * @param assignState See above
     */
    struct BorrowData {
        uint256 deadline;
        uint256 totalAmount;
        uint256 totalBorrow;
        address caller;
        address borrower;
        AssignState assignState;
    }

    /**
     * @param pricePerDay The price of the loan per day
     * @param totalBorrow The total number of claws that were borrowed by all borrowers
     * @param totalAssign The total number of claws that were assigned by the owner
     * @param totalClaw The total number of claws
     * @param priceClaw The price of the claw
     */
    struct Claw {
        uint256 pricePerDay;
        uint256 totalBorrow;
        uint256 totalAssign;
        uint256 totalClaw;
        uint256 priceClaw;
    }

    // Simple events
    event ClawLoaning(uint256 indexed tokenId, uint256 indexed pricePerDay);
    event ClawBorrowed(uint256 indexed tokenId, address indexed borrower, uint256 indexed deadline);

    // The maximum supply that can be mined
    uint256 public constant MAX_SUPPLY = 15; // $ echo "(7 * 2) + 1" | bc
    // The safe address to withdraw or to sell tokens
    address public safeAddress;
    // The base uri that stores the json file
    string private _baseUri;

    // Map {Claw} by the id of token
    mapping(uint256 => Claw) private _claws;
    // Map {BorrowData} by borrower address
    mapping(uint256 => mapping(address => BorrowData)) private _borrowers;
    address[] private _borrowerArray;

    /**
     * @dev Throws if the token does not exist.
     * See {ERC721-_exists}.
     *
     * @param tokenId The id of the token
     */
    modifier existToken(uint256 tokenId) {
        require(_exists(tokenId), "KaveuERC721: the token does not exist");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     * See {IERC721-ownerOf}.
     *
     * @param tokenId The id of the token
     */
    modifier onlyOwnerOf(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "KaveuERC721: you are not the owner");
        _;
    }

    /**
     * @dev Set the {Claw.priceClaw} to 12,7 ether (starting price) and {Claw.totalClaw} to 2.
     * Set the {_baseUri} and the {safeAddress}.
     *
     * @param safeAddress_ The safe address of deployer
     * @param uri_ The CID of ipfs url
     */
    constructor(address safeAddress_, string memory uri_) ERC721("Kaveu", "KVU") {
        safeAddress = safeAddress_;
        _baseUri = uri_;

        for (uint256 id = 1; id <= MAX_SUPPLY; id++) {
            _claws[id].totalClaw = id > 1 ? 2 : 7; // The one should never be sold
            _claws[id].priceClaw = 12.7 gwei; // 12.7 ether (matic): 18$ at april 17th 2022
            _mint(safeAddress, id);
        }
    }

    /**
     * @return MAX_SUPPLY The maximum supply
     */
    function totalSupply() external pure returns (uint256) {
        return MAX_SUPPLY;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     *
     * @param _tokenId The id of the token
     * @return uri The uri token of the {_tokenId}
     */
    function tokenURI(uint256 _tokenId) public view virtual override existToken(_tokenId) returns (string memory) {
        return string(abi.encodePacked(_baseUri, Strings.toString(_tokenId), ".json"));
    }

    /**
     * @dev Call once a time all the tokens uri.
     *
     * @return uris All tokens uri
     */
    function getTokenURIs() external view virtual returns (string[] memory) {
        string[] memory uris = new string[](MAX_SUPPLY);
        for (uint256 tokenId = 1; tokenId <= MAX_SUPPLY; tokenId++) uris[tokenId - 1] = tokenURI(tokenId);
        return uris;
    }

    /**
     * @return balance The balance of the contract
     */
    function balance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Allows the deployer to send the contract balance to the {safeAddress}.
     */
    function withdraw() external virtual onlyOwner nonReentrant {
        (bool success, ) = payable(safeAddress).call{value: address(this).balance}("");
        require(success, "Address: unable to send value");
    }

    /**
     * @dev Allow the deployer to set the {safeAddress} by the {_safeAddress}.
     *
     * @param _safeAddress The new safe address
     */
    function setSafeAddress(address _safeAddress) external virtual onlyOwner {
        safeAddress = _safeAddress;
    }

    /**
     * @dev Allows the deployer to set the {_baseUri} by the {_newUri}.
     *
     * @param _newUri The new {_baseUri}
     */
    function setUri(string memory _newUri) external virtual onlyOwner {
        _baseUri = _newUri;
    }

    /**
     * @dev Allows the owner to increase claws of the {_tokenId} by {_incBy} by sending a minimum amount.
     * The {Claw.priceClaw} is updated according to the formula: {Claw.totalClaw} * 5,7614 ether.
     * !! Decreases claws does not exist.
     *
     * Throws if the {_tokenId} is less than 1 and if the {value} is less than the required amount.
     *
     * @param _tokenId The id of the token
     * @param _incBy The number of claws to add
     */
    function increaseClaws(uint256 _tokenId, uint256 _incBy) external payable virtual onlyOwnerOf(_tokenId) nonReentrant {
        require(msg.value >= _incBy * _claws[_tokenId].priceClaw && _tokenId > 1, "KaveuERC721: unable to increase the token");
        _claws[_tokenId].totalClaw += _incBy;
        _claws[_tokenId].priceClaw = _claws[_tokenId].totalClaw * 5.7614 gwei; // 5,7614 = (12,7 / 7,21) + (7 - 2 - 1)
    }

    /**
     * @dev Allows the deployer to increase by 4, all owner claws except the id one.
     * This function affects the {increaseClaws} function.
     */
    function airdrop() external virtual onlyOwner {
        for (uint256 id = 2; id <= MAX_SUPPLY; id++) _claws[id].totalClaw += (7 - 2 - 1);
    }

    /////////////////////////////////////////////////////////////////////
    /////////////////////////// LOAN ////////////////////////////////////
    /////////////////////////////////////////////////////////////////////

    /**
     * @param _tokenId The id of the token
     * @return claw The {Claw} of the {_tokenId}
     */
    function clawsOf(uint256 _tokenId) external view existToken(_tokenId) returns (Claw memory) {
        return _claws[_tokenId];
    }

    /**
     * @dev The IA uses this function to check if a borrower is allowed to use him.
     *
     * @param _tokenId The id of the token
     * @return borrowDatas An array of {BorrowData} of the {_tokenId}
     */
    function borrowOf(uint256 _tokenId) external view existToken(_tokenId) returns (BorrowData[] memory) {
        uint256 ln = _borrowerArray.length;
        if (ln == 0) return new BorrowData[](ln);
        uint256 cbsIndex;
        uint256 i;
        BorrowData[] memory cbs = new BorrowData[](ln);
        for (i = 0; i < ln; i++) {
            BorrowData memory cb = _borrowers[_tokenId][_borrowerArray[i]];
            if (cb.assignState != AssignState.DEFAULT) {
                cbs[cbsIndex] = cb;
                cbsIndex++;
            }
        }
        // use assembly to decrease the size for null data (by null, it means AssignState.DEFAULT)
        // the first 'if' above makes the following code safe
        for (i = cbsIndex; i < ln; i++)
            assembly {
                mstore(cbs, sub(mload(cbs), 1))
            }

        return cbs;
    }

    /**
     * ~ON-CHAIN~
     * @dev The IA uses this function to check if a borrower is allowed to use him.
     * Check to see if the borrower exists and if the deadline of the loan has been reached.
     *
     * @param _borrower The borrower to find
     * @return isBorrower
     */
    function isBorrower(address _borrower) external view returns (bool) {
        bool find = false;
        for (uint256 i = 0; i < _borrowerArray.length; i++)
            if (_borrowerArray[i] == _borrower) {
                find = true;
                break;
            }
        if (!find) return find;
        for (uint256 id = 1; id <= MAX_SUPPLY; id++) if (_borrowers[id][_borrower].assignState != AssignState.DEFAULT && _borrowers[id][_borrower].deadline > block.timestamp) return true;
        return false;
    }

    /**
     * ~ON-CHAIN~
     * @param _borrower The borrower who borrows
     * @return totalBorrowsOf The number of claws the {_borrower} borrows.
     */
    function totalBorrowsOf(address _borrower) external view returns (uint256) {
        uint256 total = 0;
        for (uint256 id = 1; id <= MAX_SUPPLY; id++) total += _borrowers[id][_borrower].totalBorrow;
        return total;
    }

    /**
     * @dev Removes {index} borrower from the array by calling the pop() function.
     * In fine : this will decrease the array length by 1.
     *
     * @param index The cute index
     */
    function removeBorrower(uint256 index) private {
        _borrowerArray[index] = _borrowerArray[_borrowerArray.length - 1];
        _borrowerArray.pop();
    }

    /**
     * @dev Manually assigns a {_borrower} once to the token {_tokenId} for 721 years and without paying the loan fee.
     * The {_borrower} is a dedicated account. Considere checking the website for more info.
     * !! The {Claw.assignState} is set by the owner.
     *
     * Throws if the {Claw.totalAssign} of the {_tokenId} is greater than the {Claw.totalClaw}.
     * And throws if the {BorrowData.assignState} of the {_borrower} is not an {AssignState.DEFAULT}.
     *
     * This emits the {ClawBorrowed} event.
     *
     * @param _tokenId The id of the token
     * @param _forClaws The number of claws the owner wants to borrow
     * @param _borrower The address of the borrower
     */
    function assign(
        uint256 _tokenId,
        uint256 _forClaws,
        address _borrower
    ) external virtual onlyOwnerOf(_tokenId) {
        BorrowData memory cb = _borrowers[_tokenId][_borrower];
        Claw memory cl = _claws[_tokenId];
        cl.totalAssign += _forClaws;

        require(cl.totalAssign <= cl.totalClaw && cb.assignState == AssignState.DEFAULT, "KaveuERC721: cannot assign the borrower");

        cb.deadline = block.timestamp + (31536000 * 721); // 31536000 YEAR_IN_SECONDS
        cb.assignState = AssignState.BY_OWNER;
        cb.totalBorrow = _forClaws;
        cb.caller = msg.sender;
        cb.borrower = _borrower;

        _claws[_tokenId] = cl;
        _borrowers[_tokenId][_borrower] = cb;
        _borrowerArray.push(_borrower);

        emit ClawBorrowed(_tokenId, _borrower, cb.deadline);
    }

    /**
     * @dev Deassigns a {_borrower} who has already been manually assigned from the assign() function.
     * If {Claw.totalAssign} is 0, then it will clear the data.
     *
     * Throws if the {BorrowData.assignState} was not assigned by the owner.
     *
     * @param _tokenId The id of the token
     * @param _forClaws The number of claws the owner wants to borrow
     * @param _borrower The address of the borrower
     */
    function deassign(
        uint256 _tokenId,
        uint256 _forClaws,
        address _borrower
    ) external virtual onlyOwnerOf(_tokenId) {
        Claw storage cl = _claws[_tokenId];
        cl.totalAssign -= _forClaws; // reverting on overflow

        require(_borrowers[_tokenId][_borrower].assignState == AssignState.BY_OWNER, "KaveuERC721: cannot deassign the borrower");

        // clear()
        if (cl.totalAssign == 0)
            for (uint256 i = 0; i < _borrowerArray.length; i++)
                if (_borrowerArray[i] == _borrower) {
                    delete _borrowers[_tokenId][_borrower];
                    removeBorrower(i);
                    break;
                }
    }

    /**
     * @dev Create a loan for the {_tokenId} by setting a price {_pricePerDay}.
     * To stop the loan, set the {_pricePerDay} to 0 but this does not stop the current rentals.
     *
     * This emits {ClawLoaning} event.
     *
     * @param _tokenId The id of the token
     * @param _pricePerDay The price the caller wants to loan claws
     */
    function loan(uint256 _tokenId, uint256 _pricePerDay) external virtual onlyOwnerOf(_tokenId) {
        _claws[_tokenId].pricePerDay = _pricePerDay;

        emit ClawLoaning(_tokenId, _pricePerDay);
    }

    /**
     * @dev Create a borrow for a {_tokenId} by sending a minimum amount. Borrow until {_forDays} + {block.timestamp}.
     * If the owner of the {_tokenId} wants to sell it, he will have to pay back {BorrowData.totalAmount} the {BorrowData.caller} completely first, not for the days remaining.
     * !! The caller cannot cancel the loan until the deadline is reached.
     *
     * See {loan} to stop it.
     * See {_beforeTokenTransfer} to check the refunds.
     *
     * Throws if {Claw.pricePerDay} of the {_tokenId} or {_forDays} is 0.
     * Throws if the {Claw.totalBorrow} is greater than the {Claw.totalClaw}.
     * Throws if {BorrowData.assignState} is not an {AssignState.DEFAULT}.
     * And throws if the {value} is less than the required amount.
     *
     * This emits the {ClawBorrowed} event.
     *
     * @param _tokenId The id of the token
     * @param _forClaws The number of claws the caller wants to borrow
     * @param _forDays The number of days the caller wants to borrow
     * @param _borrower The address of the borrower
     */
    function borrow(
        uint256 _tokenId,
        uint256 _forClaws,
        uint256 _forDays,
        address _borrower
    ) external payable virtual existToken(_tokenId) nonReentrant {
        Claw memory cl = _claws[_tokenId];
        cl.totalBorrow += _forClaws;
        BorrowData memory cb = _borrowers[_tokenId][_borrower];

        require(cl.pricePerDay > 0 && _forClaws > 0 && _forDays > 0 && cl.totalBorrow <= cl.totalClaw && cb.assignState == AssignState.DEFAULT, "KaveuERC721: cannot borrow");

        cb.deadline = block.timestamp + (_forDays * 86400); // 86400 DAY_IN_SECONDS
        cb.totalAmount = _forClaws * _forDays * cl.pricePerDay;
        cb.totalBorrow = _forClaws;
        cb.caller = msg.sender; // refund the caller
        cb.borrower = _borrower;
        cb.assignState = AssignState.BY_BORROWER;

        _claws[_tokenId] = cl;
        _borrowers[_tokenId][_borrower] = cb;
        _borrowerArray.push(_borrower);

        // pays loan fee
        require(msg.value >= cb.totalAmount, "KaveuERC721: not enought token");
        (bool success, ) = payable(ownerOf(_tokenId)).call{value: msg.value}("");
        require(success, "Address: unable to send value");

        emit ClawBorrowed(_tokenId, _borrower, cb.deadline);
    }

    /**
     * @dev Clears the data if the {BorrowData.deadline} has been reached. Anyone can call this function.
     */
    function clear() external virtual {
        uint256 ln = _borrowerArray.length;
        uint256[] memory array = new uint256[](ln);
        uint256 counter = 0;
        uint256 i;
        for (uint256 id = 1; id <= MAX_SUPPLY; id++)
            for (i = 0; i < _borrowerArray.length; i++) {
                BorrowData memory cb = _borrowers[id][_borrowerArray[i]];
                if (cb.assignState != AssignState.DEFAULT && cb.deadline < block.timestamp) {
                    Claw storage cl = _claws[id];
                    if (cb.assignState == AssignState.BY_OWNER) cl.totalAssign -= cb.totalBorrow;
                    else cl.totalBorrow -= cb.totalBorrow;
                    array[counter] = i;
                    counter++;
                    delete _borrowers[id][_borrowerArray[i]];
                }
            }

        for (i = 0; i < counter; i++) removeBorrower(array[i]);
    }

    /**
     * @param _tokenId The id of the token
     * @return amountIn The required amount to refund the owner of the {_tokenId}
     */
    function getAmountInToRefund(uint256 _tokenId) public view returns (uint256) {
        uint256 amountIn = 0;
        for (uint256 i = 0; i < _borrowerArray.length; i++)
            if (_borrowers[_tokenId][_borrowerArray[i]].assignState == AssignState.BY_BORROWER) amountIn += _borrowers[_tokenId][_borrowerArray[i]].totalAmount;

        return amountIn;
    }

    /**
     * @dev Check that there are no refunds to be made prior to the transfer. If there is, a refund is required to the `BorrowData.caller` for `BorrowData.totalAmount`, not for the days remaining.
     * !! It is recommended to call the {clear} function first.
     *
     * Throws if the {value} is less than the required amount.
     *
     */
    function refundBorrowers(uint256 _tokenId) external payable virtual nonReentrant {
        require(msg.value >= getAmountInToRefund(_tokenId), "KaveuERC721: not enought token");

        for (uint256 i = 0; i < _borrowerArray.length; i++) {
            BorrowData memory cb = _borrowers[_tokenId][_borrowerArray[i]];
            if (cb.assignState == AssignState.BY_BORROWER) {
                // refunds the caller
                (bool success, ) = payable(cb.caller).call{value: cb.totalAmount}("");
                require(success, "Address: unable to send value");
                // to clear()
                cb.deadline = block.timestamp - 10;
                _borrowers[_tokenId][_borrowerArray[i]] = cb;
            }
        }
    }

    /**
     * See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        // from _mint() or to _burn()
        if (from == address(0) || to == address(0)) return;
        for (uint256 i = 0; i < _borrowerArray.length; i++)
            if (_borrowers[tokenId][_borrowerArray[i]].assignState == AssignState.BY_BORROWER && _borrowers[tokenId][_borrowerArray[i]].deadline > block.timestamp)
                revert("KaveuERC721: refund borrowers first");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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